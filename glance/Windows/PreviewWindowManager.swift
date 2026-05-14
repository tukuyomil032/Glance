import AppKit

@MainActor
final class PreviewWindowManager {
    private var controllers: [PreviewWindowController] = []

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

    private func register(_ controller: PreviewWindowController) {
        controllers.append(controller)
        controller.setDidCloseHandler { [weak self, weak controller] in
            self?.controllers.removeAll { $0 === controller }
        }

        controller.loadWindow()
        controller.ensureContentConfigured()
        tabWindowIfNeeded(controller.window)
        controller.showWindow(nil)
        logPreviewWindowState("openPreview", window: controller.window)
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

    private func canHostTabbedWindow(_ controller: PreviewWindowController) -> Bool {
        guard let window = controller.window else {
            return false
        }
        return window.isVisible
            && !window.isMiniaturized
            && isWindowOnVisibleScreen(window)
    }

    private func isWindowOnVisibleScreen(_ window: NSWindow) -> Bool {
        guard let screen = window.screen else {
            return false
        }
        return screen.visibleFrame.contains(window.frame, tolerance: 0.5)
    }

    private func logPreviewWindowState(_ event: String, window: NSWindow?) {
        PreviewWindowDiagnostics.dump(event: event, window: window)
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
