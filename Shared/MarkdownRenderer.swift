import Foundation

enum MarkdownRenderer {

    nonisolated static func render(_ markdown: String) -> String {
        let lines = markdown.components(separatedBy: "\n")
        return processLines(lines)
    }

    // MARK: - Block Processing

    nonisolated private static func processLines(_ lines: [String]) -> String {
        var output = ""
        var index = 0

        while index < lines.count {
            let line = lines[index]

            // Fenced code block
            if line.hasPrefix("```") {
                let lang = String(line.dropFirst(3)).trimmingCharacters(in: .whitespaces)
                var codeLines: [String] = []
                index += 1
                while index < lines.count && !lines[index].hasPrefix("```") {
                    codeLines.append(lines[index])
                    index += 1
                }
                let code = codeLines.map { htmlEscape($0) }.joined(separator: "\n")
                let langAttr = lang.isEmpty ? "" : " class=\"language-\(htmlEscape(lang))\""
                output += "<pre><code\(langAttr)>\(code)</code></pre>\n"
                index += 1
                continue
            }

            // Blockquote
            if line.hasPrefix("> ") || line == ">" {
                var bqLines: [String] = []
                while index < lines.count && (lines[index].hasPrefix("> ") || lines[index] == ">") {
                    let stripped = lines[index] == ">" ? "" : String(lines[index].dropFirst(2))
                    bqLines.append(stripped)
                    index += 1
                }
                let inner = render(bqLines.joined(separator: "\n"))
                output += "<blockquote>\n\(inner)</blockquote>\n"
                continue
            }

            // Headings
            if let (level, text) = parseHeading(line) {
                output += "<h\(level)>\(applyInline(text))</h\(level)>\n"
                index += 1
                continue
            }

            // Horizontal rule
            if isHorizontalRule(line) {
                output += "<hr>\n"
                index += 1
                continue
            }

            // Unordered / ordered / task list
            if isListItem(line) {
                let (listHTML, newIndex) = processList(lines: lines, startIndex: index)
                output += listHTML
                index = newIndex
                continue
            }

            // GFM Table — peek ahead for separator row
            if index + 1 < lines.count && isTableSeparator(lines[index + 1]) {
                let (tableHTML, newIndex) = processTable(lines: lines, startIndex: index)
                output += tableHTML
                index = newIndex
                continue
            }

            // Blank line — skip
            if line.trimmingCharacters(in: .whitespaces).isEmpty {
                index += 1
                continue
            }

            // Paragraph
            var paraLines: [String] = []
            while index < lines.count {
                let l = lines[index]
                if l.trimmingCharacters(in: .whitespaces).isEmpty { break }
                if l.hasPrefix("```") { break }
                if l.hasPrefix("> ") || l == ">" { break }
                if parseHeading(l) != nil { break }
                if isHorizontalRule(l) { break }
                if isListItem(l) { break }
                if index + 1 < lines.count && isTableSeparator(lines[index + 1]) { break }
                paraLines.append(l)
                index += 1
            }
            if !paraLines.isEmpty {
                let content = paraLines.map { applyInline($0) }.joined(separator: "\n")
                output += "<p>\(content)</p>\n"
            }
        }

        return output
    }

    // MARK: - Heading

    nonisolated private static func parseHeading(_ line: String) -> (Int, String)? {
        var level = 0
        var i = line.startIndex
        while i < line.endIndex && line[i] == "#" && level < 6 {
            level += 1
            i = line.index(after: i)
        }
        guard level > 0, i < line.endIndex, line[i] == " " else { return nil }
        let text = String(line[line.index(after: i)...]).trimmingCharacters(in: .whitespaces)
        return (level, text)
    }

    // MARK: - Horizontal Rule

    nonisolated private static func isHorizontalRule(_ line: String) -> Bool {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        let chars = Set(trimmed)
        guard chars.count == 1, let ch = chars.first, ch == "-" || ch == "*" || ch == "_" else { return false }
        return trimmed.count >= 3
    }

    // MARK: - List Processing

    nonisolated private static func isListItem(_ line: String) -> Bool {
        let indent = leadingSpaces(line)
        let rest = String(line.dropFirst(indent))
        return isUnorderedMarker(rest) || isOrderedMarker(rest)
    }

    nonisolated private static func isUnorderedMarker(_ s: String) -> Bool {
        guard s.count >= 2 else { return false }
        let first = s.first!
        return (first == "-" || first == "*" || first == "+") && s[s.index(after: s.startIndex)] == " "
    }

    nonisolated private static func isOrderedMarker(_ s: String) -> Bool {
        var i = s.startIndex
        while i < s.endIndex && s[i].isNumber { i = s.index(after: i) }
        guard i < s.endIndex && i > s.startIndex && s[i] == "." else { return false }
        let next = s.index(after: i)
        return next < s.endIndex && s[next] == " "
    }

    nonisolated private static func leadingSpaces(_ s: String) -> Int {
        var count = 0
        for ch in s {
            if ch == " " { count += 1 }
            else if ch == "\t" { count += 2 }
            else { break }
        }
        return count
    }

    nonisolated private static func processList(lines: [String], startIndex: Int) -> (String, Int) {
        var index = startIndex
        var output = ""

        let firstIndent = leadingSpaces(lines[index])
        let firstRest = String(lines[index].dropFirst(firstIndent))
        let isOrdered = isOrderedMarker(firstRest)
        let tag = isOrdered ? "ol" : "ul"

        output += "<\(tag)>\n"

        while index < lines.count {
            let line = lines[index]
            let indent = leadingSpaces(line)
            let rest = String(line.dropFirst(indent))

            if line.trimmingCharacters(in: .whitespaces).isEmpty { break }
            if indent < firstIndent { break }

            if indent == firstIndent && (isUnorderedMarker(rest) || isOrderedMarker(rest)) {
                let itemContent = extractListItemContent(rest)

                if let (checked, taskText) = parseTaskItem(itemContent) {
                    let checkedAttr = checked ? " checked" : ""
                    output += "<li><input type=\"checkbox\" disabled\(checkedAttr)> \(applyInline(taskText))"
                } else {
                    output += "<li>\(applyInline(itemContent))"
                }

                index += 1

                // Check for nested list
                if index < lines.count {
                    let nextIndent = leadingSpaces(lines[index])
                    let nextRest = String(lines[index].dropFirst(nextIndent))
                    if nextIndent > firstIndent && (isUnorderedMarker(nextRest) || isOrderedMarker(nextRest)) {
                        let (nested, newIdx) = processList(lines: lines, startIndex: index)
                        output += "\n" + nested
                        index = newIdx
                    }
                }

                output += "</li>\n"
                continue
            }

            // Deeper indent that isn't a list marker — continuation content, skip
            if indent > firstIndent {
                index += 1
                continue
            }

            break
        }

        output += "</\(tag)>\n"
        return (output, index)
    }

    nonisolated private static func extractListItemContent(_ rest: String) -> String {
        if isUnorderedMarker(rest) {
            return String(rest.dropFirst(2))
        }
        if isOrderedMarker(rest) {
            var i = rest.startIndex
            while i < rest.endIndex && rest[i].isNumber { i = rest.index(after: i) }
            i = rest.index(after: i) // skip '.'
            i = rest.index(after: i) // skip ' '
            return String(rest[i...])
        }
        return rest
    }

    nonisolated private static func parseTaskItem(_ text: String) -> (Bool, String)? {
        if text.hasPrefix("[ ] ") { return (false, String(text.dropFirst(4))) }
        if text.hasPrefix("[x] ") || text.hasPrefix("[X] ") { return (true, String(text.dropFirst(4))) }
        return nil
    }

    // MARK: - Table

    nonisolated private static func isTableSeparator(_ line: String) -> Bool {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        guard trimmed.contains("|") else { return false }
        let cells = splitTableRow(trimmed)
        guard !cells.isEmpty else { return false }
        return cells.allSatisfy { cell in
            let c = cell.trimmingCharacters(in: .whitespaces)
                .replacingOccurrences(of: "-", with: "")
                .replacingOccurrences(of: ":", with: "")
            return c.isEmpty
        }
    }

    nonisolated private static func splitTableRow(_ line: String) -> [String] {
        var row = line.trimmingCharacters(in: .whitespaces)
        if row.hasPrefix("|") { row = String(row.dropFirst()) }
        if row.hasSuffix("|") { row = String(row.dropLast()) }
        return row.components(separatedBy: "|")
    }

    nonisolated private static func processTable(lines: [String], startIndex: Int) -> (String, Int) {
        var index = startIndex
        var output = "<table>\n"

        let headerCells = splitTableRow(lines[index])
        output += "<thead>\n<tr>\n"
        for cell in headerCells {
            output += "<th>\(applyInline(cell.trimmingCharacters(in: .whitespaces)))</th>\n"
        }
        output += "</tr>\n</thead>\n"
        index += 2 // skip header and separator

        output += "<tbody>\n"
        while index < lines.count {
            let line = lines[index]
            if line.trimmingCharacters(in: .whitespaces).isEmpty { break }
            if !line.contains("|") { break }
            let cells = splitTableRow(line)
            output += "<tr>\n"
            for cell in cells {
                output += "<td>\(applyInline(cell.trimmingCharacters(in: .whitespaces)))</td>\n"
            }
            output += "</tr>\n"
            index += 1
        }
        output += "</tbody>\n</table>\n"

        return (output, index)
    }

    // MARK: - Inline Formatting

    nonisolated static func applyInline(_ text: String) -> String {
        // Extract inline code spans first to protect content from further formatting
        var parts: [(String, Bool)] = [] // (content, isCode)
        var remaining = text
        while let range = remaining.range(of: "`") {
            let before = String(remaining[remaining.startIndex..<range.lowerBound])
            parts.append((before, false))
            let afterTick = remaining[range.upperBound...]
            if let endRange = afterTick.range(of: "`") {
                let code = String(afterTick[afterTick.startIndex..<endRange.lowerBound])
                parts.append((code, true))
                remaining = String(afterTick[endRange.upperBound...])
            } else {
                // No closing backtick — treat as literal
                parts.append(("`", false))
                remaining = String(afterTick)
            }
        }
        parts.append((remaining, false))

        var result = ""
        for (content, isCode) in parts {
            if isCode {
                result += "<code>\(htmlEscape(content))</code>"
            } else {
                result += applySpanFormatting(htmlEscape(content))
            }
        }
        return result
    }

    nonisolated private static func applySpanFormatting(_ text: String) -> String {
        var s = text

        // Trailing two spaces → <br>
        s = s.replacingOccurrences(of: "  \n", with: "<br>\n")
        if s.hasSuffix("  ") {
            s = String(s.dropLast(2)) + "<br>"
        }

        // Images before links (both use [...](...)  syntax but images start with !)
        s = applyRegex(s, pattern: "!\\[([^\\]]*)\\]\\(([^)]+)\\)") { match in
            "<img src=\"\(match[2])\" alt=\"\(match[1])\">"
        }

        // Links
        s = applyRegex(s, pattern: "\\[([^\\]]+)\\]\\(([^)]+)\\)") { match in
            "<a href=\"\(match[2])\">\(match[1])</a>"
        }

        // Bold+Italic must be matched before bold-only and italic-only
        s = applyRegex(s, pattern: "\\*\\*\\*(.+?)\\*\\*\\*") { "<strong><em>\($0[1])</em></strong>" }
        s = applyRegex(s, pattern: "___(.+?)___") { "<strong><em>\($0[1])</em></strong>" }

        // Bold
        s = applyRegex(s, pattern: "\\*\\*(.+?)\\*\\*") { "<strong>\($0[1])</strong>" }
        s = applyRegex(s, pattern: "__(.+?)__") { "<strong>\($0[1])</strong>" }

        // Italic
        s = applyRegex(s, pattern: "\\*(.+?)\\*") { "<em>\($0[1])</em>" }
        // Underscore italic: avoid matching mid-word (e.g. snake_case)
        s = applyRegex(s, pattern: "(?<![\\w])_(.+?)_(?![\\w])") { "<em>\($0[1])</em>" }

        // Strikethrough
        s = applyRegex(s, pattern: "~~(.+?)~~") { "<del>\($0[1])</del>" }

        return s
    }

    nonisolated private static func applyRegex(
        _ text: String,
        pattern: String,
        replacement: ([String]) -> String
    ) -> String {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else { return text }
        var result = ""
        var lastEnd = text.startIndex
        let matches = regex.matches(in: text, options: [], range: NSRange(text.startIndex..., in: text))

        for match in matches {
            let matchRange = Range(match.range, in: text)!
            result += text[lastEnd..<matchRange.lowerBound]

            var groups: [String] = [String(text[matchRange])]
            for i in 1..<match.numberOfRanges {
                if let r = Range(match.range(at: i), in: text) {
                    groups.append(String(text[r]))
                } else {
                    groups.append("")
                }
            }
            result += replacement(groups)
            lastEnd = matchRange.upperBound
        }
        result += text[lastEnd...]
        return result
    }

    // MARK: - HTML Escape

    nonisolated static func htmlEscape(_ text: String) -> String {
        text
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
    }
}
