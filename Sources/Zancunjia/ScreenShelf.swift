import AppKit
import QuartzCore
import SwiftUI
import ZancunjiaCore

@MainActor
final class ScreenShelf {
    let id: String
    var screen: NSScreen
    let panel: ShelfPanel
    let host: TrackingHostView
    let handle = TabDragHandle(frame: .zero)
    let chrome: ShelfChrome
    private let model: ShelfModel
    private let settings: ShelfSettings
    private weak var controller: ShelfPanelController?
    private var collapseTask: Task<Void, Never>?

    init(screen: NSScreen, model: ShelfModel, settings: ShelfSettings, controller: ShelfPanelController) {
        self.id = screen.shelfID
        self.screen = screen
        self.model = model
        self.settings = settings
        self.controller = controller
        self.chrome = ShelfChrome()
        let frame = Self.frame(for: screen, expanded: false, itemCount: 0, settings: settings)
        self.panel = ShelfPanel(contentRect: frame)
        self.host = TrackingHostView(frame: NSRect(origin: .zero, size: frame.size))
    }

    func install() {
        let hosting = ClearHostingView(rootView: ShelfView(model: model, chrome: chrome, settings: settings))
        hosting.sizingOptions = []
        hosting.safeAreaRegions = []
        hosting.autoresizingMask = [.width, .height]
        host.embed(hosting)
        host.addSubview(handle)
        handle.onClick = { [weak self] in self?.togglePin() }
        handle.onDrag = { [weak self] point in self?.reposition(to: point) }
        handle.onDragEnded = { [weak self] in self?.finishReposition() }
        host.onLayout = { [weak self] in self?.placeHandle() }
        panel.contentView = host

        chrome.togglePin = { [weak self] in
            self?.togglePin()
        }
        chrome.reposition = { [weak self] point in
            self?.reposition(to: point)
        }
        chrome.finishReposition = { [weak self] in
            self?.finishReposition()
        }
        host.onEntered = { [weak self] in
            self?.hoverEntered()
        }
        host.onExited = { [weak self] in
            self?.hoverExited()
        }
        host.onDragInside = { [weak self] inside in
            self?.dragInside(inside)
        }
        host.onDrop = { [weak self] pasteboard in
            self?.receiveDrop(pasteboard) ?? false
        }
        host.menuProvider = {
            AppDelegate.shared.makeActionMenu()
        }
        applyFrame(animated: false)
        trackItems()
    }

    private func trackItems() {
        withObservationTracking {
            _ = model.items.count
        } onChange: { [weak self] in
            Task { @MainActor in
                guard let self else { return }
                self.applyFrame(animated: true)
                self.trackItems()
            }
        }
    }

    private static func frame(for screen: NSScreen, expanded: Bool, itemCount: Int, settings: ShelfSettings) -> CGRect {
        let dock = settings.placement == .dock
            ? DockLocator.metrics(for: screen) ?? DockMetrics(tile: .null, side: .bottom, hidden: true)
            : nil
        return ShelfGeometry.frame(
            expanded: expanded,
            visible: screen.visibleFrame,
            edge: settings.edge,
            itemCount: itemCount,
            placement: settings.placement,
            anchor: settings.anchor,
            full: screen.frame,
            notch: screen.notchRect,
            dock: dock
        )
    }

    func applyFrame(animated: Bool) {
        let visible = screen.visibleFrame
        guard visible.width > 1, visible.height > 1 else { return }
        updateWindowStyle()
        if !panel.isVisible {
            panel.orderFrontRegardless()
            updateWindowStyle()
        }
        if settings.placement == .dock {
            let dock = DockLocator.metrics(for: screen) ?? DockMetrics(tile: .null, side: .bottom, hidden: true)
            chrome.dockSide = dock.side
        }
        let target = Self.frame(for: screen, expanded: chrome.isExpanded, itemCount: model.items.count, settings: settings)
        let level = windowLevel(for: target, visible: visible)
        let unchanged = panel.level == level && sameFrame(panel.frame, target)
        panel.level = level
        guard !unchanged else {
            placeHandle()
            return
        }
        guard animated else {
            panel.setFrame(target, display: true)
            placeHandle()
            return
        }
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.34
            context.timingFunction = CAMediaTimingFunction(controlPoints: 0.22, 1, 0.36, 1)
            panel.animator().setFrame(target, display: true)
        }
        placeHandle()
    }

    /// Only open shelves use the system window plate; the collapsed sidebar
    /// draws its own edge so the screen-facing side stays flat.
    private func updateWindowStyle() {
        let customPlate = settings.placement == .island
            || (settings.placement == .sidebar && !chrome.isExpanded)
        let mask: NSWindow.StyleMask = customPlate
            ? [.borderless, .nonactivatingPanel]
            : [.titled, .fullSizeContentView, .nonactivatingPanel]
        if panel.styleMask != mask {
            panel.styleMask = mask
            if panel.contentView !== host {
                panel.contentView = host
            }
        }
        if customPlate {
            panel.isOpaque = false
            panel.backgroundColor = .clear
            panel.hasShadow = false
            return
        }
        panel.isOpaque = true
        panel.backgroundColor = .windowBackgroundColor
        panel.hasShadow = true
        panel.title = ""
        panel.titleVisibility = .hidden
        panel.titlebarAppearsTransparent = true
        for kind: NSWindow.ButtonType in [.closeButton, .miniaturizeButton, .zoomButton] {
            panel.standardWindowButton(kind)?.isHidden = true
        }
    }

    private func windowLevel(for target: CGRect, visible: CGRect) -> NSWindow.Level {
        switch settings.placement {
        case .island:
            return NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.popUpMenuWindow)))
        case .dock where !visible.insetBy(dx: -1, dy: -1).contains(target):
            // The gap beside the icons is under the Dock's full-screen window.
            return NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.dockWindow)) + 1)
        case .dock, .sidebar:
            return .floating
        }
    }

    private func sameFrame(_ current: CGRect, _ target: CGRect) -> Bool {
        abs(current.minX - target.minX) < 0.5
            && abs(current.minY - target.minY) < 0.5
            && abs(current.width - target.width) < 0.5
            && abs(current.height - target.height) < 0.5
    }

    private func placeHandle() {
        guard settings.placement == .sidebar else {
            handle.isHidden = true
            return
        }
        handle.isHidden = false
        let width = min(ShelfGeometry.tabWidth, host.bounds.width)
        let x: CGFloat = settings.edge == .left ? 0 : max(host.bounds.width - width, 0)
        handle.frame = CGRect(x: x, y: 0, width: width, height: host.bounds.height)
        handle.toolTip = L10n.t("help.handle")
    }

    func pinOpen() {
        collapseTask?.cancel()
        controller?.collapseOthers(except: self)
        chrome.isPinned = true
        chrome.isExpanded = true
        applyFrame(animated: true)
    }

    func togglePin() {
        if chrome.isPinned {
            chrome.isPinned = false
            chrome.isExpanded = false
            applyFrame(animated: true)
        } else {
            pinOpen()
        }
    }

    private var grabOffset: CGFloat?

    func reposition(to point: NSPoint) {
        guard settings.placement == .sidebar else { return }
        let visible = screen.visibleFrame
        let band = (screen.frame.minY - 40)...(screen.frame.maxY + 40)
        guard visible.height > 1, band.contains(point.y) else { return }
        if grabOffset == nil {
            // Hover has usually expanded the panel by the time the hold ends. The tall
            // panel is clamped to the screen, so drag the bare tab, centered on the pointer.
            grabOffset = chrome.isExpanded ? 0 : panel.frame.midY - point.y
            chrome.isExpanded = false
        }
        chrome.isAdjusting = true
        collapseTask?.cancel()
        let mid = point.y + (grabOffset ?? 0)
        settings.setAnchor((mid - visible.minY) / visible.height, persist: false)
        controller?.layoutShelves(animated: false)
    }

    func finishReposition() {
        grabOffset = nil
        guard chrome.isAdjusting else { return }
        chrome.isAdjusting = false
        settings.persistAnchor()
        if chrome.isPinned {
            chrome.isExpanded = true
            applyFrame(animated: true)
        }
    }

    func yieldToAnotherShelf() {
        collapseTask?.cancel()
        chrome.isPinned = false
        guard chrome.isExpanded else { return }
        chrome.isExpanded = false
        applyFrame(animated: true)
    }

    private func hoverEntered() {
        guard !chrome.isAdjusting else { return }
        collapseTask?.cancel()
        guard !chrome.isExpanded else { return }
        controller?.collapseOthers(except: self)
        chrome.isExpanded = true
        applyFrame(animated: true)
    }

    private func hoverExited() {
        guard !chrome.isAdjusting else { return }
        scheduleCollapse()
    }

    private func dragInside(_ inside: Bool) {
        chrome.dropTargeted = inside
        if inside {
            collapseTask?.cancel()
            guard !chrome.isExpanded else { return }
            controller?.collapseOthers(except: self)
            chrome.isExpanded = true
            applyFrame(animated: true)
        } else {
            scheduleCollapse()
        }
    }

    private func receiveDrop(_ pasteboard: NSPasteboard) -> Bool {
        guard acceptsMedia(pasteboard) else { return false }
        Task {
            let payloads = await ClipboardReader.readMedia(from: pasteboard)
            guard !payloads.isEmpty else {
                ShelfLog.main.error("Dropped media could not be read")
                NSSound.beep()
                return
            }
            await model.importMedia(payloads)
        }
        return true
    }

    private func acceptsMedia(_ pasteboard: NSPasteboard) -> Bool {
        guard !ClipboardReader.shouldIgnore(pasteboard) else { return false }
        if let urls = pasteboard.readObjects(forClasses: [NSURL.self]) as? [URL],
           urls.contains(where: { url in
                guard url.isFileURL else { return false }
                if MediaExtractor.isImageFile(url) || MediaExtractor.isMovieFile(url) { return true }
                guard let files = try? FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: nil) else {
                    return false
                }
                return files.contains(where: MediaExtractor.isImageFile) && files.contains(where: MediaExtractor.isMovieFile)
           }) {
            return true
        }
        return pasteboard.availableType(from: [
            .png, .tiff,
            .init("public.jpeg"), .init("public.heic"),
            .init("public.gif"), .init("public.webp"),
            .init("Apple PNG pasteboard type"),
            .init("com.apple.quicktime-movie"), .init("public.mpeg-4"),
            .init("public.movie"), .init("public.video")
        ]) != nil
    }

    private func scheduleCollapse() {
        collapseTask?.cancel()
        collapseTask = Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(280))
            guard let self, !Task.isCancelled else { return }
            self.collapseIfIdle()
        }
    }

    private func collapseIfIdle() {
        guard !chrome.isPinned, !chrome.dropTargeted, !chrome.isAdjusting else { return }
        if NSEvent.pressedMouseButtons != 0 {
            scheduleCollapse()
            return
        }
        if panel.frame.insetBy(dx: -20, dy: -20).contains(NSEvent.mouseLocation) {
            return
        }
        chrome.isExpanded = false
        applyFrame(animated: true)
    }
}
