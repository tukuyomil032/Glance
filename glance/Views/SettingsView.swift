//
//  SettingsView.swift
//  glance
//
//  Created by yomi on 2026/05/09.
//

import SwiftUI

struct SettingsView: View {
    @State private var fontSize: Int = PreviewPreferences.load().fontSize
    @State private var maxWidth: Double = Double(PreviewPreferences.load().maxWidth)

    var body: some View {
        Form {
            Section("プレビュー") {
                Picker("文字サイズ", selection: $fontSize) {
                    Text("小").tag(14)
                    Text("中").tag(16)
                    Text("大").tag(18)
                }
                .pickerStyle(.segmented)
                .onChange(of: fontSize) { _, newValue in
                    var prefs = PreviewPreferences.load()
                    prefs.fontSize = newValue
                    prefs.save()
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("最大幅")
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
        }
        .formStyle(.grouped)
        .frame(width: 360, height: 200)
    }
}

#Preview {
    SettingsView()
}
