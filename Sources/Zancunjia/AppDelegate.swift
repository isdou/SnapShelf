import AppKit
import Darwin
import os
import ZancunjiaCore

/// Lock before touching the cache so another process cannot erase active files.
enum SessionOwnership {
    private struct State {
        var owned = false
        var descriptor: Int32 = -1
    }

    private static let lock = OSAllocatedUnfairLock(initialState: State())

    static func claim() throws -> Bool {
        let lockFile = SessionCache.root.appendingPathExtension("lock")
        try FileManager.default.createDirectory(
            at: lockFile.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        return try lock.withLock { state in
            if state.owned { return true }
            let descriptor = Darwin.open(lockFile.path, O_CREAT | O_RDWR | O_EXLOCK | O_NONBLOCK, S_IRUSR | S_IWUSR)
            guard descriptor >= 0 else {
                if errno == EWOULDBLOCK { return false }
                throw NSError(domain: NSPOSIXErrorDomain, code: Int(errno))
            }
            state.descriptor = descriptor
            state.owned = true
            return true
        }
    }

    /// Clean up once, while keeping the OS lock held until process exit.
    static func relinquish() -> Bool {
        lock.withLock { state in
            let wasOwned = state.owned
            state.owned = false
            return wasOwned
        }
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    static let shared = AppDelegate()

    private var controller: ShelfPanelController?
    private var monitor: ClipboardMonitor?
    private var model: ShelfModel?
    private let settings = ShelfSettings()
    private var edgeItem: NSMenuItem?
    private var captureItem: NSMenuItem?
    private var undoItem: NSMenuItem?
    private var terminationSources: [DispatchSourceSignal] = []

    func applicationWillFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        if reactivateExistingInstance() {
            NSApp.terminate(nil)
            return
        }

        installMainMenu()
        ProcessInfo.processInfo.disableSuddenTermination()
        ProcessInfo.processInfo.disableAutomaticTermination("SnapShelf 里有临时图片")

        do {
            guard try SessionOwnership.claim() else {
                NSApp.terminate(nil)
                return
            }
            let model = ShelfModel(store: try SessionStore.launchSession())
            self.model = model
            installSignalCleanup()
            let controller = ShelfPanelController(model: model, settings: settings)
            controller.start(showExpanded: CommandLine.arguments.contains("--show"))
            self.controller = controller
            let monitor = ClipboardMonitor(model: model)
            monitor.start(enabled: settings.captureEnabled)
            self.monitor = monitor
        } catch {
            ShelfLog.main.error("启动失败 \(error.localizedDescription, privacy: .public)")
            let alert = NSAlert()
            alert.messageText = "SnapShelf 打不开"
            alert.informativeText = error.localizedDescription
            alert.runModal()
            NSApp.terminate(nil)
        }
    }

    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        discardSession()
        return .terminateNow
    }

    func applicationWillTerminate(_ notification: Notification) {
        discardSession()
    }

    /// ⌘Q and the Dock run this on the main thread. SIGTERM never enters AppKit,
    /// so the signal source below deletes the same cache and then exits.
    private func discardSession() {
        guard SessionOwnership.relinquish() else { return }
        monitor?.stop()
        model?.shutdown()
        SessionCache.discardAll()
    }

    private func installSignalCleanup() {
        for sig in [SIGTERM, SIGINT] {
            signal(sig, SIG_IGN)
            let source = DispatchSource.makeSignalSource(signal: sig, queue: .main)
            source.setEventHandler {
                if SessionOwnership.relinquish() {
                    SessionCache.discardAll()
                }
                exit(0)
            }
            source.resume()
            terminationSources.append(source)
        }
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        controller?.pinShelf(at: NSEvent.mouseLocation)
        return false
    }

    func applicationDockMenu(_ sender: NSApplication) -> NSMenu? {
        makeActionMenu()
    }

    func menuNeedsUpdate(_ menu: NSMenu) {
        edgeItem?.title = edgeTitle
        edgeItem?.isHidden = settings.placement == .island
        captureItem?.state = settings.captureEnabled ? .on : .off
        undoItem?.isEnabled = model?.canUndo == true
        undoItem?.title = model?.undoActionName.isEmpty == false
            ? "撤销\(model?.undoActionName ?? "")"
            : "撤销"
        refreshPlacementChecks(in: menu)
    }

    private func refreshPlacementChecks(in menu: NSMenu) {
        for item in menu.items {
            if let raw = item.representedObject as? String, let placement = ShelfPlacement(rawValue: raw) {
                item.state = settings.placement == placement ? .on : .off
            }
            if let raw = item.representedObject as? String, let appearance = ShelfAppearance(rawValue: raw) {
                item.state = settings.appearance == appearance ? .on : .off
            }
            if let submenu = item.submenu {
                refreshPlacementChecks(in: submenu)
            }
        }
    }

    func makeActionMenu() -> NSMenu {
        let menu = NSMenu()
        menu.delegate = self
        addActions(to: menu, clearShortcut: "")
        return menu
    }

    @objc private func showAbout(_ sender: Any?) {
        NSApp.activate()
        let credits = NSAttributedString(
            string: "自动收集剪贴板里的图片和视频，只暂存在这台 Mac。\n鼠标放上去展开，点一下固定。退出后所有暂存内容都会清空。",
            attributes: [
                .font: NSFont.systemFont(ofSize: 11),
                .foregroundColor: NSColor.secondaryLabelColor,
            ]
        )
        NSApp.orderFrontStandardAboutPanel(options: [
            .applicationName: "SnapShelf",
            .credits: credits,
        ])
    }

    @objc private func showShelf() {
        controller?.pinShelf(at: NSEvent.mouseLocation)
    }

    @objc private func toggleEdge() {
        controller?.toggleEdge()
        edgeItem?.title = edgeTitle
    }

    @objc private func choosePlacement(_ sender: NSMenuItem) {
        guard let raw = sender.representedObject as? String,
              let placement = ShelfPlacement(rawValue: raw) else { return }
        controller?.setPlacement(placement)
        edgeItem?.isHidden = placement == .island
        edgeItem?.title = edgeTitle
    }

    @objc private func chooseAppearance(_ sender: NSMenuItem) {
        guard let raw = sender.representedObject as? String,
              let appearance = ShelfAppearance(rawValue: raw) else { return }
        settings.setAppearance(appearance)
    }

    @objc private func clearAll() {
        model?.clear(undoable: true)
    }

    @objc private func undoLast() {
        model?.undo()
    }

    @objc private func toggleCapture(_ sender: NSMenuItem) {
        settings.toggleCapture()
        monitor?.setEnabled(settings.captureEnabled)
        sender.state = settings.captureEnabled ? .on : .off
        captureItem?.state = sender.state
    }

    private var edgeTitle: String {
        if settings.placement == .dock, controller?.dockSide != .bottom {
            return settings.edge == .left ? "换到上边" : "换到下边"
        }
        return settings.edge == .left ? "换到右边" : "换到左边"
    }

    private func placementTitle(_ placement: ShelfPlacement) -> String {
        switch placement {
        case .sidebar: "侧边栏"
        case .island: "灵动岛"
        case .dock: "Dock 栏"
        }
    }

    private func appearanceTitle(_ appearance: ShelfAppearance) -> String {
        switch appearance {
        case .clear: "清透"
        case .regular: "磨砂"
        }
    }

    private func installMainMenu() {
        let main = NSMenu()
        let appItem = NSMenuItem()
        main.addItem(appItem)
        let appMenu = NSMenu(title: "SnapShelf")
        appItem.submenu = appMenu
        appMenu.delegate = self

        let about = appMenu.addItem(withTitle: "关于 SnapShelf", action: #selector(showAbout(_:)), keyEquivalent: "")
        about.target = self
        appMenu.addItem(.separator())
        addActions(to: appMenu, clearShortcut: "k")
        appMenu.addItem(.separator())
        appMenu.addItem(
            withTitle: "退出 SnapShelf",
            action: #selector(NSApplication.terminate(_:)),
            keyEquivalent: "q"
        )

        NSApp.mainMenu = main
    }

    private func addActions(to menu: NSMenu, clearShortcut: String) {
        let open = menu.addItem(withTitle: "打开 SnapShelf", action: #selector(showShelf), keyEquivalent: "o")
        open.keyEquivalentModifierMask = [.command, .shift]
        open.target = self

        let placementItem = NSMenuItem(title: "出现在", action: nil, keyEquivalent: "")
        let placementMenu = NSMenu()
        for placement in [ShelfPlacement.sidebar, .island, .dock] {
            let item = placementMenu.addItem(
                withTitle: placementTitle(placement),
                action: #selector(choosePlacement(_:)),
                keyEquivalent: ""
            )
            item.target = self
            item.representedObject = placement.rawValue
            item.state = settings.placement == placement ? .on : .off
        }
        placementItem.submenu = placementMenu
        menu.addItem(placementItem)

        let appearanceItem = NSMenuItem(title: "玻璃效果", action: nil, keyEquivalent: "")
        let appearanceMenu = NSMenu()
        for appearance in [ShelfAppearance.clear, .regular] {
            let item = appearanceMenu.addItem(
                withTitle: appearanceTitle(appearance),
                action: #selector(chooseAppearance(_:)),
                keyEquivalent: ""
            )
            item.target = self
            item.representedObject = appearance.rawValue
            item.state = settings.appearance == appearance ? .on : .off
        }
        appearanceItem.submenu = appearanceMenu
        menu.addItem(appearanceItem)

        let capture = menu.addItem(
            withTitle: "自动收集剪贴板媒体",
            action: #selector(toggleCapture(_:)),
            keyEquivalent: ""
        )
        capture.target = self
        capture.state = settings.captureEnabled ? .on : .off
        if menu === (NSApp.mainMenu?.item(at: 0)?.submenu) || captureItem == nil {
            captureItem = capture
        }

        let edge = menu.addItem(withTitle: edgeTitle, action: #selector(toggleEdge), keyEquivalent: "")
        edge.target = self
        edge.isHidden = settings.placement == .island
        if menu === (NSApp.mainMenu?.item(at: 0)?.submenu) || edgeItem == nil {
            edgeItem = edge
        }

        menu.addItem(.separator())
        let undo = menu.addItem(withTitle: "撤销", action: #selector(undoLast), keyEquivalent: "z")
        undo.target = self
        undo.isEnabled = model?.canUndo == true
        if menu === (NSApp.mainMenu?.item(at: 0)?.submenu) || undoItem == nil {
            undoItem = undo
        }

        let clear = menu.addItem(withTitle: "清空", action: #selector(clearAll), keyEquivalent: clearShortcut)
        clear.target = self
    }

    private func reactivateExistingInstance() -> Bool {
        guard let bundleID = Bundle.main.bundleIdentifier, !bundleID.isEmpty else { return false }
        let others = NSRunningApplication.runningApplications(withBundleIdentifier: bundleID)
            .filter { $0.processIdentifier != ProcessInfo.processInfo.processIdentifier }
        guard let existing = others.first else { return false }
        existing.activate(options: [.activateAllWindows])
        return true
    }
}
