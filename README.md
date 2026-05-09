<div align="center">

# glance

A macOS Quick Look extension for beautifully rendered Markdown previews

[![macOS 12+](https://img.shields.io/badge/macOS-12%2B-blue)](https://www.apple.com/macos/)
[![Swift](https://img.shields.io/badge/Swift-5-orange)](https://swift.org)
[![CI](https://github.com/tukuyomil032/glance/actions/workflows/ci.yml/badge.svg)](https://github.com/tukuyomil032/glance/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-lightgrey)](LICENSE)

</div>

## Overview

glance is a macOS Quick Look extension that renders `.md` files with rich formatting when you press Space in Finder. Instead of seeing raw Markdown text, you get beautifully formatted content — headings, lists, tables, code blocks, and more — instantly.

## Features

- Renders headings, emphasis, lists, blockquotes, tables, and fenced code blocks
- Automatic dark mode support via CSS `prefers-color-scheme`
- Configurable font size (14 / 16 / 18 px) and content max width (500–900 px)
- Supports `.md`, `.markdown`, `.mdown`, and `.mkd` file extensions
- No external dependencies — custom renderer with zero third-party packages

## Installation

**Requirements:** macOS 12.0 or later

Download the latest DMG from [GitHub Releases](https://github.com/tukuyomil032/glance/releases):

| Build | Architecture |
|-------|-------------|
| `glance-arm64.dmg` | Apple Silicon |
| `glance-x86_64.dmg` | Intel |
| `glance-universal.dmg` | Universal |

> [!TIP]
> The universal build runs natively on both Apple Silicon and Intel Macs. When in doubt, download it.

## Setup

1. Open the DMG and drag **glance** to your Applications folder.
2. Launch glance at least once to register the extension.
3. Go to **System Settings → Privacy & Security → Extensions → Quick Look**.
4. Enable **glance**.

After enabling the extension, reset the Quick Look cache so Finder picks it up:

```bash
qlmanage -r
```

> [!IMPORTANT]
> The extension must be enabled in System Settings before Quick Look previews will work. If previews stop working after a system update, re-enable the extension and run `qlmanage -r` again.

## Usage

1. Open Finder and navigate to any Markdown file.
2. Select the file and press **Space** to open Quick Look.
3. glance renders the file with full formatting automatically.

To adjust settings, open the app and press **Cmd+,** (or go to **glance → Settings**). You can change:

- **Font size** — 14, 16, or 18 px
- **Max content width** — 500 to 900 px

Settings are shared between the main app and the Quick Look extension via App Group.

## Supported File Types

| Extension | UTType |
|-----------|--------|
| `.md` | `net.daringfireball.markdown` |
| `.markdown` | `net.ia.markdown` |
| `.mdown` | `public.markdown` |
| `.mkd` | `public.markdown` |

## Build from Source

**Prerequisites:** Xcode 14+, macOS 12+

```bash
# Clone the repository
git clone https://github.com/tukuyomil032/glance.git
cd glance

# Build
xcodebuild -project glance.xcodeproj -scheme glance -configuration Debug build

# Run tests
xcodebuild -project glance.xcodeproj -scheme glance -configuration Debug test

# Test Quick Look preview directly
qlmanage -r && qlmanage -p path/to/file.md
```

> [!NOTE]
> After building, you may need to manually load the extension from the built `.app` bundle and enable it in System Settings.

## Tech Stack

| Component | Technology |
|-----------|-----------|
| Language | Swift |
| UI | SwiftUI + WKWebView |
| Markdown | Custom renderer (no dependencies) |
| Build | Xcode |
| CI/CD | GitHub Actions |
| Distribution | DMG (arm64 / x86_64 / universal) |
