enum HTMLTemplate {
    nonisolated static func render(body: String, fontSize: Int = 16, maxWidth: Int = 760) -> String {
        """
        <!DOCTYPE html>
        <html lang="en">
        <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1">
        <style>
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
        </style>
        </head>
        <body>
        <div class="content">
        \(body)
        </div>
        </body>
        </html>
        """
    }
}
