import AppKit

@MainActor
enum PreviewWindowAppearance {
    static func apply(to window: NSWindow?, mode: PreviewAppearanceMode) {
        guard let window else { return }

        switch mode {
        case .standard:
            window.isOpaque = true
            window.backgroundColor = .windowBackgroundColor
            window.titlebarAppearsTransparent = false
            window.isMovableByWindowBackground = false
        case .liquidGlass:
            window.isOpaque = false
            window.backgroundColor = .clear
            window.titlebarAppearsTransparent = true
            window.isMovableByWindowBackground = true
        }
    }
}
