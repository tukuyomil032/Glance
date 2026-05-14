import AppKit

@MainActor
final class PreviewWindowController: NSWindowController, NSWindowDelegate {
    private let paneController = MarkdownPreviewPaneController()
    private var didCloseHandler: (() -> Void)?
    private var hasConfiguredContentView = false

    // MARK: - Factory

    convenience init() {
        let window = PreviewWindowController.makeWindow()
        self.init(window: window)
        window.delegate = self
    }

    override init(window: NSWindow?) {
        super.init(window: window)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }

    func setDidCloseHandler(_ handler: @escaping () -> Void) {
        didCloseHandler = handler
    }

    // MARK: - Public API

    func loadMarkdownFile(at url: URL) {
        ensureContentConfigured()
        window?.title = url.lastPathComponent
        paneController.loadMarkdownFile(at: url)
        window?.makeKeyAndOrderFront(nil)
        window?.orderFrontRegardless()
    }

    func reloadWithCurrentPreferences() {
        paneController.reloadWithCurrentPreferences()
    }

    // MARK: - NSWindowDelegate

    func windowWillClose(_ notification: Notification) {
        didCloseHandler?()
        didCloseHandler = nil
    }

    // MARK: - Setup

    func ensureContentConfigured() {
        guard !hasConfiguredContentView, let window else {
            return
        }
        hasConfiguredContentView = true
        window.contentViewController = paneController
        paneController.loadViewIfNeeded()
        window.contentView?.wantsLayer = true
    }

    #if DEBUG
    var isPreviewPaneViewLoaded: Bool {
        paneController.isViewLoaded
    }

    var hasPendingPreviewLoad: Bool {
        paneController.hasPendingLoad
    }
    #endif

    // MARK: - Window factory

    private static func makeWindow() -> NSWindow {
        // Use NSPanel for menu-bar-agent mode so the window shows regardless of activation policy.
        // In UITest mode (where .regular policy is forced), fall back to NSWindow for XCUITest
        // accessibility compatibility.
        if AppMetadata.isMenuBarAgent() && !AppMetadata.isUITestMode() {
            return makePanel()
        }
        return makePlainWindow()
    }

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
        panel.tabbingMode = .disallowed
        panel.tabbingIdentifier = "MarkdownPreview"
        panel.collectionBehavior = [.moveToActiveSpace, .fullScreenAuxiliary]
        panel.isMovableByWindowBackground = false
        panel.center()
        return panel
    }

    private static func makePlainWindow() -> NSWindow {
        let window = NSWindow(
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
        window.tabbingMode = .disallowed
        window.tabbingIdentifier = "MarkdownPreview"
        window.collectionBehavior = [.moveToActiveSpace, .fullScreenAuxiliary]
        window.isMovableByWindowBackground = false
        window.center()
        return window
    }
}
