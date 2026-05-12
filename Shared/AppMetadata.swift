import Foundation

enum AppMetadata {
    static let sparkleFeedURLKey = "SUFeedURL"
    static let sparklePublicEDKeyKey = "SUPublicEDKey"
    static let menuBarAgentKey = "LSUIElement"

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
}
