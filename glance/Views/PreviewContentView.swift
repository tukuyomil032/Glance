import SwiftUI
import WebKit

struct PreviewContentView: View {
    let onWebViewCreated: (WKWebView) -> Void

    var body: some View {
        WebViewWrapper(onCreated: onWebViewCreated)
            .ignoresSafeArea()
    }
}

struct WebViewWrapper: NSViewRepresentable {
    let onCreated: (WKWebView) -> Void

    func makeNSView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.suppressesIncrementalRendering = false
        let wv = WKWebView(frame: .zero, configuration: config)
        wv.setValue(false, forKey: "drawsBackground")
        onCreated(wv)
        return wv
    }

    func updateNSView(_ nsView: WKWebView, context: Context) {}
}
