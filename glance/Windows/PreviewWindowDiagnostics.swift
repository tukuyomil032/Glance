import AppKit
import os

@MainActor
enum PreviewWindowDiagnostics {
    private static let logger = Logger(
        subsystem: "com.tukuyomi032.glance",
        category: "preview-window"
    )

    static func dump(event: String, window: NSWindow?) {
        let keyWindowTitle = NSApp.keyWindow?.title ?? "nil"
        let mainWindowTitle = NSApp.mainWindow?.title ?? "nil"
        let windowTitle = window?.title ?? "nil"
        let frame = window.map { NSStringFromRect($0.frame) } ?? "nil"
        let screen = window?.screen?.localizedName ?? "nil"
        let visibleFrame = window?.screen.map { NSStringFromRect($0.visibleFrame) } ?? "nil"
        let tabCount = window?.tabGroup?.windows.count ?? 0
        let isSelectedTab = window.map { $0.tabGroup?.selectedWindow === $0 } ?? false
        let occlusionState = window?.occlusionState.rawValue ?? 0
        let isVisible = window?.isVisible ?? false
        let isMiniaturized = window?.isMiniaturized ?? false
        let alpha = window?.alphaValue ?? -1
        let policy = NSApp.activationPolicy().rawValue
        let active = NSApp.isActive

        logger.debug(
            "[glance preview] event=\(event) policy=\(policy) active=\(active) key=\(keyWindowTitle) main=\(mainWindowTitle) title=\(windowTitle) visible=\(isVisible) mini=\(isMiniaturized) alpha=\(alpha) frame=\(frame) screen=\(screen) vf=\(visibleFrame) occ=\(occlusionState) tabs=\(tabCount) sel=\(isSelectedTab)"
        )
    }
}
