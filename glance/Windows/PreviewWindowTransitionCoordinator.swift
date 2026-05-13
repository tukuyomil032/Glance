import AppKit
import QuartzCore

@MainActor
final class PreviewWindowTransitionCoordinator {
    private let presentationScale: CGFloat
    private let animationDuration: TimeInterval
    private var isPreparingPresentation = false
    private(set) var isClosing = false
    private var targetPresentationFrame: NSRect?

    init(
        presentationScale: CGFloat = 0.96,
        animationDuration: TimeInterval = 0.18
    ) {
        self.presentationScale = presentationScale
        self.animationDuration = animationDuration
    }

    func prepareForPresentation(window: NSWindow?) {
        guard let window, !isPreparingPresentation else { return }
        isPreparingPresentation = true

        let targetFrame = window.frame
        targetPresentationFrame = targetFrame
        let startFrame = scaledFrame(from: targetFrame, scale: presentationScale)
        window.setFrame(startFrame, display: false)
        window.alphaValue = 1
    }

    func animatePresentation(window: NSWindow?) {
        guard let window else { return }
        guard let targetPresentationFrame else {
            window.alphaValue = 1
            window.setFrame(window.frame, display: true)
            isPreparingPresentation = false
            return
        }
        NSAnimationContext.runAnimationGroup { context in
            context.duration = animationDuration
            context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            window.animator().alphaValue = 1
            window.animator().setFrame(targetPresentationFrame, display: true)
        } completionHandler: {
            Task { @MainActor in
                // Normalize final state to avoid drift from interrupted/rounded animations.
                window.alphaValue = 1
                window.setFrame(targetPresentationFrame, display: true)
                self.isPreparingPresentation = false
                self.targetPresentationFrame = nil
            }
        }
    }

    func beginCloseAnimation(window: NSWindow?, completion: @escaping @MainActor () -> Void) {
        guard let window, !isClosing else {
            return
        }

        isClosing = true
        let targetFrame = scaledFrame(from: window.frame, scale: presentationScale)

        NSAnimationContext.runAnimationGroup { context in
            context.duration = animationDuration
            context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            window.animator().alphaValue = 0
            window.animator().setFrame(targetFrame, display: true)
        } completionHandler: {
            Task { @MainActor in
                self.isClosing = false
                completion()
            }
        }
    }

    func resetAfterClose() {
        isClosing = false
        isPreparingPresentation = false
        targetPresentationFrame = nil
    }

    private func scaledFrame(from frame: NSRect, scale: CGFloat) -> NSRect {
        let widthDelta = frame.width * (1 - scale)
        let heightDelta = frame.height * (1 - scale)
        return frame.insetBy(dx: widthDelta / 2, dy: heightDelta / 2)
    }
}
