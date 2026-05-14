import AppKit

@MainActor
struct PreviewWindowActivationController {
    let isMenuBarAgent: @MainActor () -> Bool
    let setActivationPolicy: @MainActor (NSApplication.ActivationPolicy) -> Void

    init(
        isMenuBarAgent: @escaping @MainActor () -> Bool = { AppMetadata.isMenuBarAgent() },
        setActivationPolicy: @escaping @MainActor (NSApplication.ActivationPolicy) -> Void = {
            NSApp.setActivationPolicy($0)
        }
    ) {
        self.isMenuBarAgent = isMenuBarAgent
        self.setActivationPolicy = setActivationPolicy
    }

    func restoreAccessoryPolicyAfterResign(
        hasVisibleWindows: Bool,
        hasOpenPreviewWindows: Bool
    ) {
        guard isMenuBarAgent(),
              !hasVisibleWindows,
              !hasOpenPreviewWindows else {
            return
        }

        setActivationPolicy(.accessory)
    }
}
