import AppKit
import SwiftUI
import WebKit

@MainActor
final class MarkdownPreviewPaneController: NSViewController {
    private var webView: WKWebView?
    private var currentFileURL: URL?
    private var pendingURL: URL?
    private var appearanceMode: PreviewAppearanceMode = .standard
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
        let prefs = PreviewPreferences.load()
        appearanceMode = prefs.appearanceMode
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
        let contentView = PreviewContentView(
            onWebViewCreated: { [weak self] webView in
                self?.webView = webView
                if let pendingURL = self?.pendingURL {
                    self?.pendingURL = nil
                    self?.performLoad(url: pendingURL, into: webView)
                }
            }
        )
        let host = NSHostingView(rootView: contentView)
        host.wantsLayer = true
        host.layer?.backgroundColor = NSColor.clear.cgColor
        view = host
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
                    contentBaseURL: url.deletingLastPathComponent(),
                    appearanceMode: prefs.appearanceMode
                )
                _ = await MainActor.run {
                    webView.loadHTMLString(html, baseURL: Bundle.main.resourceURL)
                }
            } catch {
                _ = await MainActor.run {
                    let errorHTML = HTMLTemplate.render(
                        body: "<p style='color:red'>Failed to load file: \(error.localizedDescription)</p>",
                        fontSize: 16,
                        maxWidth: 760,
                        appearanceMode: self.appearanceMode
                    )
                    webView.loadHTMLString(errorHTML, baseURL: nil)
                }
            }
        }
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
