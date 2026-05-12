import AppKit
import Foundation
import Testing
@testable import glance

@MainActor
struct PreviewWindowManagerTests {

    @Test func openPreviewCreatesIndependentControllers() async throws {
        let manager = PreviewWindowManager()
        let firstURL = try makeMarkdownFile(named: "first.md", contents: "# First")
        let secondURL = try makeMarkdownFile(named: "second.md", contents: "# Second")

        let firstController = manager.openPreview(for: firstURL)
        let secondController = manager.openPreview(for: secondURL)

        #expect(firstController !== secondController)
        #expect(manager.openWindowCount == 2)
        #expect(firstController.window?.title == "first.md")
        #expect(secondController.window?.title == "second.md")
        #expect(firstController.window?.tabGroup?.windows.count == 2)
        #expect(secondController.window?.tabGroup?.windows.count == 2)

        firstController.window?.close()
        secondController.window?.close()
        await waitUntil { manager.openWindowCount == 0 }
    }

    @Test func openSplitPreviewLoadsBothFiles() async throws {
        let manager = PreviewWindowManager()
        let firstURL = try makeMarkdownFile(named: "split-left.md", contents: "# Left")
        let secondURL = try makeMarkdownFile(named: "split-right.md", contents: "# Right")

        let controller = manager.openSplitPreview(leftURL: firstURL, rightURL: secondURL)

        #expect(manager.openWindowCount == 1)
        #expect(controller.loadedFileURLs == [firstURL, secondURL])
        #expect(controller.window != nil)

        controller.window?.close()
        await waitUntil { manager.openWindowCount == 0 }
    }

    @Test func closingOneWindowRemovesOnlyThatController() async throws {
        let manager = PreviewWindowManager()
        let firstURL = try makeMarkdownFile(named: "third.md", contents: "# Third")
        let secondURL = try makeMarkdownFile(named: "fourth.md", contents: "# Fourth")

        let firstController = manager.openPreview(for: firstURL)
        let secondController = manager.openPreview(for: secondURL)

        #expect(manager.openWindowCount == 2)

        firstController.window?.close()
        await waitUntil { manager.openWindowCount == 1 }

        #expect(manager.openWindowCount == 1)
        #expect(secondController.window != nil)

        secondController.window?.close()
        await waitUntil { manager.openWindowCount == 0 }
    }

    private func makeMarkdownFile(named name: String, contents: String) throws -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
            .appendingPathComponent(name)
        try FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try contents.write(to: url, atomically: true, encoding: .utf8)
        return url
    }

    @MainActor
    private func waitUntil(
        timeout: Duration = .seconds(2),
        _ predicate: @escaping @MainActor () -> Bool
    ) async {
        let deadline = ContinuousClock().now.advanced(by: timeout)

        while !predicate() && ContinuousClock().now < deadline {
            try? await Task.sleep(for: .milliseconds(20))
        }
    }
}
