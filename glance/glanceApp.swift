//
//  glanceApp.swift
//  glance
//
//  Created by yomi on 2026/05/09.
//

import SwiftUI

@main
struct glanceApp: App {
    var body: some Scene {
        WindowGroup {
            OnboardingView()
        }
        .defaultSize(width: 540, height: 420)
        .windowResizability(.contentSize)

        Settings {
            SettingsView()
        }
    }
}
