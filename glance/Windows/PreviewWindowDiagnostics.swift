import AppKit

#if DEBUG
@MainActor
enum PreviewWindowDiagnostics {
    private static let environmentKey = "GLANCE_PREVIEW_WINDOW_DEBUG"

    static func dump(event: String, window: NSWindow?) {
        guard isEnabled else {
            return
        }

        let keyWindowTitle = NSApp.keyWindow?.title ?? "nil"
        let mainWindowTitle = NSApp.mainWindow?.title ?? "nil"
        let windowTitle = window?.title ?? "nil"
        let frame = window.map { NSStringFromRect($0.frame) } ?? "nil"
        let screen = window?.screen?.localizedName ?? "nil"
        let visibleFrame = window?.screen.map { NSStringFromRect($0.visibleFrame) } ?? "nil"
        let tabCount = window?.tabGroup?.windows.count ?? 0
        let isSelectedTab = window.map { candidate in
            candidate.tabGroup?.selectedWindow === candidate
        } ?? false
        let occlusionState = window?.occlusionState.rawValue ?? 0

        NSLog(
            "[glance preview] event=\(event) activationPolicy=\(NSApp.activationPolicy()) "
                + "appActive=\(NSApp.isActive) keyWindow=\(keyWindowTitle) mainWindow=\(mainWindowTitle) "
                + "windowTitle=\(windowTitle) visible=\(window?.isVisible ?? false) "
                + "miniaturized=\(window?.isMiniaturized ?? false) alpha=\(window?.alphaValue ?? -1) "
                + "frame=\(frame) screen=\(screen) visibleFrame=\(visibleFrame) "
                + "occlusion=\(occlusionState) tabCount=\(tabCount) selectedTab=\(isSelectedTab)"
        )
    }

    private static var isEnabled: Bool {
        let rawValue = ProcessInfo.processInfo.environment[environmentKey] ?? ""
        let value = rawValue.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return value == "1" || value == "true" || value == "yes"
    }
}
#endif
