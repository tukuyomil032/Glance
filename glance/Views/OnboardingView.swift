//
//  OnboardingView.swift
//  glance
//
//  Created by yomi on 2026/05/09.
//

import SwiftUI

struct OnboardingView: View {
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 12) {
                Image(systemName: "eye.fill")
                    .font(.system(size: 56, weight: .medium))
                    .foregroundStyle(Color.accentColor)

                Text("glance")
                    .font(.system(size: 32, weight: .bold, design: .rounded))

                Text("Markdown Quick Look Preview")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 36)
            .padding(.bottom, 20)

            // Description
            Text("Just select a Markdown file in Finder and press Space. It shows a formatted preview.")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 48)
                .padding(.bottom, 28)

            Divider()
                .padding(.horizontal, 32)

            // Steps
            VStack(alignment: .leading, spacing: 14) {
                Text("How to Use")
                    .font(.headline)
                    .padding(.bottom, 2)

                StepRow(number: 1, text: "Launch glance.app once (first time only)")
                StepRow(number: 2, text: "Select a .md file in Finder")
                StepRow(number: 3, text: "Press Space to preview")
            }
            .padding(.horizontal, 48)
            .padding(.vertical, 20)

            Divider()
                .padding(.horizontal, 32)

            // Footer button
            Button {
                if let url = URL(string: "x-apple.systempreferences:com.apple.preference.extensions") {
                    NSWorkspace.shared.open(url)
                }
            } label: {
                Label("Open System Settings > Extensions", systemImage: "arrow.up.right.square")
                    .font(.callout)
            }
            .buttonStyle(.plain)
            .foregroundStyle(Color.accentColor)
            .padding(.vertical, 16)
        }
        .frame(minWidth: 480, minHeight: 400)
    }
}

private struct StepRow: View {
    let number: Int
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text("\(number)")
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
                .frame(width: 22, height: 22)
                .background(Color.accentColor, in: Circle())

            Text(text)
                .font(.body)
        }
    }
}

#Preview {
    OnboardingView()
}
