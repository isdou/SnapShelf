import AppKit
import Darwin
import ZancunjiaCore

/// The Dock's own window covers the whole display, so its bounds say nothing
/// about where the icons are. The window server reports that strip directly.
@MainActor
enum DockLocator {
    private typealias Connection = @convention(c) () -> Int32
    private typealias DockRect = @convention(c) (
        Int32,
        UnsafeMutablePointer<CGRect>,
        UnsafeMutablePointer<Int32>
    ) -> Int32

    private static let query: (DockRect, Int32)? = {
        guard let handle = dlopen("/System/Library/PrivateFrameworks/SkyLight.framework/SkyLight", RTLD_LAZY),
              let connectionSymbol = dlsym(handle, "SLSMainConnectionID"),
              let rectSymbol = dlsym(handle, "SLSGetDockRectWithReason") else { return nil }
        let connection = unsafeBitCast(connectionSymbol, to: Connection.self)
        let rect = unsafeBitCast(rectSymbol, to: DockRect.self)
        return (rect, connection())
    }()

    static func metrics(for screen: NSScreen) -> DockMetrics? {
        guard let query else { return nil }
        var rect = CGRect.null
        var reason: Int32 = 0
        guard query.0(query.1, &rect, &reason) == 0,
              rect.width > 20, rect.height > 20, rect.width < 20_000, rect.height < 20_000 else { return nil }

        // SkyLight's origin is the top-left of the primary display. AppKit's is
        // the bottom-left of that same display.
        let primary = NSScreen.screens.first { $0.frame.origin == .zero } ?? screen
        let tile = CGRect(
            x: rect.origin.x,
            y: primary.frame.maxY - rect.origin.y - rect.height,
            width: rect.width,
            height: rect.height
        )
        guard screen.frame.insetBy(dx: -300, dy: -300).intersects(tile) else { return nil }

        let side = DockMetrics.side(of: tile, on: screen.frame)
        let inset: CGFloat = switch side {
        case .bottom:
            screen.visibleFrame.minY - screen.frame.minY
        case .left:
            screen.visibleFrame.minX - screen.frame.minX
        case .right:
            screen.frame.maxX - screen.visibleFrame.maxX
        }
        return DockMetrics(tile: tile, side: side, hidden: inset < 8)
    }
}
