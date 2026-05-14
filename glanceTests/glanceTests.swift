//
//  glanceTests.swift
//  glanceTests
//
//  Created by yomi on 2026/05/09.
//

import Testing
import Foundation
import AppKit
@testable import glance

struct MarkdownRendererTests {

    @Test func headingRendering() {
        let html = MarkdownRenderer.render("# Title")
        #expect(html.contains("<h1>"))
        #expect(html.contains("Title"))
    }

    @Test func boldItalic() {
        let html = MarkdownRenderer.render("**bold** _italic_")
        #expect(html.contains("<strong>"))
        #expect(html.contains("<em>"))
    }

    @Test func codeBlock() {
        let html = MarkdownRenderer.render("```\ncode\n```")
        #expect(html.contains("<pre>") || html.contains("<code>"))
    }

    @Test func codeBlockPreservesLanguageClass() {
        let html = MarkdownRenderer.render("```swift\nprint(\"hi\")\n```")
        #expect(html.contains("language-swift"))
    }

    @Test func table() {
        let md = "| A | B |\n|---|---|\n| 1 | 2 |"
        let html = MarkdownRenderer.render(md)
        #expect(html.contains("<table>"))
    }

    @Test func emptyInput() {
        let html = MarkdownRenderer.render("")
        #expect(html.isEmpty || html.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
    }

    @Test func utf8Japanese() {
        let html = MarkdownRenderer.render("## 日本語テスト 🎉")
        #expect(html.contains("日本語テスト"))
    }
}

struct HTMLTemplateTests {

    @Test func htmlStructure() {
        let html = HTMLTemplate.render(body: "<p>test</p>")
        #expect(html.contains("<!DOCTYPE html>"))
        #expect(html.contains("<style>"))
        #expect(html.contains("<p>test</p>"))
    }

    @Test func fontSizeInjection() {
        let html = HTMLTemplate.render(body: "", fontSize: 18, maxWidth: 800)
        #expect(html.contains("18px") || html.contains("font-size"))
    }

    @Test func contentBaseURLInjection() {
        let html = HTMLTemplate.render(
            body: "<p>test</p>",
            contentBaseURL: URL(fileURLWithPath: "/tmp/example")
        )
        #expect(html.contains("<base href=\"file:///tmp/example\">"))
    }

    @Test func includesHighlightAssetsWhenBundled() {
        let html = HTMLTemplate.render(body: "<pre><code class=\"language-swift\">print(\"hi\")</code></pre>")
        #expect(html.contains("highlight.min.js"))
        #expect(html.contains("github-dark-dimmed.min.css"))
    }

    @Test func liquidGlassModeUsesGlassShell() {
        let html = HTMLTemplate.render(body: "<p>glass</p>", appearanceMode: .liquidGlass)
        #expect(html.contains("backdrop-filter"))
        #expect(html.contains("border-radius: 28px"))
        #expect(html.contains("glass"))
    }

}

struct AppMetadataTests {

    @Test func readsSparkleMetadataFromBundle() throws {
        let bundle = try makeBundle(infoDictionary: [
            "SUFeedURL": "https://example.com/appcast.xml",
            "SUPublicEDKey": "test-public-key",
            "LSUIElement": true,
        ])

        #expect(AppMetadata.sparkleFeedURL(bundle: bundle)?.absoluteString == "https://example.com/appcast.xml")
        #expect(AppMetadata.sparklePublicEDKey(bundle: bundle) == "test-public-key")
        #expect(AppMetadata.isMenuBarAgent(bundle: bundle))
    }

    @Test func trimsEmptyBundleMetadata() throws {
        let bundle = try makeBundle(infoDictionary: [
            "SUFeedURL": "   ",
            "SUPublicEDKey": "",
            "LSUIElement": "0",
        ])

        #expect(AppMetadata.sparkleFeedURL(bundle: bundle) == nil)
        #expect(AppMetadata.sparklePublicEDKey(bundle: bundle) == nil)
        #expect(!AppMetadata.isMenuBarAgent(bundle: bundle))
    }

    @Test func detectsUITestModeFromEnvironment() {
        #expect(AppMetadata.isUITestMode(environment: ["GLANCE_UI_TEST_MODE": "1"]))
        #expect(AppMetadata.isUITestMode(environment: ["GLANCE_UI_TEST_MODE": "true"]))
        #expect(AppMetadata.isUITestMode(environment: ["GLANCE_UI_TEST_MODE": " yes "]))
    }

    @Test func uiTestModeDefaultsToDisabled() {
        #expect(!AppMetadata.isUITestMode(environment: [:]))
        #expect(!AppMetadata.isUITestMode(environment: ["GLANCE_UI_TEST_MODE": "0"]))
        #expect(!AppMetadata.isUITestMode(environment: ["GLANCE_UI_TEST_MODE": ""]))
    }

    @Test func readsUITestPreviewPathsFromEnvironment() {
        let singlePath = "/tmp/glance-single.md"
        let leftPath = "/tmp/glance-left.md"
        let rightPath = "/tmp/glance-right.md"

        #expect(AppMetadata.uiTestPreviewURL(environment: [
            "GLANCE_UI_TEST_PREVIEW_PATH": " \(singlePath) ",
        ]) == URL(fileURLWithPath: singlePath))
        #expect(AppMetadata.uiTestSplitPreviewURLs(environment: [
            "GLANCE_UI_TEST_SPLIT_PREVIEW_LEFT_PATH": leftPath,
            "GLANCE_UI_TEST_SPLIT_PREVIEW_RIGHT_PATH": rightPath,
        ]) == [URL(fileURLWithPath: leftPath), URL(fileURLWithPath: rightPath)])
        #expect(AppMetadata.uiTestPreviewURL(environment: [
            "GLANCE_UI_TEST_PREVIEW_PATH": " ",
        ]) == nil)
        #expect(AppMetadata.uiTestSplitPreviewURLs(environment: [
            "GLANCE_UI_TEST_SPLIT_PREVIEW_LEFT_PATH": leftPath,
        ]) == nil)
    }

    private func makeBundle(infoDictionary: [String: Any]) throws -> Bundle {
        let rootURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let bundleURL = rootURL.appendingPathComponent("TestBundle.bundle", isDirectory: true)
        try FileManager.default.createDirectory(at: bundleURL, withIntermediateDirectories: true)

        let infoPlistURL = bundleURL.appendingPathComponent("Info.plist")
        let plistData = try PropertyListSerialization.data(
            fromPropertyList: infoDictionary,
            format: .xml,
            options: 0
        )
        try plistData.write(to: infoPlistURL)

        guard let bundle = Bundle(url: bundleURL) else {
            Issue.record("Failed to construct bundle at \(bundleURL.path())")
            throw CocoaError(.fileReadCorruptFile)
        }

        return bundle
    }
}

@MainActor
struct AppDelegatePreviewActivationTests {

    @Test func openPreviewPromotesMenuBarAgentBeforeOpeningWindow() async {
        var appliedPolicies: [NSApplication.ActivationPolicy] = []
        var activationCount = 0
        var openedURL: URL?
        let url = URL(fileURLWithPath: "/tmp/preview.md")

        let delegate = AppDelegate(
            previewActivationController: PreviewWindowActivationController(
                isMenuBarAgent: { true },
                setActivationPolicy: { appliedPolicies.append($0) },
                activate: { activationCount += 1 }
            ),
            previewOpener: { openedURL = $0 },
            splitPreviewOpener: { _, _ in
                Issue.record("Unexpected split preview open")
            }
        )

        delegate.openPreview(for: url)
        await Task.yield()
        RunLoop.main.run(until: Date().addingTimeInterval(0.05))

        #expect(appliedPolicies == [.regular])
        #expect(activationCount == 1)
        #expect(openedURL == url)
    }

    @Test func openSplitPreviewPromotesMenuBarAgentBeforeOpeningWindow() async {
        var appliedPolicies: [NSApplication.ActivationPolicy] = []
        var activationCount = 0
        var openedURLs: [URL] = []
        let leftURL = URL(fileURLWithPath: "/tmp/left.md")
        let rightURL = URL(fileURLWithPath: "/tmp/right.md")

        let delegate = AppDelegate(
            previewActivationController: PreviewWindowActivationController(
                isMenuBarAgent: { true },
                setActivationPolicy: { appliedPolicies.append($0) },
                activate: { activationCount += 1 }
            ),
            previewOpener: { _ in
                Issue.record("Unexpected single preview open")
            },
            splitPreviewOpener: { left, right in
                openedURLs = [left, right]
            }
        )

        delegate.openSplitPreview(leftURL: leftURL, rightURL: rightURL)
        await Task.yield()
        RunLoop.main.run(until: Date().addingTimeInterval(0.05))

        #expect(appliedPolicies == [.regular])
        #expect(activationCount == 1)
        #expect(openedURLs == [leftURL, rightURL])
    }

    @Test func openPreviewSkipsPolicyPromotionForRegularApps() {
        var appliedPolicies: [NSApplication.ActivationPolicy] = []
        var activationCount = 0
        var openedURL: URL?
        let url = URL(fileURLWithPath: "/tmp/regular.md")

        let delegate = AppDelegate(
            previewActivationController: PreviewWindowActivationController(
                isMenuBarAgent: { false },
                setActivationPolicy: { appliedPolicies.append($0) },
                activate: { activationCount += 1 }
            ),
            previewOpener: { openedURL = $0 },
            splitPreviewOpener: { _, _ in
                Issue.record("Unexpected split preview open")
            }
        )

        delegate.openPreview(for: url)

        #expect(appliedPolicies.isEmpty)
        #expect(activationCount == 0)
        #expect(openedURL == url)
    }

    @Test func resignActiveReturnsAccessoryOnlyWhenNoPreviewControllersRemain() {
        var appliedPolicies: [NSApplication.ActivationPolicy] = []
        let controller = PreviewWindowActivationController(
            isMenuBarAgent: { true },
            setActivationPolicy: { appliedPolicies.append($0) },
            activate: { }
        )

        controller.restoreAccessoryPolicyAfterResign(
            hasVisibleWindows: false,
            hasOpenPreviewWindows: true
        )
        controller.restoreAccessoryPolicyAfterResign(
            hasVisibleWindows: true,
            hasOpenPreviewWindows: false
        )
        controller.restoreAccessoryPolicyAfterResign(
            hasVisibleWindows: false,
            hasOpenPreviewWindows: false,
            isPendingPresentation: true
        )

        #expect(appliedPolicies.isEmpty)

        controller.restoreAccessoryPolicyAfterResign(
            hasVisibleWindows: false,
            hasOpenPreviewWindows: false,
            isPendingPresentation: false
        )

        #expect(appliedPolicies == [.accessory])
    }
}

struct PreviewPreferencesTests {

    @Test func defaultValues() {
        let prefs = PreviewPreferences(fontSize: 16, maxWidth: 760, language: "system", appearanceMode: .standard)
        #expect(prefs.fontSize == 16)
        #expect(prefs.maxWidth == 760)
        #expect(prefs.language == "system")
        #expect(prefs.appearanceMode == .standard)
    }

    @Test func appearanceModeRoundTripsThroughDefaults() {
        let suiteName = "com.tukuyomi032.glance.tests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)
        defaults?.removePersistentDomain(forName: suiteName)
        defer { defaults?.removePersistentDomain(forName: suiteName) }

        var prefs = PreviewPreferences.load(userDefaults: defaults)
        #expect(prefs.appearanceMode == .standard)

        prefs.appearanceMode = .liquidGlass
        prefs.save(userDefaults: defaults)

        let reloaded = PreviewPreferences.load(userDefaults: defaults)
        #expect(reloaded.appearanceMode == .liquidGlass)
    }

    @Test func savePostsPreferenceChangeNotification() {
        let suiteName = "com.tukuyomi032.glance.tests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)
        defaults?.removePersistentDomain(forName: suiteName)
        defer { defaults?.removePersistentDomain(forName: suiteName) }

        var didNotify = false
        let token = NotificationCenter.default.addObserver(
            forName: .previewPreferencesDidChange,
            object: nil,
            queue: nil
        ) { _ in
            didNotify = true
        }
        defer { NotificationCenter.default.removeObserver(token) }

        let prefs = PreviewPreferences(fontSize: 17, maxWidth: 780, language: "en", appearanceMode: .liquidGlass)
        prefs.save(userDefaults: defaults)

        #expect(didNotify)
    }
}
