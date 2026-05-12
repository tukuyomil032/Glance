import AppKit

@MainActor
final class PreviewWindowManager {
    private var controllers: [NSWindowController] = []

    var openWindowCount: Int {
        controllers.count
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
        controller.prepareForPresentation()
        tabWindowIfNeeded(controller.window)
        controller.showWindow(nil)
        controller.window?.makeKeyAndOrderFront(nil)
        controller.animatePresentation()
    }

    private func register(_ controller: SplitPreviewWindowController) {
        controllers.append(controller)
        controller.setDidCloseHandler { [weak self, weak controller] in
            self?.controllers.removeAll { $0 === controller }
        }

        controller.loadWindow()
        controller.prepareForPresentation()
        tabWindowIfNeeded(controller.window)
        controller.showWindow(nil)
        controller.window?.makeKeyAndOrderFront(nil)
        controller.animatePresentation()
    }

    private func tabWindowIfNeeded(_ window: NSWindow?) {
        guard let existingHost = controllers.dropLast().last?.window,
              let newWindow = window else {
            return
        }
        existingHost.addTabbedWindow(newWindow, ordered: .above)
    }
}
