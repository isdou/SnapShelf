import AppKit
import ZancunjiaCore

@MainActor
final class ShelfPanelController: NSObject {
    let model: ShelfModel
    let settings: ShelfSettings
    private(set) var dockSide: DockSide = .bottom
    private var shelves: [ScreenShelf] = []
    private var dockTimer: Timer?
    private var lastDockTiles: [String: CGRect] = [:]

    init(model: ShelfModel, settings: ShelfSettings) {
        self.model = model
        self.settings = settings
    }

    func start(showExpanded: Bool) {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(screensChanged),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )
        DistributedNotificationCenter.default().addObserver(
            self,
            selector: #selector(screensChanged),
            name: Notification.Name("com.apple.dock.prefchanged"),
            object: nil
        )
        syncScreens()
        trackDock()
        if showExpanded {
            pinShelf(at: NSEvent.mouseLocation)
        }
    }

    func toggleEdge() {
        settings.setEdge(settings.edge == .left ? .right : .left)
        layoutShelves(animated: true)
    }

    func setPlacement(_ placement: ShelfPlacement) {
        settings.setPlacement(placement)
        trackDock()
        layoutShelves(animated: true)
    }

    func layoutShelves(animated: Bool) {
        for shelf in shelves {
            shelf.applyFrame(animated: animated)
        }
        if let shelf = shelves.first(where: { $0.screen == NSScreen.main }) ?? shelves.first {
            dockSide = shelf.chrome.dockSide
        }
    }

    private func trackDock() {
        dockTimer?.invalidate()
        dockTimer = nil
        guard settings.placement == .dock else { return }
        let timer = Timer(timeInterval: 1.5, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.refreshDockIfMoved()
            }
        }
        dockTimer = timer
        RunLoop.main.add(timer, forMode: .common)
    }

    private func refreshDockIfMoved() {
        guard settings.placement == .dock else { return }
        var moved = false
        for shelf in shelves {
            let tile = DockLocator.metrics(for: shelf.screen)?.tile ?? .null
            let previous = lastDockTiles[shelf.id] ?? .null
            if abs(tile.minX - previous.minX) > 1
                || abs(tile.minY - previous.minY) > 1
                || abs(tile.width - previous.width) > 1
                || abs(tile.height - previous.height) > 1 {
                moved = true
            }
            lastDockTiles[shelf.id] = tile
        }
        if moved {
            layoutShelves(animated: false)
        }
    }

    func pinShelf(at point: NSPoint) {
        let shelf = shelves.first { $0.screen.frame.contains(point) } ?? shelves.first
        shelf?.pinOpen()
    }

    func collapseOthers(except kept: ScreenShelf) {
        for shelf in shelves where shelf !== kept {
            shelf.yieldToAnotherShelf()
        }
    }

    @objc private func screensChanged() {
        syncScreens()
    }

    private func syncScreens() {
        let screens = NSScreen.screens
        let live = Set(screens.map(\.shelfID))
        for shelf in shelves where !live.contains(shelf.id) {
            shelf.panel.orderOut(nil)
        }
        shelves.removeAll { !live.contains($0.id) }

        for screen in screens {
            if let shelf = shelves.first(where: { $0.id == screen.shelfID }) {
                shelf.screen = screen
                shelf.applyFrame(animated: false)
            } else {
                let shelf = ScreenShelf(screen: screen, model: model, settings: settings, controller: self)
                shelf.install()
                shelves.append(shelf)
            }
        }
    }
}

final class ShelfPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }

    init(contentRect: NSRect) {
        super.init(
            contentRect: contentRect,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        isFloatingPanel = true
        hidesOnDeactivate = false
        becomesKeyOnlyIfNeeded = true
        isMovable = false
        isReleasedWhenClosed = false
        isOpaque = false
        backgroundColor = .clear
        hasShadow = false
        level = .floating
        collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary, .ignoresCycle]
        isExcludedFromWindowsMenu = true
        animationBehavior = .none
    }

    /// The shelf has to occupy the notch. The default
    /// clamp pulls it back into the work area.
    override func constrainFrameRect(_ frameRect: NSRect, to screen: NSScreen?) -> NSRect {
        frameRect
    }
}
