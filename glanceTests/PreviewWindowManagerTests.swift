import AppKit
import Foundation
import Testing
@testable import glance

@MainActor
struct PreviewWindowManagerTests {

    @Test func openPreviewCreatesIndependentControllers() throws {
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
    }

    @Test func closingOneWindowRemovesOnlyThatController() async throws {
        let manager = PreviewWindowManager()
        let firstURL = try makeMarkdownFile(named: "third.md", contents: "# Third")
        let secondURL = try makeMarkdownFile(named: "fourth.md", contents: "# Fourth")

        let firstController = manager.openPreview(for: firstURL)
        let secondController = manager.openPreview(for: secondURL)

        #expect(manager.openWindowCount == 2)

        firstController.window?.close()
        await Task.yield()

        #expect(manager.openWindowCount == 1)
        #expect(secondController.window != nil)

        secondController.window?.close()
        await Task.yield()
        #expect(manager.openWindowCount == 0)
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
}
