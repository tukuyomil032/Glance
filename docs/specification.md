# glance — 技術仕様書

## 1. システムアーキテクチャ

```
┌─────────────────────────────────────────────────┐
│  glance.app                                     │
│  ┌──────────────┐   ┌──────────────────────┐   │
│  │ glanceApp    │   │ AppDelegate           │   │
│  │ (@main)      │   │ - NSStatusBar icon    │   │
│  │ Settings     │   │ - Global hotkey (Cmd+G)   │
│  │ scene        │   │ - App activation policy   │   │
│  └──────────────┘   └────────────┬─────────┘   │
│                                  │ open file    │
│  ┌───────────────┐               │              │
│  │ SettingsView  │               ▼              │
│  │ (SwiftUI)     │  ┌──────────────────────┐   │
│  │ fontSize      │  │ PreviewWindowCtrlr    │   │
│  │ maxWidth      │  │ - Read file (UTF-8)  │   │
│  │ language      │  │ - MarkdownRenderer    │   │
│  │ updates       │  │ - HTMLTemplate        │   │
│  └───────────────┘  │ - WKWebView display   │   │
│                     └──────────────────────┘   │
│  ┌───────────────┐                             │
│  │ UpdaterVM     │   App Group UserDefaults    │
│  │ (Sparkle)     │  (group.com.tukuyomi032.glance)  │
│  └───────────────┘                             │
└─────────────────────────────────────────────────┘
```

---

## 2. ターゲット構成

### 2.1 glance (Main App)

| 項目 | 値 |
|------|-----|
| Bundle ID | `com.tukuyomi032.glance` |
| Product Type | Application (.app) |
| Frameworks | SwiftUI, AppKit, WebKit |
| Deployment Target | macOS 26.0+ |
| Sandbox | Yes |
| Network Client | Yes (Sparkle update check) |
| App Group | `group.com.tukuyomi032.glance` |

---

## 3. コンポーネント詳細

### 3.1 glanceApp

**ファイル**: `glance/glanceApp.swift`

SwiftUI の `@main` エントリーポイント。Settings シーンを定義し、`AppDelegate` を `@NSApplicationDelegateAdaptor` で接続。

### 3.2 AppDelegate

**ファイル**: `glance/AppDelegate.swift`

メニューバーアイコン・グローバルホットキー・アプリ前面化制御を担当。

**機能**:
- `NSStatusBar.system.statusItem` でメニューバーアイコン表示
- グローバルホットキー Cmd+G → ファイルオープンダイアログ → `PreviewWindowController` を起動
- Carbon Hot Key で Cmd+G を登録
- メニューに「Open Markdown File…」「Settings…」「Quit glance」を表示

### 3.3 PreviewWindowController

**ファイル**: `glance/Windows/PreviewWindowController.swift`

Markdown ファイルを読み込み、WKWebView にレンダリング結果を表示する NSWindowController。

**処理フロー**:
1. ファイルパスを受け取り、UTF-8 でテキスト読み込み
2. `MarkdownRenderer.render()` で HTML fragment に変換
3. `HTMLTemplate.render()` で完全な HTML ページを生成（設定値注入）
4. `WKWebView.loadHTMLString()` で表示

### 3.4 SettingsView

**ファイル**: `glance/Views/SettingsView.swift`

macOS 標準の Settings ウィンドウ（Cmd+,）。SwiftUI で実装。

**設定項目**:
- 言語: `Picker` (System Default / English / 日本語)
- フォントサイズ: `Picker` (14 / 16 / 18 px)
- コンテンツ最大幅: `Slider` (500–900 px)
- 自動アップデート: `Toggle`
- 「今すぐ確認」ボタン

### 3.5 PreviewContentView

**ファイル**: `glance/Views/PreviewContentView.swift`

`WKWebView` を SwiftUI で使用するための `NSViewRepresentable` ラッパー。

### 3.6 UpdaterViewModel

**ファイル**: `glance/Services/UpdaterViewModel.swift`

Sparkle フレームワークの `SPUUpdater` をラップした `ObservableObject`。アップデートチェックとインストールを管理。

### 3.7 MarkdownRenderer

**ファイル**: `Shared/MarkdownRenderer.swift`

Ink (JohnSundell/Ink) の薄いラッパー。Markdown テキストを HTML fragment に変換。

```swift
enum MarkdownRenderer {
    static func render(_ markdown: String) -> String
}
```

**パーサー**: Ink 0.6.0 — GFM対応（テーブル・タスクリスト・打ち消し線）

### 3.8 HTMLTemplate

**ファイル**: `Shared/HTMLTemplate.swift`

HTML fragment を完全な HTML ドキュメントにラップする。CSS を `<style>` タグとしてインライン埋め込み。

```swift
enum HTMLTemplate {
    static func render(markdown: String, preferences: PreviewPreferences) -> String
}
```

### 3.9 PreviewPreferences

**ファイル**: `Shared/PreviewPreferences.swift`

App Group UserDefaults を介した設定値の読み書き。

```swift
struct PreviewPreferences {
    var fontSize: Int       // default: 16
    var maxWidth: Int       // default: 760
    var language: String    // default: "system"
    
    static func load() -> PreviewPreferences
    func save()
}
```

**UserDefaults Suite**: `group.com.tukuyomi032.glance`

---

## 4. CSS 設計

### 4.1 カスタムプロパティ（ライトモード）

```css
:root {
    --bg: #ffffff;
    --text: #1f2328;
    --link: #0969da;
    --code-bg: #f6f8fa;
    --border: #d0d7de;
    --blockquote-border: #d0d7de;
    --blockquote-text: #656d76;
    --table-border: #d0d7de;
    --table-stripe: #f6f8fa;
}
```

### 4.2 ダークモード

```css
@media (prefers-color-scheme: dark) {
    :root {
        --bg: #0d1117;
        --text: #e6edf3;
        --link: #58a6ff;
        --code-bg: #161b22;
        --border: #30363d;
        --blockquote-border: #3b434b;
        --blockquote-text: #8b949e;
        --table-border: #30363d;
        --table-stripe: #161b22;
    }
}
```

### 4.3 タイポグラフィ

- Body: `-apple-system, BlinkMacSystemFont, "Segoe UI", Helvetica, Arial, sans-serif`
- Code: `"SF Mono", SFMono-Regular, ui-monospace, "Cascadia Mono", Menlo, Consolas, monospace`
- Line height: `1.6`
- Max width: 設定値 (default 760px)、中央揃え

---

## 5. Entitlements

### glance.entitlements

```xml
<key>com.apple.security.app-sandbox</key>
<true/>
<key>com.apple.security.network.client</key>
<true/>
<key>com.apple.security.application-groups</key>
<array>
    <string>group.com.tukuyomi032.glance</string>
</array>
```

---

## 6. SPM 依存

| パッケージ | URL | バージョン | 用途 |
|-----------|-----|-----------|------|
| Ink | `https://github.com/JohnSundell/Ink` | 0.6.0 | Markdown → HTML 変換 |
| Sparkle | `https://github.com/sparkle-project/Sparkle` | 2.9.1 | アップデート配信 |

---

## 7. テスト計画

### 7.1 ユニットテスト (glanceTests)

| テスト | 内容 |
|--------|------|
| `testHeadingRendering` | `# Title` → `<h1>Title</h1>` |
| `testBoldItalic` | `**bold**` → `<strong>bold</strong>` |
| `testCodeBlock` | fenced code → `<pre><code>` |
| `testTable` | pipe table → `<table>` |
| `testEmptyInput` | 空文字列 → 空 body の valid HTML |
| `testUTF8` | 日本語・絵文字の正常レンダリング |
| `testHTMLTemplateStructure` | 出力に `<!DOCTYPE html>`, `<style>` が含まれる |
| `testPreferencesDefaults` | デフォルト値の検証 |

### 7.2 手動統合テスト

| テスト | 手順 |
|--------|------|
| ホットキー起動 | Cmd+G → ファイルダイアログ表示 → .md 選択 → プレビュー表示 |
| メニューバー操作 | メニューバーアイコン → Open Markdown File… → プレビュー表示 |
| ダークモード | システム設定切替 → 配色変化を確認 |
| 設定反映 | フォントサイズ変更 → プレビューウィンドウで反映確認 |
| アップデート確認 | Settings → Check for Updates ボタン押下 |

---

## 8. 配布

### 8.1 直接配布

1. Developer ID Application 証明書で署名
2. `xcrun notarytool submit` で公証
3. `xcrun stapler staple` でチケット添付
4. `appcast.xml` を更新（Sparkle アップデートフィード）
5. `.dmg` で配布（Applications へドラッグ）
