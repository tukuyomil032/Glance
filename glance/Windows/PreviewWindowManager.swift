import AppKit

@MainActor
final class PreviewWindowManager {
    private var controllers: [PreviewWindowController] = []

    var openWindowCount: Int {
        controllers.count
    }

    @discardableResult
    func openPreview(for url: URL) -> PreviewWindowController {
        let controller = PreviewWindowController()
        controllers.append(controller)
        controller.setDidCloseHandler { [weak self, weak controller] in
            self?.controllers.removeAll { $0 === controller }
        }

        controller.loadWindow()
        if let existingHost = controllers.dropLast().last?.window,
           let newWindow = controller.window {
            existingHost.addTabbedWindow(newWindow, ordered: .above)
        }
        controller.loadMarkdownFile(at: url)
        controller.showWindow(nil)
        controller.window?.makeKeyAndOrderFront(nil)
        return controller
    }
}
