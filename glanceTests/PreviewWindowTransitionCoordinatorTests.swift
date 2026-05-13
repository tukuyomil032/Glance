import AppKit
import Testing
@testable import glance

@MainActor
struct PreviewWindowTransitionCoordinatorTests {
    @Test func prepareForPresentationShrinksAndKeepsWindowFullyVisible() {
        let coordinator = PreviewWindowTransitionCoordinator()
        let window = NSWindow(
            contentRect: NSRect(x: 100, y: 100, width: 800, height: 600),
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered,
            defer: false
        )
        let originalFrame = window.frame

        coordinator.prepareForPresentation(window: window)

        #expect(window.alphaValue == 1)
        #expect(window.frame.width < originalFrame.width)
        #expect(window.frame.height < originalFrame.height)
    }

    @Test func animatePresentationRestoresAlphaAndFrame() {
        let coordinator = PreviewWindowTransitionCoordinator(animationDuration: 0)
        let window = NSWindow(
            contentRect: NSRect(x: 100, y: 100, width: 800, height: 600),
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered,
            defer: false
        )
        let originalFrame = window.frame

        coordinator.prepareForPresentation(window: window)
        coordinator.animatePresentation(window: window)
        RunLoop.main.run(until: Date().addingTimeInterval(0.01))

        #expect(window.alphaValue == 1)
        #expect(window.frame == originalFrame)
    }

    @Test func animatePresentationNormalizesWhenNoPreparedTargetFrame() {
        let coordinator = PreviewWindowTransitionCoordinator(animationDuration: 0)
        let window = NSWindow(
            contentRect: NSRect(x: 100, y: 100, width: 800, height: 600),
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered,
            defer: false
        )
        let originalFrame = window.frame
        window.alphaValue = 0.2

        coordinator.animatePresentation(window: window)

        #expect(window.alphaValue == 1)
        #expect(window.frame == originalFrame)
    }
}
