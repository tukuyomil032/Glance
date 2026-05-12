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
│  │ fontSize      │  │ PreviewWindowManager │   │
│  │ maxWidth      │  │ - Own preview windows │   │
│  │ language      │  │ - Own split windows   │   │
│  │ updates       │  │ - Remove on close     │   │
│  └───────────────┘                 ▼            │
│                    ┌────────────────────────────┐   │
│                    │ PreviewWindowController     │   │
│                    │ SplitPreviewWindowController│   │
│                    │ MarkdownPreviewPaneController│  │
│                    │ - Read file (UTF-8)         │   │
│                    │ - MarkdownRenderer           │   │
│                    │ - HTMLTemplate               │   │
│                    │ - WKWebView display          │   │
│                    └────────────────────────────┘   │
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
- グローバルホットキー Cmd+G → ファイルオープンダイアログ → `PreviewWindowManager` 経由で preview window を生成
- メニューに「Open Markdown File…」「Open in Split View…」「Settings…」「Quit glance」を表示
- Carbon Hot Key で Cmd+G を登録

### 3.3 PreviewWindowManager

**ファイル**: `glance/Windows/PreviewWindowManager.swift`

preview window / split window の生成と生存管理を担当する coordinator。各ファイルを独立した window として開き、閉じた window の参照を解除する。既存の preview があれば AppKit の標準 tab group にまとめる。

### 3.4 PreviewWindowController

**ファイル**: `glance/Windows/PreviewWindowController.swift`

Markdown ファイルを読み込み、WKWebView にレンダリング結果を表示する NSWindowController。
表示モードは `standard` / `Liquid Glass` を切り替え可能で、設定値に応じてウィンドウ背景と HTML テーマを調整する。
各 controller は独立して動作し、singleton の `shared` は持たない。
open / close 時は控えめな `fade + scale` 遷移を使う。

### 3.5 SplitPreviewWindowController

**ファイル**: `glance/Windows/SplitPreviewWindowController.swift`

2 つの Markdown ファイルを `NSSplitViewController` で左右に並べて表示する NSWindowController。
単一 preview と同じレンダリング経路を、2 つの pane で再利用する。

### 3.6 MarkdownPreviewPaneController

**ファイル**: `glance/Windows/MarkdownPreviewPaneController.swift`

Markdown ファイルの読み込み・再描画・WKWebView への反映を担う再利用可能な pane controller。
window 固有の装飾は持たず、単一 preview と split preview の両方から使う。

**処理フロー**:
1. ファイルパスを受け取り、UTF-8 でテキスト読み込み
2. `MarkdownRenderer.render()` で HTML fragment に変換
3. `HTMLTemplate.render()` で完全な HTML ページを生成（設定値注入）
4. `WKWebView.loadHTMLString()` で表示
5. 表示と終了は `PreviewWindowTransitionCoordinator` 経由でアニメーションする

### 3.7 SettingsView

**ファイル**: `glance/Views/SettingsView.swift`

macOS 標準の Settings ウィンドウ（Cmd+,）。SwiftUI で実装。

**設定項目**:
- 表示モード: Standard / Liquid Glass
- Split View: `Open in Split View…` から 2 ファイルを選ぶと横並びで表示
- 言語: `Picker` (System Default / English / 日本語)
- フォントサイズ: `Picker` (14 / 16 / 18 px)
- コンテンツ最大幅: `Slider` (500–900 px)
- 自動アップデート: `Toggle`
- 「今すぐ確認」ボタン

### 3.8 PreviewContentView

**ファイル**: `glance/Views/PreviewContentView.swift`

`WKWebView` を SwiftUI で使用するための `NSViewRepresentable` ラッパー。

### 3.9 UpdaterViewModel

**ファイル**: `glance/Services/UpdaterViewModel.swift`

Sparkle フレームワークの `SPUUpdater` をラップした `ObservableObject`。アップデートチェックとインストールを管理。

### 3.10 MarkdownRenderer

**ファイル**: `Shared/MarkdownRenderer.swift`

Ink (JohnSundell/Ink) の薄いラッパー。Markdown テキストを HTML fragment に変換し、fenced code block の language class を保持する。

```swift
enum MarkdownRenderer {
    static func render(_ markdown: String) -> String
}
```

**パーサー**: Ink 0.6.0 — GFM対応（テーブル・タスクリスト・打ち消し線）

### 3.11 HTMLTemplate

**ファイル**: `Shared/HTMLTemplate.swift`

HTML fragment を完全な HTML ドキュメントにラップする。CSS を `<style>` タグとしてインライン埋め込みし、同梱した `highlight.js` を読み込む。

```swift
enum HTMLTemplate {
    static func render(markdown: String, preferences: PreviewPreferences) -> String
}
```

### 3.12 PreviewPreferences

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
| `testCodeBlockPreservesLanguageClass` | fenced code の言語情報保持 |
| `testTable` | pipe table → `<table>` |
| `testEmptyInput` | 空文字列 → 空 body の valid HTML |
| `testUTF8` | 日本語・絵文字の正常レンダリング |
| `testHTMLTemplateStructure` | 出力に `<!DOCTYPE html>`, `<style>` が含まれる |
| `testPreferencesDefaults` | デフォルト値の検証 |
| `testPreviewWindowManager` | preview window の独立生成と cleanup |
| `testPreviewWindowTabs` | 2 つ目の preview が既存 window に tab として結合される |
| `testSplitPreviewWindowManager` | split window の生成と cleanup |
| `testMarkdownOpenPanelCoordinatorSplitSelection` | split 用 open panel が 2 ファイル選択を検証する |
| `testPreviewWindowTransition` | preview window の open / close アニメーションを確認する |

### 7.2 手動統合テスト

| テスト | 手順 |
|--------|------|
| ホットキー起動 | Cmd+G → ファイルダイアログ表示 → .md 選択 → プレビュー表示 |
| メニューバー操作 | メニューバーアイコン → Open Markdown File… → プレビュー表示 |
| Split View | Open in Split View… → 2 ファイル選択 → 2 pane 表示 |
| ダークモード | システム設定切替 → 配色変化を確認 |
| 設定反映 | フォントサイズ変更 → プレビューウィンドウで反映確認 |
| アップデート確認 | Settings → Check for Updates ボタン押下 |

---

## 8. 配布

### 8.1 直接配布

1. archive から staging app を作成
2. staging app を再署名し `codesign --verify --deep --strict` を通す
3. `spctl --assess` で実行可能性を確認
4. `appcast.xml` を更新（Sparkle アップデートフィード）
5. `.dmg` で配布（Applications へドラッグ）
