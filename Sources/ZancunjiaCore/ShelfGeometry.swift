import CoreGraphics
import Foundation

public nonisolated enum ShelfEdge: String, Sendable {
    case left
    case right
}

public nonisolated enum ShelfPlacement: String, Sendable {
    case sidebar
    case island
    case dock
}

/// Which screen edge the system Dock occupies. `left` on `ShelfEdge` means the
/// start of that edge (screen left, or the bottom when the Dock is vertical).
public nonisolated enum DockSide: String, Sendable {
    case bottom
    case left
    case right
}

/// The Dock icon strip in AppKit coordinates. `hidden` is auto-hide: the strip
/// is off the screen and `tile` is only used to remember which edge it uses.
public nonisolated struct DockMetrics: Equatable, Sendable {
    public var tile: CGRect
    public var side: DockSide
    public var hidden: Bool

    public init(tile: CGRect, side: DockSide, hidden: Bool) {
        self.tile = tile
        self.side = side
        self.hidden = hidden
    }

    public static func side(of tile: CGRect, on screen: CGRect) -> DockSide {
        let toLeft = abs(tile.minX - screen.minX)
        let toRight = abs(screen.maxX - tile.maxX)
        let toBottom = abs(tile.minY - screen.minY)
        let nearest = min(toLeft, toRight, toBottom)
        if nearest == toBottom { return .bottom }
        if nearest == toLeft { return .left }
        return .right
    }
}

public nonisolated enum ShelfGeometry {
    public static let tabWidth: CGFloat = 52
    public static let tabHeight: CGFloat = 168
    public static let expandedWidth: CGFloat = 420

    /// `anchor` is where the sidebar wants to sit, from 0 at the bottom of the
    /// visible frame to 1 at the top. Island ignores it.
    /// `full` is the whole display, including the menu bar. `notch` is the
    /// housing cutout in that same coordinate space.
    public static func frame(
        expanded: Bool,
        visible: CGRect,
        edge: ShelfEdge,
        itemCount: Int = 0,
        placement: ShelfPlacement = .sidebar,
        anchor: CGFloat = 0.5,
        full: CGRect? = nil,
        notch: CGRect? = nil,
        dock: DockMetrics? = nil
    ) -> CGRect {
        let screen = full ?? visible
        switch placement {
        case .sidebar:
            return sidebarFrame(expanded: expanded, visible: visible, edge: edge, itemCount: itemCount, anchor: anchor)
        case .island:
            return islandFrame(expanded: expanded, screen: screen, visible: visible, itemCount: itemCount, notch: notch)
        case .dock:
            return dockFrame(
                expanded: expanded,
                screen: screen,
                visible: visible,
                edge: edge,
                itemCount: itemCount,
                dock: dock ?? DockMetrics(tile: .null, side: .bottom, hidden: true)
            )
        }
    }

    private static func sidebarFrame(
        expanded: Bool,
        visible: CGRect,
        edge: ShelfEdge,
        itemCount: Int,
        anchor: CGFloat
    ) -> CGRect {
        let collapsedWidth: CGFloat = itemCount == 0 ? 16 : 20
        let width = expanded ? min(expandedWidth, max(tabWidth, visible.width - 32)) : collapsedWidth
        let preferredHeight = expanded
            ? expandedHeight(itemCount: itemCount, visibleHeight: visible.height)
            : min(itemCount == 0 ? 48 : (itemCount == 1 ? 56 : 64), visible.height - 24)
        let height = min(max(preferredHeight, 1), visible.height)
        let proposedMid = visible.minY + min(max(anchor, 0), 1) * visible.height
        let y = min(max(proposedMid - height / 2, visible.minY), visible.maxY - height)
        let x: CGFloat = switch edge {
        case .left:
            visible.minX
        case .right:
            visible.maxX - width
        }
        return CGRect(x: x.rounded(), y: y.rounded(), width: width.rounded(), height: height.rounded())
    }

    private static func islandFrame(
        expanded: Bool,
        screen: CGRect,
        visible: CGRect,
        itemCount: Int,
        notch: CGRect?
    ) -> CGRect {
        let width: CGFloat
        let height: CGFloat
        if expanded {
            // Same image grid as the sidebar, so the sheet is tall enough for
            // those cells instead of a one-line metadata row.
            width = min(548, max(320, screen.width - 40))
            height = min(
                expandedHeight(itemCount: itemCount, visibleHeight: screen.height),
                max(screen.height - 8, 1)
            )
        } else if let notch {
            // Ears sit in the menu bar, just outside the camera housing.
            width = notch.width + 70
            height = notch.height
        } else {
            width = itemCount == 0 ? 148 : 180
            height = 32
        }
        let anchorX = notch?.midX ?? screen.midX
        let x = min(max(anchorX - width / 2, screen.minX + 4), max(screen.maxX - width - 4, screen.minX))
        let y = screen.maxY - height
        return CGRect(x: x.rounded(), y: y.rounded(), width: width.rounded(), height: height.rounded())
    }

    private static func expandedHeight(itemCount: Int, visibleHeight: CGFloat) -> CGFloat {
        let measured: CGFloat = switch itemCount {
        case ..<1: 440
        case 1: 430
        default:
            128 + CGFloat((itemCount + 1) / 2) * 170
        }
        return min(720, max(360, measured), max(visibleHeight - 48, 1))
    }

    /// Collapsed shelf lives in the Dock bar. A free stretch of that bar is used
    /// when the icons leave one; otherwise it takes the end of the icon strip
    /// itself. Auto-hide has no bar, so the shelf is a lip on that edge until it opens.
    private static func dockFrame(
        expanded: Bool,
        screen: CGRect,
        visible: CGRect,
        edge: ShelfEdge,
        itemCount: Int,
        dock: DockMetrics
    ) -> CGRect {
        let work = CGRect(
            x: visible.minX,
            y: visible.minY,
            width: max(visible.width, 1),
            height: max(visible.height, 1)
        )
        if dock.hidden {
            return dockLip(expanded: expanded, screen: screen, work: work, side: dock.side, edge: edge, itemCount: itemCount)
        }
        let band = dockBand(side: dock.side, screen: screen, visible: visible)
        if let gap = dockGap(in: band, tile: dock.tile, side: dock.side, edge: edge) {
            let collapsed = dockPill(in: gap, tile: dock.tile, side: dock.side)
            guard expanded else { return collapsed.rounded() }
            return dockSheet(collapsed: collapsed, work: work, side: dock.side, itemCount: itemCount)
        }
        return dockInBar(
            expanded: expanded,
            work: work,
            tile: dock.tile,
            side: dock.side,
            edge: edge,
            itemCount: itemCount
        )
    }

    private static func dockBand(side: DockSide, screen: CGRect, visible: CGRect) -> CGRect {
        switch side {
        case .bottom:
            let height = max(visible.minY - screen.minY, 0)
            return CGRect(x: screen.minX, y: screen.minY, width: screen.width, height: height)
        case .left:
            let width = max(visible.minX - screen.minX, 0)
            return CGRect(x: screen.minX, y: screen.minY, width: width, height: max(visible.maxY - screen.minY, 0))
        case .right:
            let width = max(screen.maxX - visible.maxX, 0)
            return CGRect(x: screen.maxX - width, y: screen.minY, width: width, height: max(visible.maxY - screen.minY, 0))
        }
    }

    /// A gap has to fit a whole pill without covering Dock icons.
    private static func dockGap(in band: CGRect, tile: CGRect, side: DockSide, edge: ShelfEdge) -> CGRect? {
        let blocked = tile.insetBy(dx: -4, dy: -4)
        let horizontal = side == .bottom
        var gaps: [(rect: CGRect, atStart: Bool)] = []
        if horizontal {
            let left = blocked.minX - band.minX
            if left > 1 {
                gaps.append((CGRect(x: band.minX, y: band.minY, width: left, height: band.height), true))
            }
            let right = band.maxX - blocked.maxX
            if right > 1 {
                gaps.append((CGRect(x: blocked.maxX, y: band.minY, width: right, height: band.height), false))
            }
        } else {
            let below = blocked.minY - band.minY
            if below > 1 {
                gaps.append((CGRect(x: band.minX, y: band.minY, width: band.width, height: below), true))
            }
            let above = band.maxY - blocked.maxY
            if above > 1 {
                gaps.append((CGRect(x: band.minX, y: blocked.maxY, width: band.width, height: above), false))
            }
        }
        let usable = gaps.filter { gap in
            let length = horizontal ? gap.rect.width : gap.rect.height
            let thickness = horizontal ? gap.rect.height : gap.rect.width
            return length >= 72 && thickness >= 24
        }
        let wantStart = edge == .left
        return (usable.first { $0.atStart == wantStart } ?? usable.first)?.rect
    }

    private static func dockPill(in gap: CGRect, tile: CGRect, side: DockSide) -> CGRect {
        switch side {
        case .bottom:
            let height = min(max(gap.height - 8, 1), 80)
            let width = min(136, max(gap.width - 10, 1))
            let onStartSide = gap.maxX <= tile.midX
            let rawX = onStartSide ? gap.maxX - width - 4 : gap.minX + 4
            let x = min(max(rawX, gap.minX), max(gap.maxX - width, gap.minX))
            let y = gap.minY + (gap.height - height) / 2
            return CGRect(x: x, y: y, width: width, height: height)
        case .left, .right:
            let width = min(max(gap.width - 8, 1), 80)
            let height = min(136, max(gap.height - 10, 1))
            let onStartSide = gap.maxY <= tile.midY
            let rawY = onStartSide ? gap.maxY - height - 4 : gap.minY + 4
            let y = min(max(rawY, gap.minY), max(gap.maxY - height, gap.minY))
            let x = gap.minX + (gap.width - width) / 2
            return CGRect(x: x, y: y, width: width, height: height)
        }
    }

    /// Opens into the work area from the collapsed pill, away from the Dock icons.
    private static func dockSheet(
        collapsed: CGRect,
        work: CGRect,
        side: DockSide,
        itemCount: Int
    ) -> CGRect {
        let width = min(expandedWidth, max(work.width - 16, 1))
        let height = min(expandedHeight(itemCount: itemCount, visibleHeight: work.height), max(work.height - 8, 1))
        switch side {
        case .bottom:
            let proposed = collapsed.midX > work.midX ? collapsed.minX : collapsed.maxX - width
            let x = min(max(proposed, work.minX), max(work.maxX - width, work.minX))
            let y = work.minY
            return CGRect(x: x, y: y, width: width, height: height).rounded()
        case .left:
            let proposed = collapsed.midY > work.midY ? collapsed.maxY - height : collapsed.minY
            let y = min(max(proposed, work.minY), max(work.maxY - height, work.minY))
            return CGRect(x: work.minX, y: y, width: width, height: height).rounded()
        case .right:
            let proposed = collapsed.midY > work.midY ? collapsed.maxY - height : collapsed.minY
            let y = min(max(proposed, work.minY), max(work.maxY - height, work.minY))
            return CGRect(x: work.maxX - width, y: y, width: width, height: height).rounded()
        }
    }

    /// The icon strip already fills the bar. Take its end, on top of the Dock.
    private static func dockInBar(
        expanded: Bool,
        work: CGRect,
        tile: CGRect,
        side: DockSide,
        edge: ShelfEdge,
        itemCount: Int
    ) -> CGRect {
        let slot = dockSlot(tile: tile, side: side, edge: edge)
        guard expanded else { return slot.rounded() }
        return dockSheet(collapsed: slot, work: work, side: side, itemCount: itemCount)
    }

    private static func dockSlot(tile: CGRect, side: DockSide, edge: ShelfEdge) -> CGRect {
        switch side {
        case .bottom:
            let height = tile.height
            let width = min(max(height * 1.8, 72), 128, max(tile.width, 1))
            let x = edge == .left ? tile.minX : tile.maxX - width
            return CGRect(x: x, y: tile.minY, width: width, height: height)
        case .left, .right:
            let width = tile.width
            let height = min(max(width * 1.45, 68), 96, max(tile.height, 1))
            let y = edge == .left ? tile.minY : tile.maxY - height
            return CGRect(x: tile.minX, y: y, width: width, height: height)
        }
    }

    private static func dockLip(
        expanded: Bool,
        screen: CGRect,
        work: CGRect,
        side: DockSide,
        edge: ShelfEdge,
        itemCount: Int
    ) -> CGRect {
        let thickness: CGFloat = 18
        switch side {
        case .bottom:
            let height = expanded
                ? min(expandedHeight(itemCount: itemCount, visibleHeight: work.height), max(screen.maxY - screen.minY - 8, 1))
                : thickness
            let width = expanded
                ? min(expandedWidth, max(work.width - 16, 1))
                : min(132, max(work.width - 16, 1))
            let x = edge == .left ? work.minX + 8 : max(work.maxX - width - 8, work.minX)
            let y = screen.minY
            let maxHeight = max(work.maxY - y, thickness)
            return CGRect(x: x, y: y, width: width, height: min(height, maxHeight)).rounded()
        case .left:
            let width = expanded ? min(expandedWidth, max(work.width, 1)) : thickness
            let height = expanded
                ? min(expandedHeight(itemCount: itemCount, visibleHeight: work.height), max(work.height - 16, 1))
                : min(132, max(work.height - 16, 1))
            let y = edge == .left ? work.minY + 8 : max(work.maxY - height - 8, work.minY)
            return CGRect(x: screen.minX, y: y, width: min(width, max(work.maxX - screen.minX, 1)), height: height).rounded()
        case .right:
            let width = expanded ? min(expandedWidth, max(work.width, 1)) : thickness
            let height = expanded
                ? min(expandedHeight(itemCount: itemCount, visibleHeight: work.height), max(work.height - 16, 1))
                : min(132, max(work.height - 16, 1))
            let y = edge == .left ? work.minY + 8 : max(work.maxY - height - 8, work.minY)
            let x = screen.maxX - width
            return CGRect(x: x, y: y, width: width, height: height).rounded()
        }
    }
}

private extension CGRect {
    nonisolated func rounded() -> CGRect {
        CGRect(x: minX.rounded(), y: minY.rounded(), width: width.rounded(), height: height.rounded())
    }
}
