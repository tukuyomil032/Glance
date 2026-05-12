import Foundation

enum AppMetadata {
    static let sparkleFeedURLKey = "SUFeedURL"
    static let sparklePublicEDKeyKey = "SUPublicEDKey"
    static let menuBarAgentKey = "LSUIElement"
    static let uiTestModeEnvironmentKey = "GLANCE_UI_TEST_MODE"

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
}
