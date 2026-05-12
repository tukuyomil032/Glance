import AppKit
import UniformTypeIdentifiers

@MainActor
protocol MarkdownOpenPanelPresenting: AnyObject {
    var url: URL? { get }
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
    private let panelFactory: @MainActor @Sendable () -> MarkdownOpenPanelPresenting
    private let beforePresent: @MainActor @Sendable (@escaping @MainActor () -> Void) -> Void
    private var isPresentingPanel = false

    init(
        panelFactory: @escaping @MainActor @Sendable () -> MarkdownOpenPanelPresenting = MarkdownOpenPanelCoordinator.defaultPanelFactory,
        beforePresent: @escaping @MainActor @Sendable (@escaping @MainActor () -> Void) -> Void = LaunchSplashController.performAfterDismissIfNeeded
    ) {
        self.panelFactory = panelFactory
        self.beforePresent = beforePresent
    }

    func openMarkdownFile(onSelect: @escaping (URL) -> Void) {
        if let activePanel {
            NSApp.activate(ignoringOtherApps: true)
            activePanel.orderFrontRegardless()
            return
        }

        guard !isPresentingPanel else { return }
        isPresentingPanel = true

        beforePresent { [weak self] in
            self?.presentPanel(onSelect: onSelect)
        }
    }

    private func presentPanel(onSelect: @escaping (URL) -> Void) {
        let panel = panelFactory()
        activePanel = panel
        isPresentingPanel = false

        NSApp.activate(ignoringOtherApps: true)
        panel.orderFrontRegardless()
        panel.begin { [weak self, weak panel] response in
            guard let self else { return }
            defer { self.activePanel = nil }
            guard response == .OK, let url = panel?.url else { return }
            onSelect(url)
        }
    }

    private static func defaultPanelFactory() -> MarkdownOpenPanelPresenting {
        let panel = NSOpenPanel()
        panel.title = String(localized: "Open Markdown File")
        panel.message = String(localized: "Select a Markdown file to preview")
        panel.allowedContentTypes = [
            .init(filenameExtension: "md") ?? .plainText,
            .init(filenameExtension: "markdown") ?? .plainText,
            .init(filenameExtension: "mdown") ?? .plainText,
            .init(filenameExtension: "mkd") ?? .plainText,
        ]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        return NSOpenPanelAdapter(panel: panel)
    }
}
