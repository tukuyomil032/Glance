import Foundation

struct PreviewPreferences: Sendable {
    var fontSize: Int
    var maxWidth: Int

    nonisolated static let suiteName = "com.tukuyomi032.glance"

    nonisolated static func load() -> PreviewPreferences {
        let defaults = UserDefaults(suiteName: suiteName)
        let fontSize = defaults?.integer(forKey: "fontSize").nonZero ?? 16
        let maxWidth = defaults?.integer(forKey: "maxWidth").nonZero ?? 760
        return PreviewPreferences(fontSize: fontSize, maxWidth: maxWidth)
    }

    nonisolated func save() {
        let defaults = UserDefaults(suiteName: PreviewPreferences.suiteName)
        defaults?.set(fontSize, forKey: "fontSize")
        defaults?.set(maxWidth, forKey: "maxWidth")
    }
}

private extension Int {
    // UserDefaults returns 0 for missing keys; treat 0 as absent.
    nonisolated var nonZero: Int? { self == 0 ? nil : self }
}
