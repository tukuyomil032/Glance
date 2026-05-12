import Foundation

enum HTMLTemplate {
    nonisolated static func render(
        body: String,
        fontSize: Int = 16,
        maxWidth: Int = 760,
        contentBaseURL: URL? = nil,
        appearanceMode: PreviewAppearanceMode = .standard
    ) -> String {
        let baseTag = contentBaseURL.map { #"<base href="\#($0.absoluteString)">"# } ?? ""
        let highlightStyleTag = highlightAssetTag(
            named: "github-dark-dimmed.min",
            extension: "css",
            format: "<link rel=\"stylesheet\" href=\"%@\">"
        )
        let highlightScriptTag = highlightAssetTag(
            named: "highlight.min",
            extension: "js",
            format: "<script src=\"%@\"></script>"
        )
        let highlightBootstrapScript = highlightScriptTag.isEmpty ? "" : """
        <script>
        document.addEventListener('DOMContentLoaded', function () {
          document.querySelectorAll('pre code').forEach(function (block) {
            if (window.hljs) {
              window.hljs.highlightElement(block);
            }
          });
        });
        </script>
        """

        return """
        <!DOCTYPE html>
        <html lang="en">
        <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1">
        \(baseTag)
        \(highlightStyleTag)
        \(highlightScriptTag)
        <style>
        \(baseStyles(for: appearanceMode, fontSize: fontSize, maxWidth: maxWidth))
        </style>
        \(highlightBootstrapScript)
        </head>
        <body>
        <div class="content">
        \(body)
        </div>
        </body>
        </html>
        """
    }

    private nonisolated static func baseStyles(
        for appearanceMode: PreviewAppearanceMode,
        fontSize: Int,
        maxWidth: Int
    ) -> String {
        switch appearanceMode {
        case .standard:
            return standardStyles(fontSize: fontSize, maxWidth: maxWidth)
        case .liquidGlass:
            return liquidGlassStyles(fontSize: fontSize, maxWidth: maxWidth)
        }
    }

    private nonisolated static func standardStyles(fontSize: Int, maxWidth: Int) -> String {
        """
        :root {
          --bg: #ffffff;
          --text: #1f2328;
          --text-secondary: #636c76;
          --link: #0969da;
          --border: #d0d7de;
          --code-bg: #f6f8fa;
          --code-text: #1f2328;
          --blockquote-border: #d0d7de;
          --blockquote-text: #636c76;
          --table-header-bg: #f6f8fa;
          --table-row-alt-bg: #f6f8fa;
          --hr-color: #d0d7de;
          --heading-border: #d0d7de;
        }

        @media (prefers-color-scheme: dark) {
          :root {
            --bg: #0d1117;
            --text: #e6edf3;
            --text-secondary: #848d97;
            --link: #58a6ff;
            --border: #30363d;
            --code-bg: #161b22;
            --code-text: #e6edf3;
            --blockquote-border: #3d444d;
            --blockquote-text: #9198a1;
            --table-header-bg: #161b22;
            --table-row-alt-bg: #161b22;
            --hr-color: #21262d;
            --heading-border: #21262d;
          }
        }

        *, *::before, *::after {
          box-sizing: border-box;
        }

        body {
          background-color: var(--bg);
          color: var(--text);
          font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Helvetica, Arial, sans-serif,
                       "Apple Color Emoji", "Segoe UI Emoji";
          font-size: \(fontSize)px;
          line-height: 1.6;
          margin: 0;
          padding: 24px;
        }

        .content {
          max-width: \(maxWidth)px;
          margin: 0 auto;
        }

        a {
          color: var(--link);
          text-decoration: none;
        }
        a:hover {
          text-decoration: underline;
        }

        h1, h2, h3, h4, h5, h6 {
          margin-top: 1.5em;
          margin-bottom: 0.5em;
          font-weight: 600;
          line-height: 1.25;
        }
        h1 { font-size: 2em;    padding-bottom: 0.3em; border-bottom: 1px solid var(--heading-border); }
        h2 { font-size: 1.5em;  padding-bottom: 0.3em; border-bottom: 1px solid var(--heading-border); }
        h3 { font-size: 1.25em; }
        h4 { font-size: 1em;    }
        h5 { font-size: 0.875em;}
        h6 { font-size: 0.85em; color: var(--text-secondary); }

        p { margin-top: 0; margin-bottom: 1em; }

        code {
          font-family: "SF Mono", SFMono-Regular, ui-monospace, "Cascadia Mono",
                       Menlo, Consolas, "Liberation Mono", monospace;
          font-size: 0.875em;
          background-color: var(--code-bg);
          color: var(--code-text);
          padding: 0.2em 0.4em;
          border-radius: 6px;
        }

        pre {
          background-color: var(--code-bg);
          border-radius: 6px;
          padding: 16px;
          overflow-x: auto;
          margin-bottom: 1em;
        }
        pre code {
          padding: 0;
          background: none;
          font-size: 0.875em;
          overflow-x: auto;
          display: block;
        }
        .hljs {
          background: transparent;
          color: inherit;
        }

        blockquote {
          margin: 0 0 1em 0;
          padding: 0 1em;
          color: var(--blockquote-text);
          border-left: 4px solid var(--blockquote-border);
        }
        blockquote > :last-child { margin-bottom: 0; }

        table {
          border-collapse: collapse;
          width: 100%;
          margin-bottom: 1em;
          display: block;
          overflow-x: auto;
        }
        th, td {
          border: 1px solid var(--border);
          padding: 6px 13px;
          text-align: left;
        }
        th {
          background-color: var(--table-header-bg);
          font-weight: 600;
        }
        tr:nth-child(even) td {
          background-color: var(--table-row-alt-bg);
        }

        img {
          max-width: 100%;
          height: auto;
        }

        hr {
          border: none;
          border-top: 1px solid var(--hr-color);
          margin: 1.5em 0;
        }

        ul, ol {
          padding-left: 2em;
          margin-top: 0;
          margin-bottom: 1em;
        }
        li { margin-bottom: 0.25em; }
        li > p { margin-top: 0.5em; }

        /* Task list */
        ul.task-list { list-style: none; padding-left: 0; }
        ul.task-list li { display: flex; align-items: flex-start; gap: 0.5em; }
        ul.task-list input[type="checkbox"] { margin-top: 0.25em; flex-shrink: 0; }
        """
    }

    private nonisolated static func liquidGlassStyles(fontSize: Int, maxWidth: Int) -> String {
        """
        :root {
          color-scheme: light dark;
          --bg: transparent;
          --text: #1f2328;
          --text-secondary: #636c76;
          --link: #0969da;
          --border: rgba(255, 255, 255, 0.32);
          --code-bg: rgba(255, 255, 255, 0.55);
          --code-text: #1f2328;
          --blockquote-border: rgba(255, 255, 255, 0.28);
          --blockquote-text: #4b5563;
          --table-header-bg: rgba(255, 255, 255, 0.5);
          --table-row-alt-bg: rgba(255, 255, 255, 0.24);
          --hr-color: rgba(255, 255, 255, 0.2);
          --heading-border: rgba(255, 255, 255, 0.24);
        }

        @media (prefers-color-scheme: dark) {
          :root {
            --text: #f3f4f6;
            --text-secondary: rgba(243, 244, 246, 0.72);
            --link: #8ab4ff;
            --border: rgba(255, 255, 255, 0.16);
            --code-bg: rgba(17, 24, 39, 0.54);
            --code-text: #f8fafc;
            --blockquote-border: rgba(255, 255, 255, 0.16);
            --blockquote-text: rgba(243, 244, 246, 0.72);
            --table-header-bg: rgba(17, 24, 39, 0.56);
            --table-row-alt-bg: rgba(17, 24, 39, 0.32);
            --hr-color: rgba(255, 255, 255, 0.14);
            --heading-border: rgba(255, 255, 255, 0.14);
          }
        }

        *, *::before, *::after {
          box-sizing: border-box;
        }

        body {
          background: linear-gradient(180deg, rgba(255, 255, 255, 0.14), rgba(255, 255, 255, 0.06));
          color: var(--text);
          font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Helvetica, Arial, sans-serif,
                       "Apple Color Emoji", "Segoe UI Emoji";
          font-size: \(fontSize)px;
          line-height: 1.6;
          margin: 0;
          padding: 24px;
        }

        .content {
          max-width: \(maxWidth)px;
          margin: 0 auto;
          padding: 24px 26px;
          border-radius: 28px;
          border: 1px solid var(--border);
          background: rgba(255, 255, 255, 0.52);
          backdrop-filter: blur(28px) saturate(170%);
          -webkit-backdrop-filter: blur(28px) saturate(170%);
          box-shadow:
            0 24px 60px rgba(15, 23, 42, 0.14),
            inset 0 1px 0 rgba(255, 255, 255, 0.34);
        }

        @media (prefers-color-scheme: dark) {
          .content {
            background: rgba(15, 23, 42, 0.48);
            box-shadow:
              0 24px 60px rgba(0, 0, 0, 0.32),
              inset 0 1px 0 rgba(255, 255, 255, 0.08);
          }
        }

        a {
          color: var(--link);
          text-decoration: none;
        }
        a:hover {
          text-decoration: underline;
        }

        h1, h2, h3, h4, h5, h6 {
          margin-top: 1.5em;
          margin-bottom: 0.5em;
          font-weight: 600;
          line-height: 1.25;
        }
        h1 { font-size: 2em;    padding-bottom: 0.3em; border-bottom: 1px solid var(--heading-border); }
        h2 { font-size: 1.5em;  padding-bottom: 0.3em; border-bottom: 1px solid var(--heading-border); }
        h3 { font-size: 1.25em; }
        h4 { font-size: 1em;    }
        h5 { font-size: 0.875em;}
        h6 { font-size: 0.85em; color: var(--text-secondary); }

        p { margin-top: 0; margin-bottom: 1em; }

        code {
          font-family: "SF Mono", SFMono-Regular, ui-monospace, "Cascadia Mono",
                       Menlo, Consolas, "Liberation Mono", monospace;
          font-size: 0.875em;
          background-color: var(--code-bg);
          color: var(--code-text);
          padding: 0.2em 0.4em;
          border-radius: 6px;
        }

        pre {
          background-color: var(--code-bg);
          border-radius: 20px;
          padding: 16px;
          overflow-x: auto;
          margin-bottom: 1em;
          border: 1px solid rgba(255, 255, 255, 0.16);
        }
        pre code {
          padding: 0;
          background: none;
          font-size: 0.875em;
          overflow-x: auto;
          display: block;
        }
        .hljs {
          background: transparent;
          color: inherit;
        }

        blockquote {
          margin: 0 0 1em 0;
          padding: 0 1em;
          color: var(--blockquote-text);
          border-left: 4px solid var(--blockquote-border);
        }
        blockquote > :last-child { margin-bottom: 0; }

        table {
          border-collapse: collapse;
          width: 100%;
          margin-bottom: 1em;
          display: block;
          overflow-x: auto;
        }
        th, td {
          border: 1px solid var(--border);
          padding: 6px 13px;
          text-align: left;
        }
        th {
          background-color: var(--table-header-bg);
          font-weight: 600;
        }
        tr:nth-child(even) td {
          background-color: var(--table-row-alt-bg);
        }

        img {
          max-width: 100%;
          height: auto;
        }

        hr {
          border: none;
          border-top: 1px solid var(--hr-color);
          margin: 1.5em 0;
        }

        ul, ol {
          padding-left: 2em;
          margin-top: 0;
          margin-bottom: 1em;
        }
        li { margin-bottom: 0.25em; }
        li > p { margin-top: 0.5em; }

        /* Task list */
        ul.task-list { list-style: none; padding-left: 0; }
        ul.task-list li { display: flex; align-items: flex-start; gap: 0.5em; }
        ul.task-list input[type="checkbox"] { margin-top: 0.25em; flex-shrink: 0; }
        """
    }

    private nonisolated static func highlightAssetTag(
        named name: String,
        extension fileExtension: String,
        format: String
    ) -> String {
        guard
            let assetURL = Bundle.main.url(
                forResource: name,
                withExtension: fileExtension,
                subdirectory: "Highlight"
            ) ?? Bundle.main.url(
                forResource: name,
                withExtension: fileExtension
            )
        else {
            return ""
        }

        let escapedURL = assetURL.absoluteString.replacingOccurrences(of: "\"", with: "&quot;")
        return String(format: format, escapedURL)
    }
}
