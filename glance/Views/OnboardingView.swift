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
            Text("Finder で Markdown ファイルを選択して Space を押すだけ。書式付きプレビューを表示します。")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 48)
                .padding(.bottom, 28)

            Divider()
                .padding(.horizontal, 32)

            // Steps
            VStack(alignment: .leading, spacing: 14) {
                Text("使い方")
                    .font(.headline)
                    .padding(.bottom, 2)

                StepRow(number: 1, text: "glance.app を1度起動する（初回のみ）")
                StepRow(number: 2, text: "Finder で .md ファイルを選択")
                StepRow(number: 3, text: "Space キーを押してプレビュー")
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
                Label("システム設定 > 機能拡張 を開く", systemImage: "arrow.up.right.square")
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
