import AppKit

@MainActor
final class LaunchSplashController {
    private static var isShown = false
    private static var activeController: LaunchSplashController?

    private let window: NSWindow
    private var dismissalTask: Task<Void, Never>?
    private var pendingActions: [@MainActor () -> Void] = []
    private var isDismissing = false

    private init(window: NSWindow) {
        self.window = window
    }

    static func showIfNeeded() {
        guard !isShown else { return }
        isShown = true

        let controller = LaunchSplashController(window: makeWindow())
        activeController = controller
        controller.presentAndDismiss()
    }

    static func performAfterDismissIfNeeded(_ action: @escaping @MainActor () -> Void) {
        guard let activeController else {
            action()
            return
        }

        activeController.dismiss(then: action)
    }

    private func presentAndDismiss() {
        window.alphaValue = 1
        window.center()
        window.orderFrontRegardless()
        dismissalTask = Task { @MainActor [weak self] in
            try? await Task.sleep(for: .milliseconds(550))
            guard !Task.isCancelled, let self else { return }
            dismiss()
        }
    }

    private func dismiss(then action: (@MainActor () -> Void)? = nil) {
        dismissalTask?.cancel()
        dismissalTask = nil
        if let action {
            pendingActions.append(action)
        }

        guard window.isVisible else {
            finishDismissal()
            return
        }

        guard !isDismissing else {
            return
        }
        isDismissing = true

        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.24
            self.window.animator().alphaValue = 0
        }, completionHandler: {
            Task { @MainActor [weak self] in
                self?.finishDismissal()
            }
        })
    }

    private func finishDismissal() {
        isDismissing = false
        window.orderOut(nil)
        Self.activeController = nil

        let actions = pendingActions
        pendingActions.removeAll()
        actions.forEach { $0() }
    }

    private static func makeWindow() -> NSWindow {
        let contentSize = NSSize(width: 220, height: 220)
        let frame = NSRect(origin: .zero, size: contentSize)
        let window = SplashWindow(contentRect: frame, styleMask: .borderless, backing: .buffered, defer: false)
        window.backgroundColor = .clear
        window.isOpaque = false
        window.hasShadow = false
        window.level = .statusBar
        window.ignoresMouseEvents = true
        window.collectionBehavior = [.canJoinAllSpaces, .transient, .fullScreenAuxiliary]

        let container = NSView(frame: frame)
        let imageView = NSImageView(frame: NSRect(x: 46, y: 46, width: 128, height: 128))
        imageView.image = NSApp.applicationIconImage
        imageView.imageScaling = .scaleProportionallyUpOrDown
        container.addSubview(imageView)
        window.contentView = container

        return window
    }
}

private final class SplashWindow: NSWindow {
    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}
