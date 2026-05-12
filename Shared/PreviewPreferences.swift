import Foundation

enum PreviewAppearanceMode: String, Sendable, CaseIterable {
    case standard
    case liquidGlass

    var displayName: String {
        switch self {
        case .standard: return "Standard"
        case .liquidGlass: return "Liquid Glass"
        }
    }
}

extension Notification.Name {
    nonisolated static let previewPreferencesDidChange = Notification.Name("PreviewPreferencesDidChange")
}

struct PreviewPreferences: Sendable {
    var fontSize: Int
    var maxWidth: Int
    var language: String
    var appearanceMode: PreviewAppearanceMode

    nonisolated static let suiteName = "com.tukuyomi032.glance"

    nonisolated static func load(userDefaults defaults: UserDefaults? = nil) -> PreviewPreferences {
        let defaults = defaults ?? UserDefaults(suiteName: suiteName)
        let fontSize = defaults?.integer(forKey: "fontSize").nonZero ?? 16
        let maxWidth = defaults?.integer(forKey: "maxWidth").nonZero ?? 760
        let language = defaults?.string(forKey: "appLanguage") ?? "system"
        let appearanceMode = PreviewAppearanceMode(
            rawValue: defaults?.string(forKey: "previewAppearanceMode") ?? ""
        ) ?? .standard
        return PreviewPreferences(
            fontSize: fontSize,
            maxWidth: maxWidth,
            language: language,
            appearanceMode: appearanceMode
        )
    }

    nonisolated func save(userDefaults defaults: UserDefaults? = nil) {
        let defaults = defaults ?? UserDefaults(suiteName: PreviewPreferences.suiteName)
        defaults?.set(fontSize, forKey: "fontSize")
        defaults?.set(maxWidth, forKey: "maxWidth")
        defaults?.set(language, forKey: "appLanguage")
        defaults?.set(appearanceMode.rawValue, forKey: "previewAppearanceMode")
        NotificationCenter.default.post(name: .previewPreferencesDidChange, object: nil)
    }
}

private extension Int {
    nonisolated var nonZero: Int? { self == 0 ? nil : self }
}
