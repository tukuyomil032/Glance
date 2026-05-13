import AppKit
import Foundation
import Testing
@testable import glance

@MainActor
@Suite(.serialized)
struct PreviewWindowManagerTests {

    @Test func openPreviewCreatesIndependentControllers() async throws {
        let manager = makeManager()
        let firstURL = try makeMarkdownFile(named: "first.md", contents: "# First")
        let secondURL = try makeMarkdownFile(named: "second.md", contents: "# Second")

        let firstController = manager.openPreview(for: firstURL)
        let secondController = manager.openPreview(for: secondURL)

        #expect(firstController !== secondController)
        #expect(manager.openWindowCount == 2)
        #expect(firstController.window?.title == "first.md")
        #expect(secondController.window?.title == "second.md")
        #expect(firstController.window?.isVisible == true)
        #expect(secondController.window?.isVisible == true)
        #expect(firstController.window?.alphaValue == 1)
        #expect(secondController.window?.alphaValue == 1)
        assertPresented(firstController.window)
        assertPresented(secondController.window)
        #expect(firstController.window?.tabGroup?.windows.count == 2)
        #expect(secondController.window?.tabGroup?.windows.count == 2)
        #expect(secondController.window?.tabGroup?.selectedWindow === secondController.window)

        firstController.window?.close()
        secondController.window?.close()
        await waitUntil { manager.openWindowCount == 0 }
    }

    @Test func previewWindowsUseRegularNSWindowInsteadOfPanel() throws {
        let manager = makeManager()
        let singleURL = try makeMarkdownFile(named: "regular-window.md", contents: "# Single")
        let leftURL = try makeMarkdownFile(named: "regular-left.md", contents: "# Left")
        let rightURL = try makeMarkdownFile(named: "regular-right.md", contents: "# Right")

        let singleController = manager.openPreview(for: singleURL)
        let splitController = manager.openSplitPreview(leftURL: leftURL, rightURL: rightURL)

        #expect(!(singleController.window is NSPanel))
        #expect(!(splitController.window is NSPanel))
        #expect(type(of: try #require(singleController.window)) == NSWindow.self)
        #expect(type(of: try #require(splitController.window)) == NSWindow.self)

        singleController.window?.close()
        splitController.window?.close()
    }

    @Test func openPreviewEagerlyLoadsPaneViewBeforeMarkdownLoad() throws {
        let manager = makeManager()
        let url = try makeMarkdownFile(named: "eager-single.md", contents: "# Single")

        let controller = manager.openPreview(for: url)

        #expect(controller.isPreviewPaneViewLoaded)
        #expect(!controller.hasPendingPreviewLoad)

        controller.window?.close()
    }

    @Test func openSplitPreviewLoadsBothFiles() async throws {
        let manager = makeManager()
        let firstURL = try makeMarkdownFile(named: "split-left.md", contents: "# Left")
        let secondURL = try makeMarkdownFile(named: "split-right.md", contents: "# Right")

        let controller = manager.openSplitPreview(leftURL: firstURL, rightURL: secondURL)

        #expect(manager.openWindowCount == 1)
        #expect(controller.loadedFileURLs == [firstURL, secondURL])
        #expect(controller.window != nil)
        #expect(controller.window?.title == "split-left.md + split-right.md")
        #expect(controller.window?.isVisible == true)
        #expect(controller.window?.alphaValue == 1)
        assertPresented(controller.window)

        controller.window?.close()
        await waitUntil { manager.openWindowCount == 0 }
    }

    @Test func openSplitPreviewEagerlyLoadsBothPaneViewsBeforeMarkdownLoad() throws {
        let manager = makeManager()
        let firstURL = try makeMarkdownFile(named: "eager-left.md", contents: "# Left")
        let secondURL = try makeMarkdownFile(named: "eager-right.md", contents: "# Right")

        let controller = manager.openSplitPreview(leftURL: firstURL, rightURL: secondURL)

        #expect(controller.arePreviewPaneViewsLoaded == [true, true])
        #expect(controller.hasPendingPreviewLoads == [false, false])

        controller.window?.close()
    }

    @Test func closingOneWindowRemovesOnlyThatController() async throws {
        let manager = makeManager()
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

    @Test func secondPreviewDoesNotTabIntoBarelyVisibleHost() throws {
        let manager = makeManager()
        let firstURL = try makeMarkdownFile(named: "barely-visible-host.md", contents: "# Offscreen")
        let secondURL = try makeMarkdownFile(named: "onscreen-new.md", contents: "# Onscreen")

        let firstController = manager.openPreview(for: firstURL)
        moveMostlyOffscreen(firstController.window)
        #expect(firstController.window?.isVisible == true)
        #expect(firstController.window?.screen != nil)

        let secondController = manager.openPreview(for: secondURL)

        #expect((firstController.window?.tabGroup?.windows.count ?? 1) == 1)
        #expect((secondController.window?.tabGroup?.windows.count ?? 1) == 1)
        assertPresented(secondController.window)

        firstController.window?.close()
        secondController.window?.close()
    }

    private func assertPresented(_ window: NSWindow?) {
        guard let window else {
            Issue.record("Expected window")
            return
        }

        #expect(window.isVisible)
        #expect(!window.isMiniaturized)
        #expect(window.alphaValue == 1)
        #expect(window.screen != nil)
        if let screen = window.screen {
            #expect(screen.visibleFrame.contains(window.frame, tolerance: 0.5))
        }
    }

    private func makeManager() -> PreviewWindowManager {
        closePreviewWindowsForTest()
        return PreviewWindowManager()
    }

    private func closePreviewWindowsForTest() {
        let previewWindows = NSApp.windows
            .flatMap { window in [window] + (window.tabGroup?.windows ?? []) }
            .reduce(into: [ObjectIdentifier: NSWindow]()) { windowsByID, window in
                windowsByID[ObjectIdentifier(window)] = window
            }
            .values

        for window in previewWindows where window.tabbingIdentifier == "MarkdownPreview" {
            window.delegate = nil
            window.orderOut(nil)
            window.close()
        }
        RunLoop.main.run(until: Date().addingTimeInterval(0.05))
    }

    private func moveMostlyOffscreen(_ window: NSWindow?) {
        guard let window else {
            Issue.record("Expected window")
            return
        }

        guard let screen = window.screen ?? NSScreen.main else {
            Issue.record("Expected screen")
            return
        }

        let visibleFrame = screen.visibleFrame
        let width = min(max(window.frame.width, 320), visibleFrame.width / 2)
        let height = min(max(window.frame.height, 240), visibleFrame.height / 2)
        window.setFrame(
            NSRect(
                x: visibleFrame.midX - width / 2,
                y: visibleFrame.midY - height / 2,
                width: width,
                height: height
            ),
            display: true
        )

        let visibleStripWidth = min(width / 4, 32)
        let origin = NSPoint(
            x: visibleFrame.maxX - visibleStripWidth,
            y: clamp(
                window.frame.minY,
                min: visibleFrame.minY,
                max: visibleFrame.maxY - window.frame.height
            )
        )
        window.setFrame(
            NSRect(origin: origin, size: window.frame.size),
            display: false
        )
        #expect(window.frame.intersects(visibleFrame))
        #expect(!visibleFrame.contains(window.frame, tolerance: 0.5))
    }

    private func clamp(_ value: CGFloat, min minValue: CGFloat, max maxValue: CGFloat) -> CGFloat {
        if maxValue < minValue {
            return minValue
        }

        return min(max(value, minValue), maxValue)
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

private extension NSRect {
    func contains(_ rect: NSRect, tolerance: CGFloat) -> Bool {
        minX <= rect.minX + tolerance
            && minY <= rect.minY + tolerance
            && maxX >= rect.maxX - tolerance
            && maxY >= rect.maxY - tolerance
    }
}
