import AppKit

@MainActor
struct PreviewWindowActivationController {
    let isMenuBarAgent: @MainActor () -> Bool
    let setActivationPolicy: @MainActor (NSApplication.ActivationPolicy) -> Void
    let activate: @MainActor (Bool) -> Void

    init(
        isMenuBarAgent: @escaping @MainActor () -> Bool = { AppMetadata.isMenuBarAgent() },
        setActivationPolicy: @escaping @MainActor (NSApplication.ActivationPolicy) -> Void = {
            NSApp.setActivationPolicy($0)
        },
        activate: @escaping @MainActor (Bool) -> Void = {
            NSApp.activate(ignoringOtherApps: $0)
        }
    ) {
        self.isMenuBarAgent = isMenuBarAgent
        self.setActivationPolicy = setActivationPolicy
        self.activate = activate
    }

    func prepareForPreviewPresentation() {
        guard isMenuBarAgent() else {
            return
        }

        setActivationPolicy(.regular)
        activate(true)
    }

    func activateAfterPreviewPresentation() {
        guard isMenuBarAgent() else {
            return
        }

        activate(true)
    }

    func restoreAccessoryPolicyAfterResign(hasVisibleWindows: Bool, hasOpenPreviewWindows: Bool) {
        guard isMenuBarAgent(), !hasVisibleWindows, !hasOpenPreviewWindows else {
            return
        }

        setActivationPolicy(.accessory)
    }
}
