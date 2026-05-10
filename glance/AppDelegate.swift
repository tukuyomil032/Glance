import AppKit
import SwiftUI
import Combine
import ApplicationServices
import UniformTypeIdentifiers

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
    private var hotKeyMonitor: Any?
    private var accessibilityCheckTimer: Timer?

    // MARK: - NSApplicationDelegate

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        setupStatusItem()
        if requestAccessibilityIfNeeded() {
            registerGlobalHotKey()
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        if let monitor = hotKeyMonitor {
            NSEvent.removeMonitor(monitor)
        }
    }

    func applicationDidResignActive(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
    }

    // MARK: - Accessibility permission

    @discardableResult
    func requestAccessibilityIfNeeded() -> Bool {
        let options: NSDictionary = [
            kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true
        ]
        let trusted = AXIsProcessTrustedWithOptions(options)
        if !trusted {
            scheduleAccessibilityStatusCheck()
        }
        return trusted
    }

    private func scheduleAccessibilityStatusCheck() {
        var checkCount = 0
        accessibilityCheckTimer = Timer.scheduledTimer(
            withTimeInterval: 0.5,
            repeats: true
        ) { [weak self] timer in
            checkCount += 1
            if AXIsProcessTrusted() {
                timer.invalidate()
                Task { @MainActor [weak self] in
                    self?.accessibilityCheckTimer = nil
                    self?.registerGlobalHotKey()
                    self?.refreshStatusMenu()
                }
            } else if checkCount > 120 {
                timer.invalidate()
                Task { @MainActor [weak self] in
                    self?.accessibilityCheckTimer = nil
                }
            }
        }
    }

    // MARK: - Global hotkey

    func registerGlobalHotKey() {
        guard AXIsProcessTrusted() else { return }

        if let existing = hotKeyMonitor {
            NSEvent.removeMonitor(existing)
            hotKeyMonitor = nil
        }

        hotKeyMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { event in
            let onlyCommand = event.modifierFlags
                .intersection(.deviceIndependentFlagsMask) == .command
            if event.keyCode == 5 && onlyCommand {
                Task { @MainActor [weak self] in
                    self?.openMarkdownFile()
                }
            }
        }
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

        menu.addItem(.separator())

        if !AXIsProcessTrusted() {
            let axItem = NSMenuItem(
                title: "Grant Accessibility Permission…",
                action: #selector(openAccessibilitySettings),
                keyEquivalent: ""
            )
            axItem.target = self
            menu.addItem(axItem)
            menu.addItem(.separator())
        }

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

    @objc private func openAccessibilitySettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }

    @objc private func openSettings() {
        NSApp.activate(ignoringOtherApps: true)
        NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
    }

    @objc private func checkForUpdates() {
        updaterViewModel.checkForUpdates()
    }
}
