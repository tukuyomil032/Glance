import SwiftUI
import WebKit

struct PreviewContentView: View {
    let webView: WKWebView

    var body: some View {
        WebViewWrapper(webView: webView)
            .ignoresSafeArea()
    }
}

struct WebViewWrapper: NSViewRepresentable {
    let webView: WKWebView

    func makeNSView(context: Context) -> WKWebView { webView }

    func updateNSView(_ nsView: WKWebView, context: Context) {}
}
