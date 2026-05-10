<div align="center">

# glance

A macOS menu bar app for beautifully rendered Markdown previews

[![macOS](https://img.shields.io/badge/macOS-Tahoe%2B-blue)](https://www.apple.com/macos/)
[![Swift](https://img.shields.io/badge/Swift-5-orange)](https://swift.org)
[![License: MIT](https://img.shields.io/badge/License-MIT-lightgrey)](LICENSE)

</div>

## Overview

glance is a macOS menu bar app that renders Markdown files with rich formatting. Press **Cmd+G** from anywhere to open a file and see beautifully formatted content — headings, lists, tables, code blocks, and more — instantly.

## Features

- Global hotkey **Cmd+G** to open any Markdown file without switching apps
- Renders headings, emphasis, lists, blockquotes, tables, and fenced code blocks
- Automatic dark mode support via CSS `prefers-color-scheme`
- Configurable font size (14 / 16 / 18 px) and content max width (500–900 px)
- Language support: English and Japanese
- Automatic updates via Sparkle
- Supports `.md`, `.markdown`, `.mdown`, and `.mkd` file extensions

## Installation

**Requirements:** macOS Tahoe (26.0) or later

Download the latest release from [GitHub Releases](https://github.com/tukuyomi032/glance/releases):

1. Open the DMG and drag **glance** to your Applications folder.
2. Launch glance — the icon appears in your menu bar.
3. Grant **Accessibility** permission when prompted (required for the global hotkey).

## Usage

### Opening a file

- Press **Cmd+G** from anywhere to open a file dialog
- Or click the glance icon in the menu bar and select **Open File…**

### Adjusting settings

Press **Cmd+,** or go to **glance → Settings** to configure:

- **Language** — System Default, English, or 日本語
- **Font size** — 14, 16, or 18 px
- **Max content width** — 500 to 900 px
- **Auto-update** — automatically check for new versions

## Build from Source

**Prerequisites:** Xcode 16+

```bash
# Clone the repository
git clone https://github.com/tukuyomi032/glance.git
cd glance

# Build
xcodebuild -project glance.xcodeproj -scheme glance -configuration Debug build

# Run tests
xcodebuild -project glance.xcodeproj -scheme glance -configuration Debug test
```

## Tech Stack

| Component | Technology |
|-----------|-----------|
| Language | Swift |
| UI | SwiftUI + AppKit + WKWebView |
| Markdown | [Ink](https://github.com/JohnSundell/Ink) (JohnSundell/Ink) |
| Updates | [Sparkle](https://github.com/sparkle-project/Sparkle) 2.9.1 |
| Build | Xcode |
