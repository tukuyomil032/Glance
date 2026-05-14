import AppKit

@MainActor
struct PreviewWindowActivationController {
    let isMenuBarAgent: @MainActor () -> Bool
    let setActivationPolicy: @MainActor (NSApplication.ActivationPolicy) -> Void
    let activate: @MainActor () -> Void

    init(
        isMenuBarAgent: @escaping @MainActor () -> Bool = { AppMetadata.isMenuBarAgent() },
        setActivationPolicy: @escaping @MainActor (NSApplication.ActivationPolicy) -> Void = {
            NSApp.setActivationPolicy($0)
        },
        activate: @escaping @MainActor () -> Void = {
            NSRunningApplication.current.activate()
        }
    ) {
        self.isMenuBarAgent = isMenuBarAgent
        self.setActivationPolicy = setActivationPolicy
        self.activate = activate
    }

    func prepareForPreviewPresentation(then continuation: @escaping @MainActor () -> Void) {
        guard isMenuBarAgent() else {
            continuation()
            return
        }

        setActivationPolicy(.regular)
        DispatchQueue.main.async {
            self.activate()
            continuation()
        }
    }

    func restoreAccessoryPolicyAfterResign(
        hasVisibleWindows: Bool,
        hasOpenPreviewWindows: Bool,
        isPendingPresentation: Bool = false
    ) {
        guard isMenuBarAgent(),
              !hasVisibleWindows,
              !hasOpenPreviewWindows,
              !isPendingPresentation else {
            return
        }

        setActivationPolicy(.accessory)
    }
}
