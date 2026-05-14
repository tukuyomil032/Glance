import AppKit
import SwiftUI
import WebKit

@MainActor
final class MarkdownPreviewPaneController: NSViewController {
    private var webView: WKWebView?
    private var currentFileURL: URL?
    private var pendingURL: URL?
    private var preferencesObserver: NSObjectProtocol?

    init() {
        super.init(nibName: nil, bundle: nil)
        observePreferencesChanges()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func loadMarkdownFile(at url: URL) {
        currentFileURL = url

        guard let webView else {
            pendingURL = url
            return
        }

        performLoad(url: url, into: webView)
    }

    func reloadWithCurrentPreferences() {
        guard let url = currentFileURL else { return }
        loadMarkdownFile(at: url)
    }

    override func loadView() {
        let webView = Self.makeWebView()
        self.webView = webView
        let contentView = PreviewContentView(webView: webView)
        let host = NSHostingView(rootView: contentView)
        host.wantsLayer = true
        host.layer?.backgroundColor = NSColor.clear.cgColor
        view = host
        flushPendingLoadIfNeeded()
    }

    var hasPendingLoad: Bool {
        pendingURL != nil
    }

    deinit {
        if let preferencesObserver {
            NotificationCenter.default.removeObserver(preferencesObserver)
        }
    }

    private func performLoad(url: URL, into webView: WKWebView) {
        Task {
            do {
                let source = try String(contentsOf: url, encoding: .utf8)
                let prefs = PreviewPreferences.load()
                let body = MarkdownRenderer.render(source)
                let html = HTMLTemplate.render(
                    body: body,
                    fontSize: prefs.fontSize,
                    maxWidth: prefs.maxWidth,
                    contentBaseURL: url.deletingLastPathComponent()
                )
                _ = await MainActor.run {
                    webView.loadHTMLString(html, baseURL: Bundle.main.resourceURL)
                }
            } catch {
                _ = await MainActor.run {
                    let errorHTML = HTMLTemplate.render(
                        body: "<p style='color:red'>Failed to load file: \(error.localizedDescription)</p>"
                    )
                    webView.loadHTMLString(errorHTML, baseURL: nil)
                }
            }
        }
    }

    private func flushPendingLoadIfNeeded() {
        guard let webView, let pendingURL else {
            return
        }

        self.pendingURL = nil
        performLoad(url: pendingURL, into: webView)
    }

    private static func makeWebView() -> WKWebView {
        let config = WKWebViewConfiguration()
        config.suppressesIncrementalRendering = false
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.setValue(false, forKey: "drawsBackground")
        return webView
    }

    private func observePreferencesChanges() {
        preferencesObserver = NotificationCenter.default.addObserver(
            forName: .previewPreferencesDidChange,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task {
                await MainActor.run { [weak self] in
                    self?.reloadWithCurrentPreferences()
                }
            }
        }
    }
}
