import AppKit

final class TrackingHostView: NSView {
    var onEntered: () -> Void = {}
    var onExited: () -> Void = {}
    var onDragInside: (Bool) -> Void = { _ in }
    var onDrop: (NSPasteboard) -> Bool = { _ in false }
    var menuProvider: () -> NSMenu = { NSMenu() }
    private weak var hosted: NSView?

    override var isOpaque: Bool { false }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        registerForDraggedTypes([
            .fileURL,
            .png,
            .tiff,
            NSPasteboard.PasteboardType("public.jpeg"),
            NSPasteboard.PasteboardType("public.heic"),
            NSPasteboard.PasteboardType("public.gif"),
            NSPasteboard.PasteboardType("public.webp"),
            NSPasteboard.PasteboardType("Apple PNG pasteboard type"),
            NSPasteboard.PasteboardType("com.apple.quicktime-movie"),
            NSPasteboard.PasteboardType("public.mpeg-4"),
            NSPasteboard.PasteboardType("public.movie"),
            NSPasteboard.PasteboardType("public.video"),
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not used")
    }

    func embed(_ view: NSView) {
        hosted = view
        addSubview(view)
        view.frame = bounds
    }

    var onLayout: () -> Void = {}

    override func layout() {
        super.layout()
        hosted?.frame = bounds
        onLayout()
    }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        for area in trackingAreas {
            removeTrackingArea(area)
        }
        addTrackingArea(NSTrackingArea(
            rect: bounds,
            options: [.mouseEnteredAndExited, .activeAlways, .inVisibleRect],
            owner: self,
            userInfo: nil
        ))
    }

    override func mouseEntered(with event: NSEvent) {
        onEntered()
    }

    override func mouseExited(with event: NSEvent) {
        onExited()
    }

    override func menu(for event: NSEvent) -> NSMenu? {
        menuProvider()
    }

    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        guard acceptsExternal(sender) else { return [] }
        onDragInside(true)
        return .copy
    }

    override func draggingUpdated(_ sender: NSDraggingInfo) -> NSDragOperation {
        acceptsExternal(sender) ? .copy : []
    }

    override func draggingExited(_ sender: NSDraggingInfo?) {
        onDragInside(false)
    }

    override func prepareForDragOperation(_ sender: NSDraggingInfo) -> Bool {
        acceptsExternal(sender)
    }

    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        onDragInside(false)
        guard acceptsExternal(sender) else { return false }
        return onDrop(sender.draggingPasteboard)
    }

    private func acceptsExternal(_ sender: NSDraggingInfo) -> Bool {
        !(sender.draggingSource is ThumbView)
    }
}
