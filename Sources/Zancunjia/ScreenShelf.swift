import AppKit
import ObjectiveC
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
    /// AppKit glass behind the SwiftUI content. SwiftUI's own glass view is not
    /// an `NSGlassEffectView`, so the two plates cannot be pinned from there.
    private var glassPlate: NSView?
    private var glassPin: Task<Void, Never>?

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
        if #available(macOS 26, *) {
            let glass = ShelfGlassPlate(frame: host.bounds)
            glass.autoresizingMask = [.width, .height]
            glass.cornerRadius = ShelfGeometry.cornerRadius
            host.addSubview(glass)
            glassPlate = glass
        }
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
        trackAppearance()
        updateGlassPlate()
    }

    private func trackAppearance() {
        withObservationTracking {
            _ = settings.appearance
            _ = settings.placement
        } onChange: { [weak self] in
            Task { @MainActor in
                guard let self else { return }
                self.updateGlassPlate()
                self.trackAppearance()
            }
        }
    }

    /// Adaptation stays off so a light window cannot flip the plate on its own.
    /// The "clear" appearance uses the regular sample you can see the desktop through.
    /// The "regular" (frosted) appearance uses the clear style, which settles into the darker gray plate.
    private func updateGlassPlate() {
        guard #available(macOS 26, *), let glass = glassPlate as? ShelfGlassPlate else { return }
        glass.isHidden = settings.placement == .island
        glass.frame = host.bounds
        let clear = settings.appearance == .clear
        glass.tintColor = nil
        setGlassInt(glass, "set_adaptiveAppearance:", 1)
        // Clear style is the darker plate that hides the desktop. Regular style
        // plus a light backdrop sample is the one you can see the wallpaper through.
        glass.style = clear ? .regular : .clear
        glass.seeThrough = clear
        glass.backdropScale = clear ? 0.04 : 1
        let radius = ShelfGeometry.cornerRadius
        let bounds = glass.bounds
        let path: CGPath
        if settings.placement == .dock, !chrome.isExpanded {
            let capsule = min(bounds.width, bounds.height) / 2
            path = unevenPath(bounds, topLeft: capsule, topRight: capsule, bottomRight: capsule, bottomLeft: capsule)
        } else if settings.placement == .sidebar {
            let onLeft = settings.edge == .left
            path = unevenPath(
                bounds,
                topLeft: onLeft ? 0 : radius,
                topRight: onLeft ? radius : 0,
                bottomRight: onLeft ? radius : 0,
                bottomLeft: onLeft ? 0 : radius
            )
        } else {
            path = unevenPath(bounds, topLeft: radius, topRight: radius, bottomRight: radius, bottomLeft: radius)
        }
        glass.cornerRadius = radius
        setGlassPath(glass, path: path)
        let seeThrough = glass.seeThrough
        glassPin?.cancel()
        glassPin = Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(700))
            guard !Task.isCancelled, glass.seeThrough == seeThrough else { return }
            glass.pinBackdropScale()
        }
    }

    private func unevenPath(
        _ rect: CGRect,
        topLeft: CGFloat,
        topRight: CGFloat,
        bottomRight: CGFloat,
        bottomLeft: CGFloat
    ) -> CGPath {
        let path = CGMutablePath()
        func turn(to corner: CGPoint, then next: CGPoint, radius: CGFloat) {
            if radius > 0 {
                path.addArc(tangent1End: corner, tangent2End: next, radius: radius)
            } else {
                path.addLine(to: corner)
            }
        }
        path.move(to: CGPoint(x: rect.minX + topLeft, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX - topRight, y: rect.maxY))
        turn(to: CGPoint(x: rect.maxX, y: rect.maxY), then: CGPoint(x: rect.maxX, y: rect.maxY - topRight), radius: topRight)
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + bottomRight))
        turn(to: CGPoint(x: rect.maxX, y: rect.minY), then: CGPoint(x: rect.maxX - bottomRight, y: rect.minY), radius: bottomRight)
        path.addLine(to: CGPoint(x: rect.minX + bottomLeft, y: rect.minY))
        turn(to: CGPoint(x: rect.minX, y: rect.minY), then: CGPoint(x: rect.minX, y: rect.minY + bottomLeft), radius: bottomLeft)
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY - topLeft))
        turn(to: CGPoint(x: rect.minX, y: rect.maxY), then: CGPoint(x: rect.minX + topLeft, y: rect.maxY), radius: topLeft)
        path.closeSubpath()
        return path
    }

    private func setGlassPath(_ view: NSView, path: CGPath) {
        let sel = NSSelectorFromString("_setPath:")
        guard view.responds(to: sel), let method = class_getInstanceMethod(type(of: view), sel) else { return }
        typealias Fn = @convention(c) (AnyObject, Selector, CGPath) -> Void
        let fn = unsafeBitCast(method_getImplementation(method), to: Fn.self)
        fn(view, sel, path)
    }

    private func setGlassInt(_ view: NSView, _ setter: String, _ value: Int) {
        let sel = NSSelectorFromString(setter)
        guard view.responds(to: sel), let method = class_getInstanceMethod(type(of: view), sel) else { return }
        typealias Fn = @convention(c) (AnyObject, Selector, Int) -> Void
        let fn = unsafeBitCast(method_getImplementation(method), to: Fn.self)
        fn(view, sel, value)
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
        if !panel.isVisible {
            panel.orderFrontRegardless()
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
        updateGlassPlate()
        guard settings.placement == .sidebar else {
            handle.isHidden = true
            return
        }
        handle.isHidden = false
        let width = min(ShelfGeometry.tabWidth, host.bounds.width)
        let x: CGFloat = settings.edge == .left ? 0 : max(host.bounds.width - width, 0)
        handle.frame = CGRect(x: x, y: 0, width: width, height: host.bounds.height)
        handle.toolTip = "点击固定，按住可上下移动"
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
            grabOffset = panel.frame.midY - point.y
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

/// Pins the glass backdrop after AppKit resets it during layout.
@available(macOS 26, *)
private final class ShelfGlassPlate: NSGlassEffectView {
    var backdropScale: CGFloat = 0.5
    /// Regular glass with an extra backdrop blur. This is the plate you can see through.
    var seeThrough = false

    override func layout() {
        super.layout()
        pinScale(layer)
    }

    func pinBackdropScale() {
        pinScale(layer)
        pinFilters(layer)
    }

    private func pinScale(_ layer: CALayer?) {
        guard let layer else { return }
        if String(describing: type(of: layer)) == "CABackdropLayer" {
            layer.setValue(backdropScale, forKey: "scale")
        }
        let children = layer.sublayers ?? []
        for sublayer in children {
            pinScale(sublayer)
        }
    }

    private func pinFilters(_ layer: CALayer?) {
        guard let layer else { return }
        if String(describing: type(of: layer)) == "CABackdropLayer" {
            let existing = (layer.value(forKey: "filters") as? [NSObject]) ?? []
            let glass = existing.filter { String(describing: $0) == "glassBackground" }
            // Removing glassBackground drops the plate and the shelf content with it.
            guard !glass.isEmpty else { return }
            if seeThrough, let blur = gaussianBlur(radius: 36) {
                layer.setValue(glass + [blur], forKey: "filters")
            } else {
                layer.setValue(glass, forKey: "filters")
            }
        }
        let children = layer.sublayers ?? []
        for sublayer in children {
            pinFilters(sublayer)
        }
    }

    private func gaussianBlur(radius: CGFloat) -> NSObject? {
        guard let cls = NSClassFromString("CAFilter") else { return nil }
        let sel = NSSelectorFromString("filterWithType:")
        guard let method = class_getClassMethod(cls, sel) else { return nil }
        typealias Make = @convention(c) (AnyClass, Selector, NSString) -> Unmanaged<NSObject>?
        // filterWithType: returns an autoreleased object.
        let filter = unsafeBitCast(method_getImplementation(method), to: Make.self)(cls, sel, "gaussianBlur")?.takeUnretainedValue()
        filter?.setValue(radius, forKey: "inputRadius")
        return filter
    }
}
