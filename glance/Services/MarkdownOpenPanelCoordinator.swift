import AppKit
import UniformTypeIdentifiers

@MainActor
protocol MarkdownOpenPanelPresenting: AnyObject {
    var url: URL? { get }
    var urls: [URL] { get }
    func orderFrontRegardless()
    func begin(_ handler: @escaping (NSApplication.ModalResponse) -> Void)
}

@MainActor
final class NSOpenPanelAdapter: MarkdownOpenPanelPresenting {
    private let panel: NSOpenPanel

    init(panel: NSOpenPanel) {
        self.panel = panel
    }

    var url: URL? { panel.url }

    var urls: [URL] { panel.urls }

    func orderFrontRegardless() {
        panel.orderFrontRegardless()
    }

    func begin(_ handler: @escaping (NSApplication.ModalResponse) -> Void) {
        panel.begin(completionHandler: handler)
    }
}

@MainActor
final class MarkdownOpenPanelCoordinator {
    private var activePanel: MarkdownOpenPanelPresenting?
    private let panelFactory: @MainActor @Sendable (Bool) -> MarkdownOpenPanelPresenting
    private let beforePresent: @MainActor @Sendable (@escaping @MainActor () -> Void) -> Void
    private let invalidSplitSelectionHandler: @MainActor @Sendable () -> Void
    private var isPresentingPanel = false

    init(
        panelFactory: @escaping @MainActor @Sendable (Bool) -> MarkdownOpenPanelPresenting = MarkdownOpenPanelCoordinator.defaultPanelFactory,
        beforePresent: @escaping @MainActor @Sendable (@escaping @MainActor () -> Void) -> Void = LaunchSplashController.performAfterDismissIfNeeded,
        invalidSplitSelectionHandler: @escaping @MainActor @Sendable () -> Void = MarkdownOpenPanelCoordinator.defaultInvalidSplitSelectionHandler
    ) {
        self.panelFactory = panelFactory
        self.beforePresent = beforePresent
        self.invalidSplitSelectionHandler = invalidSplitSelectionHandler
    }

    func openMarkdownFile(onSelect: @escaping (URL) -> Void) {
        openMarkdownFiles(allowsMultipleSelection: false) { urls in
            guard let url = urls.first else { return }
            onSelect(url)
        }
    }

    func openSplitMarkdownFiles(onSelect: @escaping ([URL]) -> Void) {
        openMarkdownFiles(allowsMultipleSelection: true) { urls in
            guard urls.count == 2 else {
                self.invalidSplitSelectionHandler()
                return
            }
            onSelect(urls)
        }
    }

    private func openMarkdownFiles(
        allowsMultipleSelection: Bool,
        onSelect: @escaping ([URL]) -> Void
    ) {
        if let activePanel {
            NSRunningApplication.current.activate()
            activePanel.orderFrontRegardless()
            return
        }

        guard !isPresentingPanel else { return }
        isPresentingPanel = true

        beforePresent { [weak self] in
            self?.presentPanel(allowsMultipleSelection: allowsMultipleSelection, onSelect: onSelect)
        }
    }

    private func presentPanel(
        allowsMultipleSelection: Bool,
        onSelect: @escaping ([URL]) -> Void
    ) {
        let panel = panelFactory(allowsMultipleSelection)
        activePanel = panel
        isPresentingPanel = false

        NSRunningApplication.current.activate()
        panel.orderFrontRegardless()
        panel.begin { [weak self, weak panel] response in
            guard let self else { return }
            defer { self.activePanel = nil }
            guard response == .OK, let url = panel?.url else { return }
            let urls = panel?.urls ?? [url]
            onSelect(urls)
        }
    }

    private static func defaultInvalidSplitSelectionHandler() {
        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = String(localized: "Select exactly two Markdown files")
        alert.informativeText = String(localized: "Split View requires exactly two Markdown files.")
        alert.runModal()
    }

    private static func defaultPanelFactory(allowsMultipleSelection: Bool) -> MarkdownOpenPanelPresenting {
        let panel = NSOpenPanel()
        if allowsMultipleSelection {
            panel.title = String(localized: "Open Markdown Files for Split View")
            panel.message = String(localized: "Select exactly two Markdown files to preview side by side")
        } else {
            panel.title = String(localized: "Open Markdown File")
            panel.message = String(localized: "Select a Markdown file to preview")
        }
        panel.allowedContentTypes = [
            .init(filenameExtension: "md") ?? .plainText,
            .init(filenameExtension: "markdown") ?? .plainText,
            .init(filenameExtension: "mdown") ?? .plainText,
            .init(filenameExtension: "mkd") ?? .plainText,
        ]
        panel.allowsMultipleSelection = allowsMultipleSelection
        panel.canChooseDirectories = false
        return NSOpenPanelAdapter(panel: panel)
    }
}
