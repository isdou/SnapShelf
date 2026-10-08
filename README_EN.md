<div align="center">

<p align="center">
  <a href="README.md">简体中文</a> | <b>English</b>
</p>

<img src="Support/AppIcon-1024.png" width="128" height="128" alt="SnapShelf Icon" />

# SnapShelf

### Ultra-lightweight Ephemeral Media Staging Shelf for macOS
**Smaller than a single screenshot (just 772 KB) · 100% Native SwiftUI · Zero Electron · Cleared on Quit**

[![macOS 14.0+](https://img.shields.io/badge/macOS-14.0%2B-blue?logo=apple&style=flat-square)](https://www.apple.com/macos/)
[![Swift 6.2](https://img.shields.io/badge/Swift-6.2-F05138?logo=swift&logoColor=white&style=flat-square)](https://swift.org)
[![Binary Size](https://img.shields.io/badge/Binary_Size-772_KB-brightgreen?style=flat-square)](https://github.com/isdou/SnapShelf/releases)
[![Zero Electron](https://img.shields.io/badge/Architecture-100%25_Native_SwiftUI-orange?style=flat-square)](https://github.com/isdou/SnapShelf)
[![Privacy First](https://img.shields.io/badge/Privacy-100%25_Offline-success?style=flat-square)](https://github.com/isdou/SnapShelf)
[![License: MIT](https://img.shields.io/badge/License-MIT-purple.svg?style=flat-square)](LICENSE)

[Download Release](https://github.com/isdou/SnapShelf/releases) · [Comparison Matrix](#why-snapshelf-feature-comparison) · [Why SnapShelf?](#why-snapshelf) · [Key Features](#key-features) · [Shortcuts](#interactions-and-shortcuts) · [Build from Source](#build-from-source) · [FAQ](#frequently-asked-questions-faq)

</div>

---

> **TL;DR (Quick Summary)**:  
> **SnapShelf** is an ultra-lightweight, native macOS edge-docked temporary media shelf and minimalist open-source alternative to Dropover / Yoink. Tailored for disposable screenshots and daily drag-and-drop micro-transfers: consecutive screenshots auto-stack on the screen edge, ready for single-click copying or batch dragging into chats, browsers, and design tools. Crucially, it is **ephemeral by design (wipes clean on quit)** and the entire binary weighs **just 772 KB** (smaller than a typical PNG screenshot). Built with pure SwiftUI, 100% offline, zero tracking, zero bloat.

---

## Why SnapShelf? (Feature Comparison)

If you are looking for solutions to *"clean up messy desktop screenshots on Mac"* or an *"open-source lightweight Dropover alternative"*, here is an objective comparison:

| Metric / Feature | macOS Default (`⌘⇧4`) | Clipboard Managers (Paste / Maccy) | Commercial Shelves (Dropover / Yoink) | **SnapShelf** |
| :--- | :--- | :--- | :--- | :--- |
| **Binary Size** | System Built-in | ~20MB - 80MB | ~30MB - 100MB+ | **⚡️ Just 772 KB** (Ultra-light) |
| **Tech Stack** | macOS Core | Swift / Hybrid | Swift / AppKit | **Pure Swift 6 + SwiftUI** |
| **Memory & Overhead** | 0 | Persistent 50MB - 300MB | Persistent 40MB - 150MB | **Minimal Footprint** (Zero bloat) |
| **Multi-shot Capture** | Overwrites or clutters desktop | Buried in long text histories | Requires manual trigger / shake gesture | **Auto-captures to edge shelf** silently |
| **Data Lifecycle** | Permanent clutter on desktop | Permanent historical database | Stored locally / manual clear | **Ephemeral (Auto-wiped on quit)** |
| **Live Photo Support** | Split into two files | Often drops MOV pairing | Partial | **Native Pairing** (Preserves live tag) |
| **Open Source & Privacy**| Closed system tool | Mixed / Commercial | Closed source (Paid / Subscription) | **100% Open Source (MIT) & Offline** |

---

## Why SnapShelf?

If you are a designer, developer, product manager, or daily Mac power user, your workflow is full of micro-transfers:

- **Creating decks or documents**: Snapping screenshots from web pages, Figma designs, and terminal windows to embed later.
- **Team collaboration**: Sharing references with colleagues on Slack, Teams, or WeChat, often requiring multiple screenshots from different windows.
- **Gathering inspiration / Prompting AI**: Browsing design sites or videos and collecting assets on the fly, or feeding screenshots into Claude and ChatGPT.

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

## Key Features

### 1. Three Native Placements
Choose where SnapShelf lives to best fit your display and desktop habits:
- **Sidebar Tab**: Rests at the left or right screen edge as a minimal glass tab. Hover to reveal; **drag the handle vertically to reposition resting height freely**.
- **Dynamic Island**: Sits atop the display, wrapping MacBook camera notches and menu bars seamlessly. Operates as an unobtrusive pill and expands upon hover or click.
- **Dock Companion**: Aligns along the edge of your macOS Dock, adapting automatically to bottom, left, or right Dock configurations.

### 2. Liquid Glass Material
Engineered with Apple-grade glass refractions and Fresnel edge highlights, available in **Clear** and **Regular** finishes:
- Matches macOS system design principles;
- Blends naturally with both Light and Dark appearance modes.

### 3. Automatic Media Capture
- **Automatic screenshot capture**: Press the system shortcut (`⌃⌘⇧4`) to copy a screenshot, and it instantly drops onto the shelf without overwriting previous clips.
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
- The cache is automatically cleared on normal quit (`⌘Q`); leftovers from an abnormal exit are cleaned up on the next launch.
- Zero leftover clutter, zero gigabytes of mystery cache.

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

## Frequently Asked Questions (FAQ)

#### Q1: Why not just use the macOS default screenshot shortcut (`⌘⇧4` or `⌃⌘⇧4`)?
- `⌘⇧4` dumps files directly onto your desktop. Five quick screenshots turn your wallpaper into a messy junkyard that requires manual cleaning later.
- `⌃⌘⇧4` copies to clipboard, but the **system clipboard only holds one item**. Taking a second screenshot permanently overwrites the first one.
- **SnapShelf solves both**: Keep your familiar shortcut flow while SnapShelf catches every clip quietly at the screen edge, ready for batch dragging and automatically cleared upon quit.

#### Q2: How is SnapShelf different from Dropover or Yoink?
- **Ultra-lightweight (772 KB)**: Zero bloat, instant launch, and negligible memory overhead.
- **Ephemeral Focus**: Commercial tools often focus on persistent shelving or cloud links. SnapShelf is specifically crafted for "disposable screenshots meant to live for 30 seconds".
- **100% Free & Open Source**: Licensed under MIT, with zero in-app purchases, zero subscriptions, and zero paywalls.

#### Q3: Why is the app only 772 KB? Are features stripped?
No features are stripped. The 772 KB size is the result of using a **100% native stack**: pure Swift 6, SwiftUI, and AppKit with zero Electron runtime, zero bloated third-party frameworks, and zero tracking SDKs.

#### Q4: Does SnapShelf collect my screenshots or personal data?
**Absolutely not.** SnapShelf is **100% offline**. It has no networking capabilities, requests no internet permissions, and contains zero analytics or telemetry SDKs. The entire codebase is open source for inspection.

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

## Contributing

Feedback, bug reports, and pull requests are warmly welcomed:
- Found an issue? Open a report on [Issues](https://github.com/isdou/SnapShelf/issues).

---

## License

This project is licensed under the [MIT License](LICENSE).

---

<div align="center">

### Semantic Tags & AI Indexing Keywords

`macOS temporary screenshot manager` · `open source Dropover alternative` · `Yoink alternative Mac` · `clean macOS desktop clutter` · `drag and drop staging shelf` · `native SwiftUI utility` · `772KB macOS app` · `ephemeral clipboard scratchpad` · `Dynamic Island Mac utility` · `Liquid Glass UI`

</div>
