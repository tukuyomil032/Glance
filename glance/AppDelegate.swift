import AppKit
import SwiftUI
import Combine
import UniformTypeIdentifiers
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

    private var statusItem: NSStatusItem?
    private let hotKeyController = GlobalHotKeyController()

    // MARK: - NSApplicationDelegate

    func applicationDidFinishLaunching(_ notification: Notification) {
        hotKeyController.delegate = self
        NSApp.setActivationPolicy(AppMetadata.isMenuBarAgent() ? .accessory : .regular)
        setupStatusItem()
        registerGlobalHotKey()
    }

    func applicationWillTerminate(_ notification: Notification) {
        hotKeyController.unregister()
    }

    func applicationDidResignActive(_ notification: Notification) {
        let hasVisibleWindows = NSApp.windows.contains { $0.isVisible }
        if !hasVisibleWindows && AppMetadata.isMenuBarAgent() {
            NSApp.setActivationPolicy(.accessory)
        }
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

        NSApp.activate(ignoringOtherApps: true)
        panel.orderFrontRegardless()

        panel.begin { [weak self] response in
            guard response == .OK, let url = panel.url else { return }
            self?.openPreview(for: url)
        }
    }

    func openPreview(for url: URL) {
        let controller = PreviewWindowController.makeOrBringToFront()
        controller.loadMarkdownFile(at: url)
        controller.showWindow(nil)
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

    // MARK: - @objc selectors

    @objc private func openMarkdownFileFromMenu() {
        openMarkdownFile()
    }

    @objc func openSettings() {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
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
