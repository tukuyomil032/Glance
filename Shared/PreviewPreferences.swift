import Foundation

extension Notification.Name {
    nonisolated static let previewPreferencesDidChange = Notification.Name("PreviewPreferencesDidChange")
}

struct PreviewPreferences: Sendable {
    var fontSize: Int
    var maxWidth: Int
    var language: String

    nonisolated static let suiteName = "com.tukuyomi032.glance"

    nonisolated static func load(userDefaults defaults: UserDefaults? = nil) -> PreviewPreferences {
        let defaults = defaults ?? UserDefaults(suiteName: suiteName)
        let fontSize = defaults?.integer(forKey: "fontSize").nonZero ?? 16
        let maxWidth = defaults?.integer(forKey: "maxWidth").nonZero ?? 760
        let language = defaults?.string(forKey: "appLanguage") ?? "system"
        return PreviewPreferences(
            fontSize: fontSize,
            maxWidth: maxWidth,
            language: language
        )
    }

    nonisolated func save(userDefaults defaults: UserDefaults? = nil) {
        let defaults = defaults ?? UserDefaults(suiteName: PreviewPreferences.suiteName)
        defaults?.set(fontSize, forKey: "fontSize")
        defaults?.set(maxWidth, forKey: "maxWidth")
        defaults?.set(language, forKey: "appLanguage")
        NotificationCenter.default.post(name: .previewPreferencesDidChange, object: nil)
    }
}

private extension Int {
    nonisolated var nonZero: Int? { self == 0 ? nil : self }
}
