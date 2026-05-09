# glance — 技術仕様書

## 1. システムアーキテクチャ

```
┌─────────────────────────────────────────────────┐
│  glance.app (Container App)                     │
│  ┌───────────────┐  ┌────────────────────────┐  │
│  │ OnboardingView│  │ SettingsView           │  │
│  │ (SwiftUI)     │  │ (SwiftUI + @AppStorage)│  │
│  └───────────────┘  └────────────────────────┘  │
│                           │                     │
│             App Group UserDefaults              │
│            (group.com.tukuyomi032.glance)       │
│                           │                     │
│  ┌────────────────────────┴──────────────────┐  │
│  │  Contents/Library/QuickLook/              │  │
│  │  glanceQLExtension.appex                  │  │
│  │  ┌──────────────────────────────────────┐ │  │
│  │  │ PreviewViewController                │ │  │
│  │  │ (NSViewController + QLPreviewingCtrl)│ │  │
│  │  │         │                            │ │  │
│  │  │    ┌────▼─────┐    ┌──────────────┐  │ │  │
│  │  │    │ Markdown │    │ HTML         │  │ │  │
│  │  │    │ Renderer │───▶│ Template     │  │ │  │
│  │  │    │ (cmark)  │    │ (CSS + HTML) │  │ │  │
│  │  │    └──────────┘    └──────┬───────┘  │ │  │
│  │  │                           │          │ │  │
│  │  │                    ┌──────▼───────┐  │ │  │
│  │  │                    │  WKWebView   │  │ │  │
│  │  │                    └──────────────┘  │ │  │
│  │  └──────────────────────────────────────┘ │  │
│  └───────────────────────────────────────────┘  │
└─────────────────────────────────────────────────┘
```

---

## 2. ターゲット構成

### 2.1 glance (Main App)

| 項目 | 値 |
|------|-----|
| Bundle ID | `com.tukuyomi032.glance` |
| Product Type | Application (.app) |
| Frameworks | SwiftUI, WebKit |
| Deployment Target | macOS 12.0+ |
| Sandbox | Yes |
| App Group | `group.com.tukuyomi032.glance` |

### 2.2 glanceQLExtension (Quick Look Extension)

| 項目 | 値 |
|------|-----|
| Bundle ID | `com.tukuyomi032.glance.QLExtension` |
| Product Type | Quick Look Preview Extension (.appex) |
| Frameworks | Quartz, WebKit |
| Deployment Target | macOS 12.0+ |
| Sandbox | Yes |
| App Group | `group.com.tukuyomi032.glance` |
| Embed Location | `Contents/Library/QuickLook/` |

---

## 3. コンポーネント詳細

### 3.1 MarkdownRenderer

**ファイル**: `Shared/MarkdownRenderer.swift`
**ターゲット**: glance, glanceQLExtension

cmark の C API をラップし、Markdown テキストを HTML 文字列に変換する。

```swift
enum MarkdownRenderer {
    /// Markdown テキストを HTML fragment に変換
    static func render(_ markdown: String) -> String
}
```

**パーサーオプション**:
- `CMARK_OPT_SMART` — スマートクォート、em-dash 変換
- `CMARK_OPT_UNSAFE` — 生の HTML を許可（サンドボックス内なので安全）

**依存**: swift-cmark SPM パッケージ (`https://github.com/apple/swift-cmark`)

### 3.2 HTMLTemplate

**ファイル**: `Shared/HTMLTemplate.swift`
**ターゲット**: glance, glanceQLExtension

HTML fragment を完全な HTML ドキュメントにラップする。CSS を `<style>` タグとしてインライン埋め込み。

```swift
enum HTMLTemplate {
    /// 完全な HTML ページを生成
    static func render(markdown: String, preferences: PreviewPreferences) -> String
}
```

### 3.3 PreviewPreferences

**ファイル**: `Shared/PreviewPreferences.swift`
**ターゲット**: glance, glanceQLExtension

App Group UserDefaults を介した設定値の読み書き。

```swift
struct PreviewPreferences {
    var fontSize: Int          // default: 16
    var maxWidth: Int          // default: 760
    var showLineNumbers: Bool  // default: false
    
    static func load() -> PreviewPreferences
    func save()
}
```

**UserDefaults Suite**: `group.com.tukuyomi032.glance`

### 3.4 PreviewViewController

**ファイル**: `glanceQLExtension/PreviewViewController.swift`
**ターゲット**: glanceQLExtension

Quick Look Extension のエントリーポイント。

```swift
class PreviewViewController: NSViewController, QLPreviewingController {
    func preparePreviewOfFile(at url: URL) async throws
}
```

**処理フロー**:
1. `url` からファイルデータを読み込み（UTF-8）
2. `MarkdownRenderer.render()` で HTML fragment に変換
3. `HTMLTemplate.render()` で完全な HTML ページを生成
4. `WKWebView.loadHTMLString()` で表示
5. `baseURL` をファイルの親ディレクトリに設定（相対画像パス解決用）

### 3.5 OnboardingView

**ファイル**: `glance/Views/OnboardingView.swift`
**ターゲット**: glance

アプリ起動時に表示するメイン画面。

**表示内容**:
- アプリアイコンとタイトル
- インストール状態の表示
- 使い方の説明（Finder で .md を選択 → Space）
- Markdown ファイルのドラッグ＆ドロップによるインアプリプレビュー

### 3.6 SettingsView

**ファイル**: `glance/Views/SettingsView.swift`
**ターゲット**: glance

macOS 標準の Settings ウィンドウ（Cmd+,）。

**設定項目**:
- フォントサイズ: `Picker` (14 / 16 / 18)
- コンテンツ最大幅: `Slider` (500–900px)
- 行番号表示: `Toggle`

---

## 4. CSS 設計

### 4.1 カスタムプロパティ

```css
:root {
    --bg: #ffffff;
    --text: #24292e;
    --link: #0366d6;
    --code-bg: #f6f8fa;
    --code-text: #24292e;
    --border: #e1e4e8;
    --heading-border: #eaecef;
    --blockquote-border: #dfe2e5;
    --blockquote-text: #6a737d;
    --table-border: #dfe2e5;
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
        --code-text: #e6edf3;
        --border: #30363d;
        --heading-border: #21262d;
        --blockquote-border: #3b434b;
        --blockquote-text: #8b949e;
        --table-border: #30363d;
        --table-stripe: #161b22;
    }
}
```

### 4.3 タイポグラフィ

- Body: `-apple-system, BlinkMacSystemFont, "Segoe UI", Helvetica, Arial, sans-serif`
- Code: `"SF Mono", "Menlo", "Monaco", "Courier New", monospace`
- Line height: `1.6`
- Max width: 設定値 (default 760px)、中央揃え

### 4.4 要素別スタイル

| 要素 | スタイル |
|------|---------|
| `h1` | 2em, bold, 下ボーダー |
| `h2` | 1.5em, bold, 下ボーダー |
| `h3`–`h6` | 段階的サイズ、bold |
| `code` (inline) | 背景色、角丸、padding |
| `pre code` | 背景色、角丸、横スクロール、padding 1em |
| `blockquote` | 左ボーダー 4px、薄い文字色 |
| `table` | 罫線、ゼブラストライプ |
| `img` | max-width: 100% |
| `hr` | border-top のみ |
| `a` | リンク色、下線なし、ホバーで下線 |

---

## 5. Info.plist 設定

### 5.1 Extension Info.plist

```xml
<key>NSExtension</key>
<dict>
    <key>NSExtensionAttributes</key>
    <dict>
        <key>QLSupportedContentTypes</key>
        <array>
            <string>net.daringfireball.markdown</string>
            <string>net.ia.markdown</string>
            <string>public.markdown</string>
            <string>text.markdown</string>
        </array>
        <key>QLSupportsSearchableItems</key>
        <true/>
    </dict>
    <key>NSExtensionPointIdentifier</key>
    <string>com.apple.quicklook.preview</string>
    <key>NSExtensionPrincipalClass</key>
    <string>$(PRODUCT_MODULE_NAME).PreviewViewController</string>
</dict>
```

### 5.2 Container App — UTImportedTypeDeclarations

```xml
<key>UTImportedTypeDeclarations</key>
<array>
    <dict>
        <key>UTTypeIdentifier</key>
        <string>net.daringfireball.markdown</string>
        <key>UTTypeDescription</key>
        <string>Markdown Document</string>
        <key>UTTypeConformsTo</key>
        <array>
            <string>public.plain-text</string>
        </array>
        <key>UTTypeTagSpecification</key>
        <dict>
            <key>public.filename-extension</key>
            <array>
                <string>md</string>
                <string>markdown</string>
                <string>mdown</string>
                <string>mkd</string>
            </array>
        </dict>
    </dict>
</array>
```

---

## 6. Entitlements

### 6.1 glance.entitlements

```xml
<key>com.apple.security.app-sandbox</key>
<true/>
<key>com.apple.security.files.user-selected.read-only</key>
<true/>
<key>com.apple.security.application-groups</key>
<array>
    <string>group.com.tukuyomi032.glance</string>
</array>
```

### 6.2 glanceQLExtension.entitlements

```xml
<key>com.apple.security.app-sandbox</key>
<true/>
<key>com.apple.security.application-groups</key>
<array>
    <string>group.com.tukuyomi032.glance</string>
</array>
```

---

## 7. SPM 依存

| パッケージ | URL | バージョン | ターゲット |
|-----------|-----|-----------|-----------|
| swift-cmark | `https://github.com/apple/swift-cmark` | latest | glance, glanceQLExtension |

---

## 8. テスト計画

### 8.1 ユニットテスト (glanceTests)

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

### 8.2 手動統合テスト

| テスト | 手順 |
|--------|------|
| Quick Look 起動 | Finder で .md 選択 → Space → 書式付き表示を確認 |
| ダークモード | システム設定切替 → 配色変化を確認 |
| 大きなファイル | 1MB+ の .md → タイムアウトなく表示 |
| 相対画像 | 同ディレクトリの画像パスが解決されるか |
| 設定反映 | フォントサイズ変更 → 再プレビューで反映 |

---

## 9. 配布

### 9.1 直接配布（推奨）

1. Developer ID Application 証明書で署名
2. `xcrun notarytool submit` で公証
3. `xcrun stapler staple` でチケット添付
4. `.dmg` で配布（Applications へドラッグ）

### 9.2 App Store（オプション）

- サンドボックス必須（対応済み）
- UTImportedTypeDeclarations の正確な設定が必要
- 画像表示に制約あり

---

## 10. 実装フェーズ

### Phase 1: Foundation
1. swift-cmark SPM パッケージ追加
2. `Shared/MarkdownRenderer.swift` 実装
3. `Shared/HTMLTemplate.swift` 実装（CSS 含む）
4. `Shared/PreviewPreferences.swift` 実装
5. ユニットテスト作成・通過確認

### Phase 2: Quick Look Extension
6. Xcode で Quick Look Preview Extension ターゲット追加
7. Info.plist に UTType 設定
8. `PreviewViewController.swift` 実装
9. App Group entitlement を両ターゲットに設定
10. Extension を main app にエンベッド
11. `qlmanage -r` ポストビルドスクリプト追加

### Phase 3: Main App UI
12. `glanceApp.swift` を Settings シーン付きに更新
13. `OnboardingView.swift` 実装
14. `SettingsView.swift` 実装
15. インアプリプレビュー機能

### Phase 4: Polish
16. アプリアイコン作成
17. UI テスト
18. ダーク/ライトモード検証
19. 配布パッケージング
