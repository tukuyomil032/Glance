import AppKit
import SwiftUI
import Combine
import Carbon

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, ObservableObject {

    // MARK: - Published properties

    @Published var appLocale: Locale = {
        let lang = PreviewPreferences.load().language
        if lang == "system" { return .autoupdatingCurrent }
        return Locale(identifier: lang)
    }()

    // MARK: - Internal state

    let updaterViewModel = UpdaterViewModel()
    private let isUITestMode = AppMetadata.isUITestMode()

    private var statusItem: NSStatusItem?
    private var uiTestHostWindow: NSWindow?
    private let hotKeyController = GlobalHotKeyController()
    private let openPanelCoordinator = MarkdownOpenPanelCoordinator()
    private let previewWindowManager: PreviewWindowManager
    private let previewActivationController: PreviewWindowActivationController
    private let previewOpener: @MainActor (URL) -> Void
    private let splitPreviewOpener: @MainActor (URL, URL) -> Void

    override init() {
        let previewWindowManager = PreviewWindowManager()
        self.previewWindowManager = previewWindowManager
        previewActivationController = PreviewWindowActivationController()
        previewOpener = { url in
            previewWindowManager.openPreview(for: url)
        }
        splitPreviewOpener = { leftURL, rightURL in
            previewWindowManager.openSplitPreview(leftURL: leftURL, rightURL: rightURL)
        }
        super.init()
    }

    init(
        previewActivationController: PreviewWindowActivationController,
        previewOpener: @escaping @MainActor (URL) -> Void,
        splitPreviewOpener: @escaping @MainActor (URL, URL) -> Void
    ) {
        self.previewWindowManager = PreviewWindowManager()
        self.previewActivationController = previewActivationController
        self.previewOpener = previewOpener
        self.splitPreviewOpener = splitPreviewOpener
        super.init()
    }

    init(
        previewActivationController: PreviewWindowActivationController,
        previewOpener: @escaping @MainActor (URL) -> Void,
        splitPreviewOpener: @escaping @MainActor (URL, URL) -> Void,
        previewWindowManager: PreviewWindowManager
    ) {
        self.previewWindowManager = previewWindowManager
        self.previewActivationController = previewActivationController
        self.previewOpener = previewOpener
        self.splitPreviewOpener = splitPreviewOpener
        super.init()
    }

    // MARK: - NSApplicationDelegate

    func applicationDidFinishLaunching(_ notification: Notification) {
        if isUITestMode {
            NSApp.setActivationPolicy(.regular)
            NSWindow.allowsAutomaticWindowTabbing = true
            launchUITestMode()
            return
        }

        hotKeyController.delegate = self
        NSApp.setActivationPolicy(AppMetadata.isMenuBarAgent() ? .accessory : .regular)
        NSWindow.allowsAutomaticWindowTabbing = true
        LaunchSplashController.showIfNeeded()
        setupStatusItem()
        registerGlobalHotKey()
    }

    func applicationWillTerminate(_ notification: Notification) {
        hotKeyController.unregister()
    }

    func applicationDidResignActive(_ notification: Notification) {
        guard !isUITestMode else { return }
        let hasVisibleWindows = NSApp.windows.contains { $0.isVisible }
        previewActivationController.restoreAccessoryPolicyAfterResign(
            hasVisibleWindows: hasVisibleWindows,
            hasOpenPreviewWindows: previewWindowManager.hasOpenPreviewWindows
        )
    }

    // MARK: - Global hotkey

    func registerGlobalHotKey() {
        _ = hotKeyController.register(
            keyCode: UInt32(kVK_ANSI_G),
            modifiers: UInt32(cmdKey)
        )
    }

    // MARK: - File operations

    func openMarkdownFile() {
        openPanelCoordinator.openMarkdownFile { [weak self] url in
            self?.openPreview(for: url)
        }
    }

    func openSplitMarkdownFiles() {
        openPanelCoordinator.openSplitMarkdownFiles { [weak self] urls in
            guard urls.count == 2 else { return }
            self?.openSplitPreview(leftURL: urls[0], rightURL: urls[1])
        }
    }

    func openPreview(for url: URL) {
        previewActivationController.prepareForPreviewPresentation { [weak self] in
            self?.previewOpener(url)
        }
    }

    func openSplitPreview(leftURL: URL, rightURL: URL) {
        previewActivationController.prepareForPreviewPresentation { [weak self] in
            self?.splitPreviewOpener(leftURL, rightURL)
        }
    }

    // MARK: - Status item setup

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        guard let button = statusItem?.button else { return }

        if let image = NSImage(named: "menuBarIcon") {
            image.isTemplate = true
            button.image = image
        } else {
            let fallback = NSImage(systemSymbolName: "doc.richtext", accessibilityDescription: "glance")
            fallback?.isTemplate = true
            button.image = fallback
        }

        button.toolTip = "glance — Markdown Preview\n⌘G to open file"
        statusItem?.menu = buildStatusMenu()
    }

    private func buildStatusMenu() -> NSMenu {
        let menu = NSMenu()

        let openItem = NSMenuItem(
            title: "Open Markdown File…",
            action: #selector(openMarkdownFileFromMenu),
            keyEquivalent: ""
        )
        openItem.target = self
        menu.addItem(openItem)

        let splitItem = NSMenuItem(
            title: "Open in Split View…",
            action: #selector(openSplitMarkdownFilesFromMenu),
            keyEquivalent: ""
        )
        splitItem.target = self
        menu.addItem(splitItem)

        let settingsItem = NSMenuItem(
            title: "Settings…",
            action: #selector(openSettings),
            keyEquivalent: ","
        )
        settingsItem.keyEquivalentModifierMask = .command
        settingsItem.target = self
        menu.addItem(settingsItem)

        menu.addItem(.separator())

        let updatesItem = NSMenuItem(
            title: "Check for Updates…",
            action: #selector(checkForUpdates),
            keyEquivalent: ""
        )
        updatesItem.target = self
        menu.addItem(updatesItem)

        menu.addItem(.separator())

        let quitItem = NSMenuItem(
            title: "Quit glance",
            action: #selector(NSApplication.terminate(_:)),
            keyEquivalent: "q"
        )
        quitItem.keyEquivalentModifierMask = .command
        menu.addItem(quitItem)

        return menu
    }

    private func refreshStatusMenu() {
        statusItem?.menu = buildStatusMenu()
    }

    private func showUITestHostWindow() {
        guard uiTestHostWindow == nil else {
            uiTestHostWindow?.makeKeyAndOrderFront(nil)
            return
        }

        let hostView = NSHostingView(
            rootView: Text("glance UI Test Host")
                .frame(minWidth: 480, minHeight: 320)
        )
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 480, height: 320),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "glance UI Test Host"
        window.center()
        window.contentView = hostView
        window.makeKeyAndOrderFront(nil)
        uiTestHostWindow = window
    }

    private func launchUITestMode() {
        if let urls = AppMetadata.uiTestSplitPreviewURLs() {
            openSplitPreview(leftURL: urls[0], rightURL: urls[1])
            return
        }

        if let url = AppMetadata.uiTestPreviewURL() {
            openPreview(for: url)
            return
        }

        showUITestHostWindow()
    }

    // MARK: - @objc selectors

    @objc private func openMarkdownFileFromMenu() {
        openMarkdownFile()
    }

    @objc private func openSplitMarkdownFilesFromMenu() {
        openSplitMarkdownFiles()
    }

    @objc func openSettings() {
        NSApp.setActivationPolicy(.regular)
        NSRunningApplication.current.activate()
        SettingsWindowController.show(rootView: makeSettingsView())
    }

    @objc private func checkForUpdates() {
        updaterViewModel.checkForUpdates()
    }

    private func makeSettingsView() -> some View {
        SettingsView(
            appLocale: Binding(
                get: { self.appLocale },
                set: { self.appLocale = $0 }
            ),
            updaterViewModel: updaterViewModel
        )
        .environment(\.locale, appLocale)
    }
}

extension AppDelegate: GlobalHotKeyControllerDelegate {
    func globalHotKeyControllerDidTrigger(_ controller: GlobalHotKeyController) {
        openMarkdownFile()
    }
}
