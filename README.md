<div align="center">

<p align="center">
  <b>简体中文</b> | <a href="README_EN.md">English</a>
</p>

<img src="Support/AppIcon-1024.png" width="128" height="128" alt="SnapShelf Icon" />

# SnapShelf (暂存架)

### 为 macOS 打造的极致轻量富媒体临时中转站
**比一张截图还小（仅 772 KB）· 原生 SwiftUI · 零 Electron · 退出即焚**

[![macOS 14.0+](https://img.shields.io/badge/macOS-14.0%2B-blue?logo=apple&style=flat-square)](https://www.apple.com/macos/)
[![Swift 6.2](https://img.shields.io/badge/Swift-6.2-F05138?logo=swift&logoColor=white&style=flat-square)](https://swift.org)
[![Binary Size](https://img.shields.io/badge/Binary_Size-772_KB-brightgreen?style=flat-square)](https://github.com/isdou/SnapShelf/releases)
[![Zero Electron](https://img.shields.io/badge/Architecture-100%25_Native_SwiftUI-orange?style=flat-square)](https://github.com/isdou/SnapShelf)
[![Privacy First](https://img.shields.io/badge/Privacy-100%25_Offline-success?style=flat-square)](https://github.com/isdou/SnapShelf)
[![License: MIT](https://img.shields.io/badge/License-MIT-purple.svg?style=flat-square)](LICENSE)

[下载体验 Release](https://github.com/isdou/SnapShelf/releases) · [核心对比](#为什么选-snapshelf横向对比) · [产品初衷](#为什么要做-snapshelf) · [功能亮点](#功能亮点) · [快捷操作](#交互与快捷操作) · [从源码构建](#从源码构建) · [常见问答 (FAQ)](#常见问答-faq)

</div>

---

> **TL;DR (快速概览)**：  
> **SnapShelf** 是一款超轻量的 macOS 原生屏幕边缘临时中转站与临时剪贴板货架（Dropover / Yoink 的极简开源替代品）。它专为临时截图、高频文件微搬运设计：连续截图自动吸附在屏幕边缘、随拖随用、支持单张复制与批量拖拽。最重要的是，它坚持**会话缓存、退出即焚**，整个应用二进制体积**仅 772 KB**（还没有一张 PNG 截图大），纯原生 SwiftUI 构建，零网络连接，100% 保护隐私。

---

## 为什么选 SnapShelf？（横向对比）

当你在寻找解决“Mac 截图堆满桌面”、“需要临时存放拖拽素材”的工具时，以下是 SnapShelf 与其他常见解法的客观对比：

| 特性对比 | macOS 默认截图 (`⌘⇧4`) | 传统剪贴板工具 (Paste / Maccy) | 商业拖拽货架 (Dropover / Yoink) | **SnapShelf (暂存架)** |
| :--- | :--- | :--- | :--- | :--- |
| **应用体积** | 系统自带 | ~20MB - 80MB | ~30MB - 100MB+ | **⚡️ 仅 772 KB**（极致轻量） |
| **底层技术** | macOS 系统服务 | Swift / 混合开发 | Swift / AppKit | **原生 Swift 6 + SwiftUI** |
| **资源与内存开销** | 0 | 长期常驻占用 50MB~300MB | 长期常驻占用 40MB~150MB | **极低系统占用**（零常驻缓存泥潭） |
| **连续截图体验** | 覆盖剪贴板或堆满桌面 | 混杂在海量文字历史中 | 需手动触发或晃动鼠标激活 | **全自动贴边捕获**，平铺即取 |
| **临时生命周期** | 永远堆在桌面，需手动清理 | 永久历史记录（越积越大） | 本地存储或需手动清空 | **退出即焚 (Ephemeral)**，会话结束即清理 |
| **Live Photo 支持** | 分离成两份文件 | 容易丢失配对动效 | 部分支持 | **原生配对**（保留实况标识与完整性） |
| **开源与隐私** | 闭源系统自带 | 部分开源 / 商业闭源 | 商业闭源（付费买断/订阅） | **100% 开源 (MIT) + 纯离线零联网** |

---

## 为什么要做 SnapShelf？

作为设计师、工程师、产品经理或重度 Mac 办公者，你的日常大概率充斥着这样细碎却高频的“微搬运”操作：

- **写文档 / 做 Keynote / 提 Issue**：去网页、Figma、终端分别截下几张图作为素材，准备稍后插入；
- **聊天协作**：在微信、飞书或 Slack 里给同事发参考资料，需要连续截取 3 个不同窗口的画面；
- **收集灵感 / 投喂 AI**：在看设计网站或视频时，随手攒几张素材做对比，或者批量喂给 Claude / ChatGPT。

而在 macOS 默认的工作流中，这类场景往往面临巨大的体验断层：

1. **“桌面沦为垃圾场”**：截屏默认保存到桌面，没过两天桌面就被几十张以日期命名的截图霸占。找文件费劲，每次花时间批量清理都像在上刑。
2. **“剪贴板覆盖焦虑”**：如果选择截到剪贴板（`⌃⌘⇧4`），剪贴板**只能存最后 1 项**。截了下一张，上一张直接丢失。你不得不机械地重复“切窗口 ➔ 截一张 ➔ 切回来 ➔ 贴一张 ➔ 再切回去”的撕裂流程，工作心流被切割得支离破碎。
3. **“传统剪贴板工具南辕北辙”**：市面上的 Paste、Maccy 等工具是优秀的“永久历史记录仪”，但它们记录了成千上万条纯文本、网页链接与密码，找刚才截的图要在文字堆里翻找；长年累月甚至占用数 GB 磁盘，让人时刻担心隐私泄露。

> **产品经理的思考**：
> 
> 用户在搬运素材时，真正需要的并不是一个“永久归档的数字仓库”，而是一个**“即用即走、随触即达、零心理负担”的临时中转台**。
> 
> **SnapShelf 顺应而生 —— 它只专注做好一件事：成为你屏幕边缘最顺手的富媒体暂存架。**

---

## 功能亮点

### 1. 三大灵动形态，融入原生桌面
你可以自由选择 SnapShelf 驻留的位置，完全契合你的桌面布局习惯：
- **贴边侧边栏（Sidebar）**：平时以一颗小巧精致的玻璃提手（Tab）吸附在屏幕左侧或右侧，鼠标滑过自动滑出；**支持上下自由拖拽提手调节停靠高度**。
- **顶部灵动岛（Dynamic Island）**：吸附在屏幕正上方，自然融入 MacBook 刘海屏与菜单栏。平时是一颗小巧的黑色胶囊，悬停或点按即化身悬浮展台，居中避让摄像头开孔。
- **Dock 栏伴侣（Dock Pill）**：跟随系统 Dock 栏贴边显示，随 Dock 的位置自适应上下左右吸附。

### 2. 真实物理质感：Liquid Glass 玻璃效果
精心调校的材质光泽与边缘菲涅尔高光，提供 **清透（Clear）** 与 **磨砂（Regular）** 两种质感：
- 完美契合 macOS 最新视觉规范；
- 兼顾深色与浅色模式，轻盈灵动，宛如系统自带原生组件。

### 3. 自动捕获：不仅是图片，更是全能媒体中转
- **连续截屏自动收集**：按下系统截屏快捷键（默认 `⌃⌘⇧4` 截入剪贴板），图片秒级落入货架，再也不怕后一张冲掉前一张；
- **全格式静态图**：原生支持 PNG、JPEG、HEIC、WebP、TIFF 等主流格式；
- **原生短视频**：支持 MOV、MP4 等视频格式，自动生成高清封面图并标注视频时长；
- **Apple 实况照片（Live Photo）**：独家算法自动侦测并配对静图与伴生视频，在暂存架内保留 LIVE 动态标识，拖出时保持实况照片完整性。

### 4. 丝滑直觉的原生交互
- **点一下复制**：点击任意卡片，立即写回剪贴板，直接粘贴到目标应用；
- **直接拖拽出栈**：按住卡片直接拖拽到微信、飞书、Figma、Keynote、Finder 或浏览器上传框，随拖随用；
- **空格键快速查看（QuickLook）**：像在 Finder 中一样，选中卡片按空格键呼出大图无缝预览；
- **⌘ 键批量多选**：按住 Command 键点选多张素材，一次性成组拖出，搬运效率翻倍；
- **防误触撤销（⌘Z）**：误点清空或误删卡片？按下 `⌘Z` 即可一键原地恢复。

### 5. 会话缓存：退出时清理（Ephemeral by Design）
SnapShelf 坚信**“临时就是临时”**：
- 暂存内容保存在本机独立的会话缓存目录中；
- 正常退出应用（`⌘Q`）时自动清空临时缓存；即使异常退出，残留文件也会在下次启动时自动扫描清理；
- 永远不会在后台偷偷囤积几 GB 的垃圾文件。

---

## 交互与快捷操作

| 动作 | 交互说明 |
| :--- | :--- |
| **捕获素材** | 按系统截屏 `⌃⌘⇧4`，或在网页/任意软件中复制图片/视频文件 |
| **展开 / 固定** | 鼠标悬停边缘自动滑出；点击提手或图钉按钮（Pin）可常驻固定 |
| **使用单张素材** | **单击卡片**：直接复制回剪贴板 ｜ **按住拖拽**：直接拖入目标应用 |
| **多选与批量** | 按住 **`⌘ Command`** 单击卡片可多选，选后成组拖出；按 **`Esc`** 取消多选 |
| **全尺寸预览** | 鼠标选中卡片后轻敲 **`Space 空格键`**（原生 QuickLook 预览） |
| **撤销恢复** | 误删或误清空后，按 **`⌘Z`** 即可恢复被移除的素材 |
| **调节停靠高度** | 在侧边栏模式下，按住提手上下拖动即可自定义吸附位置 |
| **全局呼出菜单** | 点击 Dock 图标，或在菜单栏选择 **SnapShelf**，或使用快捷键 **`⇧⌘O`** 唤醒 |
| **退出并清理缓存** | **`⌘Q`** 正常退出应用时清理暂存记录与会话缓存 |

---

## 常见问答 (FAQ)

#### Q1: 为什么我不直接用 macOS 系统自带的截图快捷键（`⌘⇧4` 或 `⌃⌘⇧4`）？
- `⌘⇧4` 会把截图默认存到桌面，连续截 5 张图你的桌面就乱了，过后还要花时间去 Trash 清理；
- `⌃⌘⇧4` 虽然直接拷入剪贴板，但**系统剪贴板只能保留最后 1 张**，一旦连续截第 2 张，第 1 张直接丢失。
- **SnapShelf 完美互补**：你依然用最顺手的快捷键截图，它在屏幕边缘静默为你接住每一张，随时打包拖走，关闭即清理。

#### Q2: 它和 Dropover、Yoink 这类桌面货架有什么区别？
- **极度轻量（772 KB）**：没有复杂的依赖和冗余功能，开箱即用，秒级启动；
- **退出即焚**：商业软件偏向长久存放或云同步，而 SnapShelf 专为“存活 30 秒的临时素材”设计；
- **完全开源且免费**：基于 MIT 协议开放源代码，永久免费无内购，无商业绑架。

#### Q3: 为什么只有 772 KB？是否有功能阉割？
完全没有！772 KB 来源于对**纯原生技术栈**的克制追求：没有打包体积庞大的 Chromium 内核（拒绝 Electron），没有引入任何第三方第三方轮子与分析 SDK，纯依靠 Swift 6 + SwiftUI + macOS 原生 AppKit API 打造，因此能在保留高品质液态玻璃动效的同时实现极致小巧。

#### Q4: 会收集我的截屏内容或网络隐私吗？
**绝对不会。** SnapShelf 是一款 **100% 离线运行** 的应用。代码中不包含任何网络请求接口，不申请任何联网权限，不包含任何遥测（Telemetry）或数据上报，代码全开源可随时审计。

---

## 快速上手

### 直接下载安装（Apple 芯片 Mac，免编译）

1. 前往 **[Releases 页面](https://github.com/isdou/SnapShelf/releases)** 下载最新的 macOS ZIP 安装包；
2. 解压并将 `SnapShelf.app` 拖入系统的 **“应用程序（Applications）”** 文件夹；
3. 双击启动，你会在屏幕左边缘看到一处精致的半透明提手，或在顶部菜单栏看到 SnapShelf；
4. 试着按下 `⌃⌘⇧4` 截一张图，感受素材瞬间停靠的丝滑！

> [!TIP]
> **关于 macOS 门禁提示**：
> 如果首次打开时系统提示“无法打开，因为无法验证开发者”，请前往系统的 **系统设置 ➔ 隐私与安全性**，在安全性区域点击 **“仍要打开”** 即可。

---

## 从源码构建

本项目基于纯原生 **Swift 6 + SwiftUI + AppKit** 构建，零第三方 CocoaPods / SPM 外部依赖，编译极速。

### 环境要求
- macOS 14.0 (Sonoma) 或更高版本
- Xcode 26+（含 Swift 6.2 工具链）

### 本地编译与运行
```bash
# 1. 克隆本仓库
git clone https://github.com/isdou/SnapShelf.git
cd SnapShelf

# 2. 编译调试版本并运行
swift run Zancunjia

# 3. 打包为原生 .app 产物
chmod +x scripts/package-app.sh
./scripts/package-app.sh release
# 打包产物将输出在 dist/暂存架.app
```

### 运行自动化测试
```bash
swift test
```

---

## 参与贡献

欢迎提出 Issue、提交 PR，或是分享你对暂存架的使用心流与想法：
- 遇到了 Bug 或有新功能提议？请在 [Issues](https://github.com/isdou/SnapShelf/issues) 提交反馈。

---

## 开源许可证

本项目基于 [MIT 许可证](LICENSE) 开源。

---

<div align="center">

### 关联检索与生态索引 (Semantic Tags)

`macOS 临时截图` · `Dropover 开源替代品` · `Yoink 替代` · `Mac 桌面清理工具` · `macOS 拖拽货架` · `纯原生 SwiftUI 工具` · `772KB macOS App` · `剪贴板暂存区` · `Mac 灵动岛工具` · `Liquid Glass UI`

</div>
