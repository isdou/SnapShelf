<div align="center">

<p align="center">
  <a href="README.md">简体中文</a> | <b>English</b>
</p>

<img src="Support/AppIcon-1024.png" width="128" height="128" alt="SnapShelf Icon" />

# SnapShelf

### A fluid and lightweight media shelf for macOS
**Say goodbye to desktop screenshot clutter. Reclaim your focus, copy, and drag workflow.**

[![macOS 14.0+](https://img.shields.io/badge/macOS-14.0%2B-blue?logo=apple&style=flat-square)](https://www.apple.com/macos/)
[![Swift 6.2](https://img.shields.io/badge/Swift-6.2-F05138?logo=swift&logoColor=white&style=flat-square)](https://swift.org)
[![Privacy First](https://img.shields.io/badge/Privacy-100%25%20Offline-success?style=flat-square)](https://github.com/isdou/SnapShelf)
[![License: MIT](https://img.shields.io/badge/License-MIT-purple.svg?style=flat-square)](LICENSE)

[Download Release](https://github.com/isdou/SnapShelf/releases) · [Why SnapShelf?](#why-snapshelf) · [Problems Solved](#what-problems-does-it-solve) · [Key Features](#key-features) · [Shortcuts](#interactions-and-shortcuts) · [Build from Source](#build-from-source)

</div>

---

## Why SnapShelf?

If you are a designer, developer, product manager, or daily Mac power user, your workflow is full of micro-transfers:

- **Creating decks or documents**: Snapping screenshots from web pages, Figma designs, and terminal windows to embed later.
- **Team collaboration**: Sharing references with colleagues on Slack or WeChat, often requiring multiple screenshots from different windows.
- **Gathering inspiration**: Browsing design sites or videos and collecting assets on the fly.

Yet macOS's default workflow introduces severe friction:

1. **"Desktop as a junkyard"**: Screenshots save to the desktop by default. In just a few days, your wallpaper is buried under dozens of generic `Screenshot 2026-xx-xx.png` files. Finding the right file is frustrating, and mass cleanup feels like a chore.
2. **"Clipboard overwrite anxiety"**: If you copy screenshots directly to the clipboard (`⌃⌘⇧4`), the system clipboard only holds **one item at a time**. Taking the next shot instantly destroys the previous one. You are forced into an exhausting loop of: *switch window ➔ capture ➔ switch back ➔ paste ➔ switch again*, shattering your focus and flow state.
3. **"Traditional clipboard managers miss the mark"**: Existing clipboard utilities often act as permanent historical archives. They record thousands of text snippets, web links, and sensitive passwords. Locating a recent image requires digging through mountains of text, while persistent database storage accumulates gigabytes of disk usage and raises privacy concerns.

> **Product Insight**:
>
> When transferring media between apps, users don't need another permanent digital warehouse—they need an **ephemeral, friction-free staging shelf that lives on the edge of their screen**.
>
> **SnapShelf was born out of this insight. It does one thing exceptionally well: serving as the most effortless temporary staging shelf for your media.**

---

## What Problems Does It Solve?

| Scenario | Traditional Workflow | SnapShelf's Solution |
| :--- | :--- | :--- |
| **Batch screenshot collection** | Cluttering the desktop or toggling between windows repeatedly | **Silent, automatic capture**: Successive screenshots and copied media line up on the shelf automatically |
| **Temporary file buildup** | Regularly cleaning hundreds of discarded screenshots into the Trash | **Session cache**: Media stays in a local cache that is cleared on normal quit; leftovers from an abnormal exit are cleared on the next launch |
| **Workspace obstruction** | Heavy floating panels obstructing current tasks | **Three native placements**: Sidebar tab, Dynamic Island notch pill, and Dock companion |
| **Live Photos and videos** | Dropping or copying Live Photos often loses paired video data | **Full native support**: Automatically pairs Live Photo image + MOV pairs and extracts video durations |
| **Privacy concerns** | Cloud-synced clipboard tools can upload sensitive data | **100% offline**: Zero network permissions, zero third-party telemetry, 100% local |

---

## Key Features

### 1. Three Native Placements
Choose where SnapShelf lives to best fit your display and desktop habits:
- **Sidebar Tab**: Rests at the left or right screen edge as a minimal glass tab. Hover to reveal; **drag the handle vertically to reposition it freely**.
- **Dynamic Island**: Sits atop the display, wrapping MacBook camera notches and menu bars seamlessly. Operates as an unobtrusive pill and expands upon hover or click.
- **Dock Companion**: Aligns along the edge of your macOS Dock, adapting automatically to bottom, left, or right Dock configurations.

### 2. Liquid Glass Material
Engineered with Apple-grade glass refractions and Fresnel edge highlights, available in **Clear** and **Regular** finishes:
- Matches macOS system design principles;
- Blends naturally with both Light and Dark appearance modes.

### 3. Automatic Media Capture
- **Automatic screenshot capture**: Press the system shortcut (`⌃⌘⇧4`) to copy a screenshot, and it instantly drops onto the shelf.
- **Comprehensive image support**: Native handling of PNG, JPEG, HEIC, WebP, and TIFF.
- **Native short video handling**: Supports MOV and MP4, generating high-resolution poster frames and displaying duration indicators.
- **Apple Live Photos**: Proprietary detection and pairing for static images and companion video files, maintaining the LIVE tag and asset integrity when dragged out.

### 4. Fluid, Direct Manipulation
- **Click to copy**: Click any item to copy it back to your system clipboard for immediate pasting.
- **Drag directly into targets**: Drag items directly into Slack, Figma, Keynote, Finder, or web upload zones.
- **QuickLook preview**: Select any item and press the **Spacebar** for full-size inspection.
- **Command-click multi-selection**: Hold Command and click items to batch-drag multiple assets together.
- **Undo safety net (⌘Z)**: Accidental removals or clears can be restored instantly with `⌘Z`.

### 5. Ephemeral by Design
SnapShelf is built around the principle that **temporary means temporary**:
- Items are stored in an isolated local session cache.
- The cache is cleared on normal quit (`⌘Q`); files left by an abnormal exit are cleared on the next launch.
- Cleanup uses normal file deletion, not secure erasure.

---

## Interactions and Shortcuts

| Action | Instruction |
| :--- | :--- |
| **Capture media** | Use system shortcut `⌃⌘⇧4`, or copy images/videos in browser and Finder |
| **Expand / Pin** | Hover near screen edge to expand; click tab or pin icon to keep open |
| **Use an item** | **Click**: Copies to clipboard ｜ **Drag**: Drops directly into target app |
| **Batch selection** | Hold **`⌘ Command`** and click items to select multiple; press **`Esc`** to clear selection |
| **QuickLook preview** | Select a card and press **`Space`** for full-size QuickLook |
| **Undo action** | Press **`⌘Z`** to undo card removal or accidental clear |
| **Adjust position** | In sidebar mode, drag the handle up or down to set resting height |
| **Global menu** | Click Dock icon, choose menu bar item, or press **`⇧⌘O`** to summon |
| **Clear on quit** | Press **`⌘Q`** to exit and clear staged items and the session cache |

---

## Quick Start

### Download and Install Prebuilt Binary (Apple Silicon Mac)

1. Go to the **[Releases page](https://github.com/isdou/SnapShelf/releases)** and download the latest macOS ZIP;
2. Unzip the archive and move `SnapShelf.app` to your **Applications** folder;
3. Launch the app. You will see a subtle translucent tab on your screen edge or in the menu bar;
4. Press `⌃⌘⇧4` to take a screenshot and watch it land smoothly on the shelf!

> [!TIP]
> **macOS Gatekeeper Note**:
> If macOS warns that the app cannot be opened because the developer cannot be verified, open **System Settings ➔ Privacy & Security**, scroll down to the Security section, and click **"Open Anyway"**.

---

## Build from Source

SnapShelf is written in pure **Swift 6 + SwiftUI + AppKit** without external CocoaPods or third-party SPM packages.

### Requirements
- macOS 14.0 (Sonoma) or later
- Xcode 26+ (Swift 6.2+) toolchain

### Build and Run Locally
```bash
# 1. Clone the repository
git clone https://github.com/isdou/SnapShelf.git
cd SnapShelf

# 2. Build and run debug version
swift run Zancunjia

# 3. Package as standalone .app bundle
chmod +x scripts/package-app.sh
./scripts/package-app.sh release
# The output bundle will be generated at dist/暂存架.app
```

### Run Tests
```bash
swift test
```

---

## Privacy and Security

- **100% Offline**: SnapShelf requests zero network permissions and contains no networking code or tracking SDKs.
- **Clipboard Media**: Imports images and videos, not plain text. Sensitive content inside an image or video is cached locally like any other media.
- **Ephemeral Lifecycle**: The session cache is deleted on normal quit, and leftovers from an abnormal exit are cleared on the next launch. Normal file deletion is not secure erasure.

---

## Contributing

Feedback, bug reports, and pull requests are warmly welcomed:
- Found an issue? Open a report on [Issues](https://github.com/isdou/SnapShelf/issues).

---

## License

This project is licensed under the [MIT License](LICENSE).
