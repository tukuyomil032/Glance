import AppKit

@MainActor
final class PreviewWindowManager {
    private var controllers: [NSWindowController] = []

    var openWindowCount: Int {
        controllers.count
    }

    var hasOpenPreviewWindows: Bool {
        !controllers.isEmpty
    }

    @discardableResult
    func openPreview(for url: URL) -> PreviewWindowController {
        let controller = PreviewWindowController()
        register(controller)
        controller.loadMarkdownFile(at: url)
        return controller
    }

    @discardableResult
    func openSplitPreview(for urls: [URL]) -> SplitPreviewWindowController {
        let controller = SplitPreviewWindowController()
        register(controller)
        controller.loadMarkdownFiles(at: urls)
        return controller
    }

    @discardableResult
    func openSplitPreview(leftURL: URL, rightURL: URL) -> SplitPreviewWindowController {
        openSplitPreview(for: [leftURL, rightURL])
    }

    private func register(_ controller: PreviewWindowController) {
        controllers.append(controller)
        controller.setDidCloseHandler { [weak self, weak controller] in
            self?.controllers.removeAll { $0 === controller }
        }

        controller.loadWindow()
        controller.ensureContentConfigured()
        restoreWindowPresentationState(controller.window, orderFront: false)
        controller.prepareForPresentation()
        tabWindowIfNeeded(controller.window)
        controller.showWindow(nil)
        controller.window?.makeKeyAndOrderFront(nil)
        restoreWindowPresentationState(controller.window)
        logPreviewWindowState("openPreview", window: controller.window)
        controller.animatePresentation()
    }

    private func register(_ controller: SplitPreviewWindowController) {
        controllers.append(controller)
        controller.setDidCloseHandler { [weak self, weak controller] in
            self?.controllers.removeAll { $0 === controller }
        }

        controller.loadWindow()
        controller.ensureContentConfigured()
        restoreWindowPresentationState(controller.window, orderFront: false)
        controller.prepareForPresentation()
        tabWindowIfNeeded(controller.window)
        controller.showWindow(nil)
        controller.window?.makeKeyAndOrderFront(nil)
        restoreWindowPresentationState(controller.window)
        logPreviewWindowState("openSplitPreview", window: controller.window)
        controller.animatePresentation()
    }

    private func restoreWindowPresentationState(_ window: NSWindow?, orderFront: Bool = true) {
        guard let window else { return }

        if window.isMiniaturized {
            window.deminiaturize(nil)
        }

        if !isWindowOnVisibleScreen(window) {
            moveWindowIntoVisibleScreen(window)
        }

        if orderFront && !window.isVisible {
            window.orderFront(nil)
        }
        window.alphaValue = 1
    }

    @discardableResult
    private func tabWindowIfNeeded(_ window: NSWindow?) -> Bool {
        guard let newWindow = window,
              let existingController = controllers.dropLast().reversed().first(where: canHostTabbedWindow),
              let existingHost = existingController.window else {
            return false
        }
        existingHost.tabbingMode = .preferred
        newWindow.tabbingMode = .preferred
        existingHost.addTabbedWindow(newWindow, ordered: .above)
        newWindow.tabGroup?.selectedWindow = newWindow
        return true
    }

    private func canHostTabbedWindow(_ controller: NSWindowController) -> Bool {
        guard let window = controller.window else {
            return false
        }

        return window.isVisible
            && !window.isMiniaturized
            && !isClosingPreviewWindow(controller)
            && isWindowOnVisibleScreen(window)
    }

    private func isClosingPreviewWindow(_ controller: NSWindowController) -> Bool {
        if let controller = controller as? PreviewWindowController {
            return controller.isClosingPreviewWindow
        }

        if let controller = controller as? SplitPreviewWindowController {
            return controller.isClosingPreviewWindow
        }

        return false
    }

    private func isWindowOnVisibleScreen(_ window: NSWindow) -> Bool {
        guard let screen = window.screen else {
            return false
        }

        return screen.visibleFrame.contains(window.frame, tolerance: 0.5)
    }

    private func moveWindowIntoVisibleScreen(_ window: NSWindow) {
        guard let screen = bestScreen(for: window.frame) else {
            return
        }

        let visibleFrame = screen.visibleFrame
        let width = min(window.frame.width, visibleFrame.width)
        let height = min(window.frame.height, visibleFrame.height)
        let x = clamp(
            window.frame.minX,
            min: visibleFrame.minX,
            max: visibleFrame.maxX - width
        )
        let y = clamp(
            window.frame.minY,
            min: visibleFrame.minY,
            max: visibleFrame.maxY - height
        )
        let origin = NSPoint(
            x: x,
            y: y
        )
        window.setFrame(
            NSRect(origin: origin, size: NSSize(width: width, height: height)),
            display: false
        )
    }

    private func bestScreen(for frame: NSRect) -> NSScreen? {
        let screens = NSScreen.screens
        let bestIntersectingScreen = screens.max { lhs, rhs in
            lhs.visibleFrame.intersection(frame).area < rhs.visibleFrame.intersection(frame).area
        }

        if let bestIntersectingScreen,
           bestIntersectingScreen.visibleFrame.intersection(frame).area > 0 {
            return bestIntersectingScreen
        }

        return NSScreen.main ?? screens.first
    }

    private func clamp(_ value: CGFloat, min minValue: CGFloat, max maxValue: CGFloat) -> CGFloat {
        if maxValue < minValue {
            return minValue
        }

        return min(max(value, minValue), maxValue)
    }

    private func logPreviewWindowState(_ event: String, window: NSWindow?) {
        #if DEBUG
        PreviewWindowDiagnostics.dump(event: event, window: window)
        #endif
    }
}

private extension NSRect {
    var area: CGFloat {
        guard !isNull, !isEmpty else {
            return 0
        }

        return width * height
    }

    func contains(_ rect: NSRect, tolerance: CGFloat) -> Bool {
        minX <= rect.minX + tolerance
            && minY <= rect.minY + tolerance
            && maxX >= rect.maxX - tolerance
            && maxY >= rect.maxY - tolerance
    }
}
