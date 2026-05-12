import AppKit
import SwiftUI

@MainActor
final class SettingsWindowController: NSWindowController, NSWindowDelegate {
    static var shared: SettingsWindowController?

    private let hostingController: NSHostingController<AnyView>

    static func show(rootView: some View) {
        if let shared {
            shared.update(rootView: rootView)
            shared.showWindow(nil)
            shared.window?.makeKeyAndOrderFront(nil)
            return
        }

        let controller = SettingsWindowController(rootView: rootView)
        shared = controller
        controller.showWindow(nil)
        controller.window?.center()
        controller.window?.makeKeyAndOrderFront(nil)
    }

    init(rootView: some View) {
        hostingController = NSHostingController(rootView: AnyView(rootView))
        let window = NSWindow(contentViewController: hostingController)
        window.styleMask = [.titled, .closable, .miniaturizable]
        window.title = "Settings"
        window.setContentSize(NSSize(width: 360, height: 380))
        window.isReleasedWhenClosed = false
        super.init(window: window)
        window.delegate = self
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }

    func update(rootView: some View) {
        hostingController.rootView = AnyView(rootView)
    }

    func windowWillClose(_ notification: Notification) {
        let hasVisibleWindows = NSApp.windows.contains { $0.isVisible && $0 !== window }
        if !hasVisibleWindows && AppMetadata.isMenuBarAgent() {
            NSApp.setActivationPolicy(.accessory)
        }
        SettingsWindowController.shared = nil
    }
}
