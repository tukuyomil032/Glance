import AppKit
import Testing
@testable import glance

@MainActor
struct MarkdownOpenPanelCoordinatorTests {
    @Test func whileOpen_reusesExistingPanel() {
        var createdPanels: [FakePanel] = []
        let coordinator = MarkdownOpenPanelCoordinator { _ in
            let panel = FakePanel()
            createdPanels.append(panel)
            return panel
        } beforePresent: { action in
            action()
        }

        coordinator.openMarkdownFile { _ in }
        coordinator.openMarkdownFile { _ in }

        #expect(createdPanels.count == 1)
        #expect(createdPanels[0].orderFrontCount == 2)
    }

    @Test func cancel_releasesActivePanel() {
        var createdPanels: [FakePanel] = []
        let coordinator = MarkdownOpenPanelCoordinator { _ in
            let panel = FakePanel()
            createdPanels.append(panel)
            return panel
        } beforePresent: { action in
            action()
        }

        coordinator.openMarkdownFile { _ in }
        createdPanels[0].complete(with: .cancel)
        coordinator.openMarkdownFile { _ in }

        #expect(createdPanels.count == 2)
    }

    @Test func ok_releasesAndForwardsSelection() {
        var createdPanels: [FakePanel] = []
        let coordinator = MarkdownOpenPanelCoordinator { _ in
            let panel = FakePanel()
            createdPanels.append(panel)
            return panel
        } beforePresent: { action in
            action()
        }

        let selectedURL = URL(fileURLWithPath: "/tmp/file.md")
        var receivedURL: URL?

        coordinator.openMarkdownFile { url in
            receivedURL = url
        }

        createdPanels[0].selectedURLs = [selectedURL]
        createdPanels[0].complete(with: .OK)
        coordinator.openMarkdownFile { _ in }

        #expect(receivedURL == selectedURL)
        #expect(createdPanels.count == 2)
    }

    @Test func whileReusingPanel_keepsSingleSelectionDelivery() {
        var createdPanels: [FakePanel] = []
        let coordinator = MarkdownOpenPanelCoordinator { _ in
            let panel = FakePanel()
            createdPanels.append(panel)
            return panel
        } beforePresent: { action in
            action()
        }

        let selectedURL = URL(fileURLWithPath: "/tmp/shared.md")
        var receivedCount = 0

        coordinator.openMarkdownFile { _ in
            receivedCount += 1
        }
        coordinator.openMarkdownFile { _ in }

        createdPanels[0].selectedURLs = [selectedURL]
        createdPanels[0].complete(with: .OK)

        #expect(createdPanels.count == 1)
        #expect(receivedCount == 1)
    }

    @Test func splitSelectionRequiresExactlyTwoFiles() {
        var createdPanels: [FakePanel] = []
        let coordinator = MarkdownOpenPanelCoordinator { _ in
            let panel = FakePanel()
            createdPanels.append(panel)
            return panel
        } beforePresent: { action in
            action()
        }

        let selectedURLs = [
            URL(fileURLWithPath: "/tmp/first.md"),
            URL(fileURLWithPath: "/tmp/second.md")
        ]
        var receivedURLs: [URL] = []

        coordinator.openSplitMarkdownFiles { urls in
            receivedURLs = urls
        }

        createdPanels[0].selectedURLs = selectedURLs
        createdPanels[0].complete(with: .OK)

        #expect(createdPanels.count == 1)
        #expect(receivedURLs == selectedURLs)
    }

    @Test func splitSelectionRejectsNonPairs() {
        var createdPanels: [FakePanel] = []
        let coordinator = MarkdownOpenPanelCoordinator(
            panelFactory: { _ in
                let panel = FakePanel()
                createdPanels.append(panel)
                return panel
            },
            beforePresent: { action in
                action()
            },
            invalidSplitSelectionHandler: {}
        )

        var receivedURLs: [URL] = []

        coordinator.openSplitMarkdownFiles { urls in
            receivedURLs = urls
        }

        createdPanels[0].selectedURLs = [URL(fileURLWithPath: "/tmp/only-one.md")]
        createdPanels[0].complete(with: .OK)

        #expect(createdPanels.count == 1)
        #expect(receivedURLs.isEmpty)
    }
}

@MainActor
private final class FakePanel: MarkdownOpenPanelPresenting {
    var selectedURLs: [URL] = []
    var url: URL? { selectedURLs.first }
    var urls: [URL] { selectedURLs }
    var orderFrontCount = 0
    private var handler: ((NSApplication.ModalResponse) -> Void)?

    func orderFrontRegardless() {
        orderFrontCount += 1
    }

    func begin(_ handler: @escaping (NSApplication.ModalResponse) -> Void) {
        self.handler = handler
    }

    func complete(with response: NSApplication.ModalResponse) {
        handler?(response)
    }
}
