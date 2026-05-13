import Foundation

enum AppMetadata {
    static let sparkleFeedURLKey = "SUFeedURL"
    static let sparklePublicEDKeyKey = "SUPublicEDKey"
    static let menuBarAgentKey = "LSUIElement"
    static let uiTestModeEnvironmentKey = "GLANCE_UI_TEST_MODE"
    static let uiTestPreviewPathEnvironmentKey = "GLANCE_UI_TEST_PREVIEW_PATH"
    static let uiTestSplitPreviewLeftPathEnvironmentKey = "GLANCE_UI_TEST_SPLIT_PREVIEW_LEFT_PATH"
    static let uiTestSplitPreviewRightPathEnvironmentKey = "GLANCE_UI_TEST_SPLIT_PREVIEW_RIGHT_PATH"

    static func sparkleFeedURL(bundle: Bundle = .main) -> URL? {
        guard let value = bundle.object(forInfoDictionaryKey: sparkleFeedURLKey) as? String else {
            return nil
        }

        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return nil
        }

        return URL(string: trimmed)
    }

    static func sparklePublicEDKey(bundle: Bundle = .main) -> String? {
        guard let value = bundle.object(forInfoDictionaryKey: sparklePublicEDKeyKey) as? String else {
            return nil
        }

        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    static func isMenuBarAgent(bundle: Bundle = .main) -> Bool {
        switch bundle.object(forInfoDictionaryKey: menuBarAgentKey) {
        case let value as Bool:
            value
        case let value as String:
            NSString(string: value).boolValue
        case let value as NSNumber:
            value.boolValue
        default:
            false
        }
    }

    static func isUITestMode(processInfo: ProcessInfo = .processInfo) -> Bool {
        isUITestMode(environment: processInfo.environment)
    }

    static func isUITestMode(environment: [String: String]) -> Bool {
        guard let rawValue = environment[uiTestModeEnvironmentKey] else {
            return false
        }

        let value = rawValue.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return value == "1" || value == "true" || value == "yes"
    }

    static func uiTestPreviewURL(environment: [String: String] = ProcessInfo.processInfo.environment) -> URL? {
        fileURL(forEnvironmentKey: uiTestPreviewPathEnvironmentKey, environment: environment)
    }

    static func uiTestSplitPreviewURLs(environment: [String: String] = ProcessInfo.processInfo.environment) -> [URL]? {
        guard let leftURL = fileURL(
            forEnvironmentKey: uiTestSplitPreviewLeftPathEnvironmentKey,
            environment: environment
        ),
              let rightURL = fileURL(
                forEnvironmentKey: uiTestSplitPreviewRightPathEnvironmentKey,
                environment: environment
              ) else {
            return nil
        }

        return [leftURL, rightURL]
    }

    private static func fileURL(forEnvironmentKey key: String, environment: [String: String]) -> URL? {
        guard let rawValue = environment[key] else {
            return nil
        }

        let value = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty else {
            return nil
        }

        return URL(fileURLWithPath: value)
    }
}
