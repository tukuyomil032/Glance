import AppKit

@MainActor
final class PreviewWindowController: NSWindowController, NSWindowDelegate {
    private let paneController = MarkdownPreviewPaneController()
    private let transitionCoordinator = PreviewWindowTransitionCoordinator()
    private var didCloseHandler: (() -> Void)?
    private var shouldBypassCloseAnimation = false
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
        let prefs = PreviewPreferences.load()
        PreviewWindowAppearance.apply(to: window, mode: prefs.appearanceMode)
        window?.title = url.lastPathComponent
        paneController.loadMarkdownFile(at: url)
        window?.orderFrontRegardless()
    }

    func prepareForPresentation() {
        ensureContentConfigured()
        transitionCoordinator.prepareForPresentation(window: window)
    }

    func animatePresentation() {
        transitionCoordinator.animatePresentation(window: window)
    }

    func reloadWithCurrentPreferences() {
        paneController.reloadWithCurrentPreferences()
    }

    var isClosingPreviewWindow: Bool {
        transitionCoordinator.isClosing
    }

    // MARK: - NSWindowDelegate

    func windowShouldClose(_ sender: NSWindow) -> Bool {
        guard !shouldBypassCloseAnimation else {
            return true
        }

        transitionCoordinator.beginCloseAnimation(window: window) { [weak self] in
            guard let self else { return }
            self.shouldBypassCloseAnimation = true
            defer { self.shouldBypassCloseAnimation = false }
            self.window?.performClose(nil)
        }
        return false
    }

    func windowWillClose(_ notification: Notification) {
        finishClose()
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

    private func finishClose() {
        transitionCoordinator.resetAfterClose()
        shouldBypassCloseAnimation = false
        didCloseHandler?()
        didCloseHandler = nil
    }

    // MARK: - Window factory

    private static func makeWindow() -> NSWindow {
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
