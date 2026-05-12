import AppKit
import WebKit
import SwiftUI

@MainActor
final class PreviewWindowController: NSWindowController, NSWindowDelegate {

    private var webView: WKWebView?
    private var currentFileURL: URL?
    private var pendingURL: URL?
    private var appearanceMode: PreviewAppearanceMode = .standard
    private var preferencesObserver: NSObjectProtocol?
    private var didCloseHandler: (() -> Void)?

    // MARK: - Factory

    convenience init() {
        let panel = PreviewWindowController.makePanel()
        self.init(window: panel)
        panel.delegate = self
        observePreferencesChanges()
    }

    func setDidCloseHandler(_ handler: @escaping () -> Void) {
        didCloseHandler = handler
    }

    // MARK: - Public API

    func loadMarkdownFile(at url: URL) {
        let prefs = PreviewPreferences.load()
        appearanceMode = prefs.appearanceMode
        applyWindowAppearance(for: appearanceMode)

        currentFileURL = url
        window?.title = url.lastPathComponent
        guard let webView else {
            pendingURL = url
            return
        }
        performLoad(url: url, into: webView)
    }

    private func performLoad(url: URL, into webView: WKWebView) {
        Task {
            do {
                let source = try String(contentsOf: url, encoding: .utf8)
                let prefs = PreviewPreferences.load()
                let body = MarkdownRenderer.render(source)
                let html = HTMLTemplate.render(body: body,
                                               fontSize: prefs.fontSize,
                                               maxWidth: prefs.maxWidth,
                                               contentBaseURL: url.deletingLastPathComponent(),
                                               appearanceMode: prefs.appearanceMode)
                await MainActor.run {
                    webView.loadHTMLString(html, baseURL: Bundle.main.resourceURL)
                    self.window?.orderFrontRegardless()
                }
            } catch {
                await MainActor.run {
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

    func reloadWithCurrentPreferences() {
        guard let url = currentFileURL else { return }
        loadMarkdownFile(at: url)
    }

    // MARK: - NSWindowDelegate

    func windowWillClose(_ notification: Notification) {
        if let preferencesObserver {
            NotificationCenter.default.removeObserver(preferencesObserver)
            self.preferencesObserver = nil
        }
        didCloseHandler?()
        didCloseHandler = nil
    }

    // MARK: - Setup

    override func windowDidLoad() {
        setupContentView()
    }

    deinit {
        if let preferencesObserver {
            NotificationCenter.default.removeObserver(preferencesObserver)
        }
    }

    private func setupContentView() {
        guard let panel = window else { return }

        let contentView = PreviewContentView(
            onWebViewCreated: { [weak self] wv in
                self?.webView = wv
                if let pending = self?.pendingURL {
                    self?.pendingURL = nil
                    self?.performLoad(url: pending, into: wv)
                }
            }
        )
        let host = NSHostingView(rootView: contentView)
        host.wantsLayer = true
        host.layer?.backgroundColor = NSColor.clear.cgColor
        panel.contentView = host
    }

    private func applyWindowAppearance(for mode: PreviewAppearanceMode) {
        guard let panel = window else { return }

        switch mode {
        case .standard:
            panel.isOpaque = true
            panel.backgroundColor = .windowBackgroundColor
            panel.titlebarAppearsTransparent = false
            panel.isMovableByWindowBackground = false
        case .liquidGlass:
            panel.isOpaque = false
            panel.backgroundColor = .clear
            panel.titlebarAppearsTransparent = true
            panel.isMovableByWindowBackground = true
        }
    }

    private func observePreferencesChanges() {
        preferencesObserver = NotificationCenter.default.addObserver(
            forName: .previewPreferencesDidChange,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.reloadWithCurrentPreferences()
        }
    }

    // MARK: - Panel factory

    private static func makePanel() -> NSPanel {
        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 760, height: 900),
            styleMask: [
                .titled,
                .closable,
                .resizable,
                .fullSizeContentView,
            ],
            backing: .buffered,
            defer: false
        )
        panel.tabbingMode = .preferred
        panel.tabbingIdentifier = "MarkdownPreview"
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.isMovableByWindowBackground = false
        panel.center()
        return panel
    }
}
