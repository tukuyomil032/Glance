import AppKit

@MainActor
final class SplitPreviewWindowController: NSWindowController, NSWindowDelegate {
    private let leadingPaneController = MarkdownPreviewPaneController()
    private let trailingPaneController = MarkdownPreviewPaneController()
    private let splitViewController = NSSplitViewController()
    private let transitionCoordinator = PreviewWindowTransitionCoordinator()
    private var didCloseHandler: (() -> Void)?
    private var shouldBypassCloseAnimation = false
    private var hasConfiguredContentView = false

    private(set) var loadedFileURLs: [URL] = []

    convenience init() {
        let window = SplitPreviewWindowController.makeWindow()
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

    func loadMarkdownFiles(at urls: [URL]) {
        guard urls.count == 2 else {
            return
        }

        ensureContentConfigured()
        loadedFileURLs = urls
        let prefs = PreviewPreferences.load()
        PreviewWindowAppearance.apply(to: window, mode: prefs.appearanceMode)
        window?.title = "\(urls[0].lastPathComponent) + \(urls[1].lastPathComponent)"

        leadingPaneController.loadMarkdownFile(at: urls[0])
        trailingPaneController.loadMarkdownFile(at: urls[1])
    }

    func prepareForPresentation() {
        ensureContentConfigured()
        transitionCoordinator.prepareForPresentation(window: window)
    }

    func animatePresentation() {
        transitionCoordinator.animatePresentation(window: window)
    }

    var isClosingPreviewWindow: Bool {
        transitionCoordinator.isClosing
    }

    func windowWillClose(_ notification: Notification) {
        finishClose()
    }

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

    func ensureContentConfigured() {
        guard !hasConfiguredContentView, let window else {
            return
        }
        hasConfiguredContentView = true
        splitViewController.splitView.isVertical = true
        splitViewController.splitView.dividerStyle = .thin

        let leadingItem = NSSplitViewItem(viewController: leadingPaneController)
        leadingItem.minimumThickness = 320
        let trailingItem = NSSplitViewItem(viewController: trailingPaneController)
        trailingItem.minimumThickness = 320

        splitViewController.addSplitViewItem(leadingItem)
        splitViewController.addSplitViewItem(trailingItem)
        window.contentViewController = splitViewController
        splitViewController.loadViewIfNeeded()
        leadingPaneController.loadViewIfNeeded()
        trailingPaneController.loadViewIfNeeded()
        splitViewController.view.wantsLayer = true
    }

    #if DEBUG
    var arePreviewPaneViewsLoaded: [Bool] {
        [leadingPaneController.isViewLoaded, trailingPaneController.isViewLoaded]
    }

    var hasPendingPreviewLoads: [Bool] {
        [leadingPaneController.hasPendingLoad, trailingPaneController.hasPendingLoad]
    }
    #endif

    private func finishClose() {
        transitionCoordinator.resetAfterClose()
        shouldBypassCloseAnimation = false
        didCloseHandler?()
        didCloseHandler = nil
    }

    private static func makeWindow() -> NSWindow {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 1280, height: 900),
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
