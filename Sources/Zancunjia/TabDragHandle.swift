import AppKit

/// Sits on the sidebar tab. A click toggles the pin; a short hold then a vertical
/// drag moves the shelf. Tracking stays in AppKit so the window can follow the pointer.
final class TabDragHandle: NSView {
    var onClick: () -> Void = {}
    var onDrag: (NSPoint) -> Void = { _ in }
    var onDragEnded: () -> Void = {}

    override var isOpaque: Bool { false }

    override func mouseDown(with event: NSEvent) {
        let start = NSEvent.mouseLocation
        let began = Date()
        var dragging = false
        window?.trackEvents(
            matching: [.leftMouseDragged, .leftMouseUp],
            timeout: .greatestFiniteMagnitude,
            mode: .eventTracking
        ) { event, stop in
            guard let event else { return }
            switch event.type {
            case .leftMouseUp:
                NSCursor.arrow.set()
                if dragging {
                    self.onDragEnded()
                } else {
                    self.onClick()
                }
                stop.pointee = true
            case .leftMouseDragged:
                let now = NSEvent.mouseLocation
                let distance = hypot(now.x - start.x, now.y - start.y)
                if !dragging, Date().timeIntervalSince(began) >= 0.28, distance >= 2 {
                    dragging = true
                    NSCursor.closedHand.set()
                }
                if dragging {
                    self.onDrag(now)
                }
            default:
                break
            }
        }
    }
}
