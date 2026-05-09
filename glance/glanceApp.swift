//
//  glanceApp.swift
//  glance
//
//  Created by yomi on 2026/05/09.
//

import SwiftUI

@main
struct glanceApp: App {
    @StateObject private var updaterViewModel = UpdaterViewModel()
    @State private var appLocale: Locale = {
        let lang = PreviewPreferences.load().language
        if lang == "system" { return .autoupdatingCurrent }
        return Locale(identifier: lang)
    }()

    var body: some Scene {
        WindowGroup {
            OnboardingView()
                .environment(\.locale, appLocale)
        }
        .defaultSize(width: 540, height: 420)
        .windowResizability(.contentSize)
        .commands {
            CommandGroup(after: .appInfo) {
                Button("Check for Updates...", action: updaterViewModel.checkForUpdates)
                    .disabled(!updaterViewModel.canCheckForUpdates)
            }
        }

        Settings {
            SettingsView(appLocale: $appLocale, updaterViewModel: updaterViewModel)
                .environment(\.locale, appLocale)
        }
    }
}
