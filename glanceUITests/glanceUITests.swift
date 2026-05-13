//
//  glanceUITests.swift
//  glanceUITests
//
//  Created by yomi on 2026/05/09.
//

import XCTest
import CoreGraphics
import AppKit

final class glanceUITests: XCTestCase {
    private let appBundleIdentifier = "com.tukuyomi032.glance"

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    @MainActor
    func testUITestModeShowsHostWindowByDefault() throws {
        let app = XCUIApplication()
        app.launchEnvironment["GLANCE_UI_TEST_MODE"] = "1"
        app.launch()
        addTeardownBlock { app.terminate() }

        XCTAssertTrue(app.staticTexts["glance UI Test Host"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testUITestModeCanOpenVisiblePreviewWindow() throws {
        let fixtureURL = try makeMarkdownFixture(named: "ui-preview.md", contents: "# UI Preview")
        let app = XCUIApplication()
        app.launchEnvironment["GLANCE_UI_TEST_MODE"] = "1"
        app.launchEnvironment["GLANCE_UI_TEST_PREVIEW_PATH"] = fixtureURL.path
        app.launch()
        addTeardownBlock { app.terminate() }

        let previewWindow = app.windows["ui-preview.md"]
        XCTAssertTrue(previewWindow.waitForExistence(timeout: 5))

        let ownerPIDs = runningApplicationPIDs(bundleIdentifier: appBundleIdentifier)
        let matchingWindow = try waitForPresentedCGWindow(
            named: "ui-preview.md",
            matching: previewWindow.frame,
            ownerPIDs: ownerPIDs
        )
        assertPresentedCGWindow(matchingWindow)
    }

    @MainActor
    func testUITestModeCanOpenVisibleSplitPreviewWindow() throws {
        let leftURL = try makeMarkdownFixture(named: "ui-left.md", contents: "# Left")
        let rightURL = try makeMarkdownFixture(named: "ui-right.md", contents: "# Right")
        let expectedTitle = "ui-left.md + ui-right.md"
        let app = XCUIApplication()
        app.launchEnvironment["GLANCE_UI_TEST_MODE"] = "1"
        app.launchEnvironment["GLANCE_UI_TEST_SPLIT_PREVIEW_LEFT_PATH"] = leftURL.path
        app.launchEnvironment["GLANCE_UI_TEST_SPLIT_PREVIEW_RIGHT_PATH"] = rightURL.path
        app.launch()
        addTeardownBlock { app.terminate() }

        let previewWindow = app.windows[expectedTitle]
        XCTAssertTrue(previewWindow.waitForExistence(timeout: 5))

        let ownerPIDs = runningApplicationPIDs(bundleIdentifier: appBundleIdentifier)
        let matchingWindow = try waitForPresentedCGWindow(
            named: expectedTitle,
            matching: previewWindow.frame,
            ownerPIDs: ownerPIDs
        )
        assertPresentedCGWindow(matchingWindow)
    }

    private func makeMarkdownFixture(named name: String, contents: String) throws -> URL {
        let rootURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: rootURL, withIntermediateDirectories: true)
        let url = rootURL.appendingPathComponent(name)
        try contents.write(to: url, atomically: true, encoding: .utf8)
        return url
    }

    private func waitForPresentedCGWindow(
        named name: String,
        matching axFrame: CGRect,
        ownerPIDs: Set<pid_t>,
        timeout: TimeInterval = 5
    ) throws -> [String: Any] {
        let deadline = Date().addingTimeInterval(timeout)
        var lastCandidateDescription = "[]"

        repeat {
            let candidates = cgWindowInfo(named: name, matching: axFrame, ownerPIDs: ownerPIDs)
            lastCandidateDescription = describeCGWindows(candidates)
            if let window = candidates.first(where: isPresentedCGWindow) {
                return window
            }
            RunLoop.current.run(until: Date().addingTimeInterval(0.1))
        } while Date() < deadline

        XCTFail("Timed out waiting for presented CGWindow named \(name). Last candidates: \(lastCandidateDescription)")
        throw CGWindowLookupError.timedOut
    }

    private func cgWindowInfo(
        named name: String,
        matching axFrame: CGRect,
        ownerPIDs: Set<pid_t>
    ) -> [[String: Any]] {
        let options: CGWindowListOption = [.optionOnScreenOnly, .excludeDesktopElements]
        guard let rawWindows = CGWindowListCopyWindowInfo(options, kCGNullWindowID) as? [[String: Any]] else {
            return []
        }
        let ownedWindows = rawWindows.filter {
            isTargetWindow($0, ownerPIDs: ownerPIDs)
                && ($0[kCGWindowLayer as String] as? NSNumber)?.intValue == 0
        }
        let exactTitleWindows = ownedWindows.filter {
            $0[kCGWindowName as String] as? String == name
        }

        if !exactTitleWindows.isEmpty {
            return exactTitleWindows
        }

        return ownedWindows.filter {
            let windowName = ($0[kCGWindowName as String] as? String) ?? ""
            return windowName.isEmpty && frame(of: $0).matches(axFrame, tolerance: 3)
        }
    }

    private func frame(of window: [String: Any]) -> CGRect? {
        guard let bounds = window[kCGWindowBounds as String] as? [String: Any] else {
            return nil
        }

        return CGRect(dictionaryRepresentation: bounds as CFDictionary)
    }

    private func isPresentedCGWindow(_ window: [String: Any]) -> Bool {
        (window[kCGWindowIsOnscreen as String] as? Bool) == true
            && (window[kCGWindowAlpha as String] as? NSNumber)?.doubleValue == 1
    }

    private func assertPresentedCGWindow(_ window: [String: Any]) {
        XCTAssertEqual(window[kCGWindowIsOnscreen as String] as? Bool, true)
        XCTAssertEqual((window[kCGWindowAlpha as String] as? NSNumber)?.doubleValue, 1)

        let bounds = window[kCGWindowBounds as String] as? [String: Any]
        XCTAssertNotNil(bounds)
        guard let bounds,
              let rect = CGRect(dictionaryRepresentation: bounds as CFDictionary) else {
            return
        }
        XCTAssertGreaterThan(rect.width, 0)
        XCTAssertGreaterThan(rect.height, 0)
    }

    private func isTargetWindow(_ window: [String: Any], ownerPIDs: Set<pid_t>) -> Bool {
        if let ownerPID = (window[kCGWindowOwnerPID as String] as? NSNumber)?.int32Value,
           ownerPIDs.contains(ownerPID) {
            return true
        }

        return window[kCGWindowOwnerName as String] as? String == "glance"
    }

    private func runningApplicationPIDs(bundleIdentifier: String) -> Set<pid_t> {
        Set(NSRunningApplication
            .runningApplications(withBundleIdentifier: bundleIdentifier)
            .filter { !$0.isTerminated }
            .map(\.processIdentifier))
    }

    private func describeCGWindows(_ windows: [[String: Any]]) -> String {
        windows.map { window in
            let name = (window[kCGWindowName as String] as? String) ?? ""
            let alpha = (window[kCGWindowAlpha as String] as? NSNumber)?.doubleValue ?? -1
            let onscreen = window[kCGWindowIsOnscreen as String] as? Bool ?? false
            let frame = frame(of: window).map { NSStringFromRect(NSRectFromCGRect($0)) } ?? "nil"
            return "{name: \(name), alpha: \(alpha), onscreen: \(onscreen), frame: \(frame)}"
        }.joined(separator: ", ")
    }

    private enum CGWindowLookupError: Error {
        case timedOut
    }
}

private extension Optional where Wrapped == CGRect {
    func matches(_ rect: CGRect, tolerance: CGFloat) -> Bool {
        guard let candidate = self else {
            return false
        }

        return abs(candidate.minX - rect.minX) <= tolerance
            && abs(candidate.minY - rect.minY) <= tolerance
            && abs(candidate.width - rect.width) <= tolerance
            && abs(candidate.height - rect.height) <= tolerance
    }
}
