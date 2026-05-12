import AppKit
import Testing
@testable import glance

@MainActor
struct PreviewWindowTransitionCoordinatorTests {
    @Test func prepareForPresentationShrinksAndFadesWindow() {
        let coordinator = PreviewWindowTransitionCoordinator()
        let window = NSPanel(
            contentRect: NSRect(x: 100, y: 100, width: 800, height: 600),
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered,
            defer: false
        )
        let originalFrame = window.frame

        coordinator.prepareForPresentation(window: window)

        #expect(window.alphaValue == 0)
        #expect(window.frame.width < originalFrame.width)
        #expect(window.frame.height < originalFrame.height)
    }
}
