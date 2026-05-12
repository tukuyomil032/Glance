import Foundation
import Ink

enum MarkdownRenderer {
    nonisolated static func render(_ markdown: String) -> String {
        var parser = MarkdownParser()
        parser.addModifier(Modifier(target: .codeBlocks) { html, rawMarkdown in
            guard
                let language = fencedCodeLanguage(in: String(rawMarkdown)),
                html.contains("<code>")
            else {
                return html
            }

            return html.replacingOccurrences(
                of: "<code>",
                with: "<code class=\"language-\(language)\">"
            )
        })

        return parser.parse(markdown).html
    }

    private nonisolated static func fencedCodeLanguage(in markdown: String) -> String? {
        guard let firstLine = markdown.split(separator: "\n", omittingEmptySubsequences: false).first else {
            return nil
        }

        let trimmedLine = String(firstLine).trimmingCharacters(in: CharacterSet.whitespaces)
        guard trimmedLine.hasPrefix("```") || trimmedLine.hasPrefix("~~~") else {
            return nil
        }

        let infoString = trimmedLine
            .drop(while: { $0 == "`" || $0 == "~" })
            .trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)

        guard let rawLanguage = infoString.split(whereSeparator: { $0.isWhitespace }).first else {
            return nil
        }

        let loweredLanguage = rawLanguage.lowercased()
        let language = loweredLanguage.filter { character in
            character.isLetter || character.isNumber || character == "+" || character == "-" || character == "_" || character == "#"
        }
        return language.isEmpty ? nil : language
    }
}
