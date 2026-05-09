# glance — macOS Quick Look Markdown Preview Extension

## Overview

Finder で `.md` ファイルを選択し Space キーで Quick Look を起動すると、Markdown が書式付きでレンダリング表示される macOS アプリ。

## Tech Stack

- **Language**: Swift
- **UI Framework**: SwiftUI (macOS app) + WKWebView (preview rendering)
- **Build System**: Xcode project (glance.xcodeproj)
- **Minimum Deployment**: macOS 12.0+
- **Markdown Parser**: Ink (JohnSundell/Ink, SPM) — GFM対応のPure Swiftパーサー
- **Quick Look API**: QLPreviewingController (Quartz framework)

## Project Structure

```
glance/
├── glance/                          # Main app target (container + settings)
│   ├── glanceApp.swift              # App entry point (@main)
│   ├── Views/
│   │   ├── OnboardingView.swift     # Initial setup/status screen
│   │   └── SettingsView.swift       # Preferences (Cmd+,)
│   └── Assets.xcassets/
├── glanceQLExtension/               # Quick Look Preview Extension target
│   ├── PreviewViewController.swift  # QLPreviewingController implementation
│   └── Info.plist                   # UTType declarations
├── Shared/                          # Shared code (both targets)
│   ├── MarkdownRenderer.swift       # Ink wrapper (Markdown → HTML)
│   ├── HTMLTemplate.swift           # HTML + CSS template generation
│   └── PreviewPreferences.swift     # App Group UserDefaults
├── glanceTests/
├── glanceUITests/
└── docs/                            # Requirements & specs
```

## Build & Run

```bash
# Build
xcodebuild -project glance.xcodeproj -scheme glance -configuration Debug build

# Reset Quick Look cache (after build)
qlmanage -r

# Test Quick Look preview
qlmanage -p path/to/file.md

# Run tests
xcodebuild -project glance.xcodeproj -scheme glance -configuration Debug test
```

## Key Architecture Decisions

1. **WKWebView for rendering** — NSAttributedString では table / code block / blockquote の表現力が不足するため
2. **Ink (JohnSundell/Ink)** — Pure Swift GFM パーサー。sandbox 安全・テーブル/タスクリスト/打ち消し線対応
3. **CSS custom properties + prefers-color-scheme** — dark mode 自動対応
4. **App Group UserDefaults** — main app ↔ extension 間の設定共有
5. **QLPreviewingController** — macOS 12+ の Quick Look extension API

## Bundle IDs

- Main app: `com.tukuyomi032.glance`
- Extension: `com.tukuyomi032.glance.QLExtension`
- App Group: `group.com.tukuyomi032.glance`

## Supported UTTypes

- `net.daringfireball.markdown`
- `net.ia.markdown`
- `public.markdown`
- `text.markdown`

File extensions: `.md`, `.markdown`, `.mdown`, `.mkd`

## Conventions

- Commit message prefix: `feat:`, `fix:`, `ref:`, `docs:`, `chore:`
- 1 commit = 1 logical change
- Swift naming: standard Apple conventions (camelCase properties, PascalCase types)
