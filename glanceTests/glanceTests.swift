//
//  glanceTests.swift
//  glanceTests
//
//  Created by yomi on 2026/05/09.
//

import Testing
import Foundation
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

struct PreviewPreferencesTests {

    @Test func defaultValues() {
        let prefs = PreviewPreferences(fontSize: 16, maxWidth: 760, language: "system")
        #expect(prefs.fontSize == 16)
        #expect(prefs.maxWidth == 760)
        #expect(prefs.language == "system")
    }
}
