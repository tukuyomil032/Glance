import AppKit

@MainActor
final class SplitPreviewWindowController: NSWindowController, NSWindowDelegate {
    private let leadingPaneController = MarkdownPreviewPaneController()
    private let trailingPaneController = MarkdownPreviewPaneController()
    private let splitViewController = NSSplitViewController()
    private let transitionCoordinator = PreviewWindowTransitionCoordinator()
    private var didCloseHandler: (() -> Void)?
    private var shouldBypassCloseAnimation = false

    private(set) var loadedFileURLs: [URL] = []

    convenience init() {
        let panel = SplitPreviewWindowController.makePanel()
        self.init(window: panel)
        panel.delegate = self
    }

    func setDidCloseHandler(_ handler: @escaping () -> Void) {
        didCloseHandler = handler
    }

    func loadMarkdownFiles(at urls: [URL]) {
        guard urls.count == 2 else {
            return
        }

        loadedFileURLs = urls
        let prefs = PreviewPreferences.load()
        PreviewWindowAppearance.apply(to: window, mode: prefs.appearanceMode)

        leadingPaneController.loadMarkdownFile(at: urls[0])
        trailingPaneController.loadMarkdownFile(at: urls[1])
    }

    func prepareForPresentation() {
        transitionCoordinator.prepareForPresentation(window: window)
    }

    func animatePresentation() {
        transitionCoordinator.animatePresentation(window: window)
    }

    override func windowDidLoad() {
        setupContentView()
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

    private func setupContentView() {
        splitViewController.splitView.isVertical = true
        splitViewController.splitView.dividerStyle = .thin

        let leadingItem = NSSplitViewItem(viewController: leadingPaneController)
        leadingItem.minimumThickness = 320
        let trailingItem = NSSplitViewItem(viewController: trailingPaneController)
        trailingItem.minimumThickness = 320

        splitViewController.addSplitViewItem(leadingItem)
        splitViewController.addSplitViewItem(trailingItem)
        window?.contentViewController = splitViewController
        splitViewController.view.wantsLayer = true
    }

    private func finishClose() {
        transitionCoordinator.resetAfterClose()
        shouldBypassCloseAnimation = false
        didCloseHandler?()
        didCloseHandler = nil
    }

    private static func makePanel() -> NSPanel {
        let panel = NSPanel(
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
        panel.tabbingMode = .preferred
        panel.tabbingIdentifier = "MarkdownPreview"
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.isMovableByWindowBackground = false
        panel.center()
        return panel
    }
}
