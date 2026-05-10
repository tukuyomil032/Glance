# glance — macOS Markdown Preview App

## Overview

メニューバーに常駐し、グローバルホットキー (Cmd+G) または メニューバーアイコンから Markdown ファイルを開いて書式付きでプレビューする macOS アプリ。

## Tech Stack

- **Language**: Swift
- **UI Framework**: SwiftUI (settings) + AppKit (AppDelegate, PreviewWindowController) + WKWebView (rendering)
- **Build System**: Xcode project (glance.xcodeproj)
- **Deployment Target**: macOS 26.0 (Tahoe)+
- **Markdown Parser**: Ink (JohnSundell/Ink, SPM) — GFM対応のPure Swiftパーサー
- **Update**: Sparkle 2.9.1 — macOS アプリアップデートフレームワーク
- **Localization**: Localizable.xcstrings (English / 日本語)

## Project Structure

```
glance/
├── glance/                              # Main app target
│   ├── glanceApp.swift                  # App entry point (@main), Settings scene
│   ├── AppDelegate.swift                # Status bar icon, Cmd+G hotkey, Accessibility
│   ├── glance.entitlements              # Sandbox + Network Client + App Group
│   ├── Localizable.xcstrings            # EN / JA localization
│   ├── Services/
│   │   └── UpdaterViewModel.swift       # Sparkle update checker
│   ├── Views/
│   │   ├── SettingsView.swift           # Preferences (Cmd+,)
│   │   └── PreviewContentView.swift     # WKWebView wrapper (NSViewRepresentable)
│   ├── Windows/
│   │   └── PreviewWindowController.swift # File loading + Markdown preview window
│   └── Assets.xcassets/
├── Shared/                              # Shared code (main app)
│   ├── MarkdownRenderer.swift           # Ink wrapper (Markdown → HTML)
│   ├── HTMLTemplate.swift               # HTML + CSS template generation
│   └── PreviewPreferences.swift         # App Group UserDefaults
├── glanceTests/
├── glanceUITests/
├── appcast.xml                          # Sparkle update feed
└── docs/                               # Requirements & specs
```

## Build & Run

```bash
# Build
xcodebuild -project glance.xcodeproj -scheme glance -configuration Debug build

# Run tests
xcodebuild -project glance.xcodeproj -scheme glance -configuration Debug test

# Open preview (app UI)
open build/Debug/glance.app
```

## Key Architecture Decisions

1. **WKWebView for rendering** — NSAttributedString では table / code block / blockquote の表現力が不足するため
2. **Ink (JohnSundell/Ink)** — Pure Swift GFM パーサー。sandbox 安全・テーブル/タスクリスト/打ち消し線対応
3. **CSS custom properties + prefers-color-scheme** — dark mode 自動対応
4. **App Group UserDefaults** — 将来の拡張や複数ウィンドウ間の設定共有
5. **AppKit AppDelegate** — グローバルホットキー登録と NSStatusBar API は AppKit が必要
6. **Sparkle** — macOS 標準外のアプリ配布でのアップデート提供

## Bundle IDs

- Main app: `com.tukuyomi032.glance`
- App Group: `group.com.tukuyomi032.glance`

## Conventions

- Commit message prefix: `feat:`, `fix:`, `ref:`, `docs:`, `chore:`
- 1 commit = 1 logical change
- Swift naming: standard Apple conventions (camelCase properties, PascalCase types)
