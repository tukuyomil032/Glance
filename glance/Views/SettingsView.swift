//
//  SettingsView.swift
//  glance
//
//  Created by yomi on 2026/05/09.
//

import SwiftUI

struct SettingsView: View {
    @Binding var appLocale: Locale
    @ObservedObject var updaterViewModel: UpdaterViewModel
    @State private var fontSize: Int = PreviewPreferences.load().fontSize
    @State private var maxWidth: Double = Double(PreviewPreferences.load().maxWidth)
    @State private var language: String = PreviewPreferences.load().language
    @State private var appearanceMode: PreviewAppearanceMode = PreviewPreferences.load().appearanceMode

    private var currentVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—"
    }

    var body: some View {
        Form {
            Section("General") {
                Picker("Language", selection: $language) {
                    Text("System Default").tag("system")
                    Text("English").tag("en")
                    Text("日本語").tag("ja")
                }
                .onChange(of: language) { _, newValue in
                    var prefs = PreviewPreferences.load()
                    prefs.language = newValue
                    prefs.save()
                    if newValue == "system" {
                        appLocale = .autoupdatingCurrent
                    } else {
                        appLocale = Locale(identifier: newValue)
                    }
                }
            }

            Section("Preview") {
                Picker("Window Style", selection: $appearanceMode) {
                    ForEach(PreviewAppearanceMode.allCases, id: \.self) { mode in
                        Text(mode.displayName).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .onChange(of: appearanceMode) { _, newValue in
                    var prefs = PreviewPreferences.load()
                    prefs.appearanceMode = newValue
                    prefs.save()
                }

                Picker("Font Size", selection: $fontSize) {
                    Text("Small").tag(14)
                    Text("Medium").tag(16)
                    Text("Large").tag(18)
                }
                .pickerStyle(.segmented)
                .onChange(of: fontSize) { _, newValue in
                    var prefs = PreviewPreferences.load()
                    prefs.fontSize = newValue
                    prefs.save()
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Max Width")
                        Spacer()
                        Text("\(Int(maxWidth)) pt")
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                    }
                    Slider(value: $maxWidth, in: 500...900, step: 10)
                        .onChange(of: maxWidth) { _, newValue in
                            var prefs = PreviewPreferences.load()
                            prefs.maxWidth = Int(newValue)
                            prefs.save()
                        }
                }
            }
            Section("Updates") {
                Toggle("Check for updates automatically", isOn: Binding(
                    get: { updaterViewModel.automaticallyChecksForUpdates },
                    set: { updaterViewModel.automaticallyChecksForUpdates = $0 }
                ))

                if let missingConfigurationReason = updaterViewModel.missingConfigurationReason {
                    Text(missingConfigurationReason)
                        .foregroundStyle(.secondary)
                        .font(.footnote)
                }

                Button("Check for Updates") {
                    updaterViewModel.checkForUpdates()
                }
                .disabled(!updaterViewModel.canCheckForUpdates || !updaterViewModel.isConfiguredForUpdates)

                Text("Version \(currentVersion)")
                    .foregroundStyle(.secondary)
                    .font(.footnote)
            }
        }
        .formStyle(.grouped)
        .frame(width: 360, height: 430)
    }
}

#Preview {
    SettingsView(appLocale: .constant(.autoupdatingCurrent), updaterViewModel: UpdaterViewModel())
}
