import Foundation

struct PreviewPreferences: Sendable {
    var fontSize: Int
    var maxWidth: Int
    var language: String

    nonisolated static let suiteName = "com.tukuyomi032.glance"

    nonisolated static func load() -> PreviewPreferences {
        let defaults = UserDefaults(suiteName: suiteName)
        let fontSize = defaults?.integer(forKey: "fontSize").nonZero ?? 16
        let maxWidth = defaults?.integer(forKey: "maxWidth").nonZero ?? 760
        let language = defaults?.string(forKey: "appLanguage") ?? "system"
        return PreviewPreferences(fontSize: fontSize, maxWidth: maxWidth, language: language)
    }

    nonisolated func save() {
        let defaults = UserDefaults(suiteName: PreviewPreferences.suiteName)
        defaults?.set(fontSize, forKey: "fontSize")
        defaults?.set(maxWidth, forKey: "maxWidth")
        defaults?.set(language, forKey: "appLanguage")
    }
}

private extension Int {
    nonisolated var nonZero: Int? { self == 0 ? nil : self }
}
