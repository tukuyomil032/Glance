import AppKit
import WebKit
import SwiftUI

@MainActor
final class PreviewWindowController: NSWindowController, NSWindowDelegate {

    static var shared: PreviewWindowController?

    private var webView: WKWebView?
    private var currentFileURL: URL?
    private var pendingURL: URL?

    // MARK: - Factory

    static func makeOrBringToFront() -> PreviewWindowController {
        if let existing = shared {
            existing.window?.orderFrontRegardless()
            return existing
        }
        let controller = PreviewWindowController()
        shared = controller
        controller.windowDidLoad()
        return controller
    }

    // MARK: - Init

    convenience init() {
        let panel = PreviewWindowController.makePanel()
        self.init(window: panel)
        panel.delegate = self
    }

    // MARK: - Public API

    func loadMarkdownFile(at url: URL) {
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
                                               contentBaseURL: url.deletingLastPathComponent())
                await MainActor.run {
                    webView.loadHTMLString(html, baseURL: Bundle.main.resourceURL)
                    self.window?.orderFrontRegardless()
                }
            } catch {
                await MainActor.run {
                    let errorHTML = HTMLTemplate.render(
                        body: "<p style='color:red'>Failed to load file: \(error.localizedDescription)</p>",
                        fontSize: 16,
                        maxWidth: 760
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
        PreviewWindowController.shared = nil
    }

    // MARK: - Setup

    override func windowDidLoad() {
        setupContentView()
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
        panel.contentView = host
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
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.isMovableByWindowBackground = false
        panel.center()
        panel.setFrameAutosaveName("MarkdownPreviewPanel")
        return panel
    }
}
