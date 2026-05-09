import Quartz
import WebKit

final class PreviewViewController: NSViewController, QLPreviewingController {

    private var webView: WKWebView {
        view as! WKWebView
    }

    override func loadView() {
        let webView = WKWebView()
        webView.setValue(false, forKey: "drawsBackground")
        view = webView
    }

    func preparePreviewOfFile(at url: URL) async throws {
        let data = try Data(contentsOf: url)

        guard let source = String(data: data, encoding: .utf8) else {
            throw CocoaError(.fileReadUnknownStringEncoding)
        }

        let preferences = PreviewPreferences.load()
        let markdownHTML = MarkdownRenderer.render(source)
        let fullHTML = HTMLTemplate.render(
            body: markdownHTML,
            fontSize: preferences.fontSize,
            maxWidth: preferences.maxWidth
        )

        let baseURL = url.deletingLastPathComponent()
        webView.loadHTMLString(fullHTML, baseURL: baseURL)
    }
}
