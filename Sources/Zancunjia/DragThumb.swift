import AppKit
@preconcurrency import Quartz
import SwiftUI
import ZancunjiaCore

struct DragThumb: NSViewRepresentable {
    var item: ScratchItem
    var dragItems: [ScratchItem]
    var onClick: (NSEvent.ModifierFlags) -> Void
    var onQuickLook: () -> Void
    var onClearSelection: () -> Void

    func makeNSView(context: Context) -> ThumbView {
        let view = ThumbView()
        view.item = item
        view.dragItems = dragItems
        view.onClick = onClick
        view.onQuickLook = onQuickLook
        view.onClearSelection = onClearSelection
        return view
    }

    func updateNSView(_ view: ThumbView, context: Context) {
        view.item = item
        view.dragItems = dragItems
        view.onClick = onClick
        view.onQuickLook = onQuickLook
        view.onClearSelection = onClearSelection
    }
}

final class ThumbView: NSView, NSDraggingSource {
    var item: ScratchItem?
    var dragItems: [ScratchItem] = []
    var onClick: (NSEvent.ModifierFlags) -> Void = { _ in }
    var onQuickLook: () -> Void = {}
    var onClearSelection: () -> Void = {}
    private var downPoint: NSPoint?
    private var dragStarted = false

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        layer?.backgroundColor = NSColor.clear.cgColor
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not used")
    }

    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }
    override var acceptsFirstResponder: Bool { true }
    override var mouseDownCanMoveWindow: Bool { false }

    override func mouseDown(with event: NSEvent) {
        window?.makeFirstResponder(self)
        downPoint = convert(event.locationInWindow, from: nil)
        dragStarted = false
    }

    override func mouseDragged(with event: NSEvent) {
        guard let downPoint, let item, !dragStarted else { return }
        let point = convert(event.locationInWindow, from: nil)
        let distance = hypot(point.x - downPoint.x, point.y - downPoint.y)
        guard distance >= 4 else { return }
        dragStarted = true

        var items: [NSDraggingItem] = []
        for (index, dragged) in (dragItems.isEmpty ? [item] : dragItems).enumerated() {
            let image = NSImage(data: dragged.thumbnailPNG)
                ?? NSImage(contentsOf: dragged.fileURL)
                ?? NSImage(size: NSSize(width: 120, height: 80))
            let offset = CGFloat(min(index, 5)) * 4
            let frame = bounds.offsetBy(dx: offset, dy: -offset)
            let mainItem = NSDraggingItem(
                pasteboardWriter: ScratchFileWriter(url: dragged.fileURL, isVideo: dragged.isVideo)
            )
            mainItem.setDraggingFrame(frame, contents: image)
            items.append(mainItem)

            if let videoURL = dragged.pairedVideoURL {
                let videoItem = NSDraggingItem(
                    pasteboardWriter: ScratchFileWriter(url: videoURL, isVideo: true)
                )
                videoItem.setDraggingFrame(frame, contents: image)
                items.append(videoItem)
            }
        }

        beginDraggingSession(with: items, event: event, source: self)
    }

    override func mouseUp(with event: NSEvent) {
        if !dragStarted {
            onClick(event.modifierFlags.intersection(.deviceIndependentFlagsMask))
        }
        dragStarted = false
    }

    override func keyDown(with event: NSEvent) {
        switch event.keyCode {
        case 36, 76:
            onClick([])
        case 49:
            onQuickLook()
        case 53:
            onClearSelection()
        default:
            super.keyDown(with: event)
        }
    }

    override func menu(for event: NSEvent) -> NSMenu? {
        let menu = NSMenu()
        let preview = menu.addItem(withTitle: "快速预览", action: #selector(showPreview), keyEquivalent: "")
        preview.target = self
        return menu
    }

    @objc private func showPreview() {
        onQuickLook()
    }

    func draggingSession(
        _ session: NSDraggingSession,
        sourceOperationMaskFor context: NSDraggingContext
    ) -> NSDragOperation {
        .copy
    }
}

@MainActor
final class ShelfQuickLook: NSObject {
    static let shared = ShelfQuickLook()

    private var urls: [URL] = []

    func show(items: [ScratchItem], startingWith id: UUID) {
        urls = items.map(\.fileURL)
        guard !urls.isEmpty, let panel = QLPreviewPanel.shared() else { return }
        panel.dataSource = self
        panel.currentPreviewItemIndex = items.firstIndex(where: { $0.id == id }) ?? 0
        panel.reloadData()
        panel.makeKeyAndOrderFront(nil)
    }
}

extension ShelfQuickLook: @MainActor QLPreviewPanelDataSource {
    func numberOfPreviewItems(in panel: QLPreviewPanel!) -> Int {
        urls.count
    }

    func previewPanel(_ panel: QLPreviewPanel!, previewItemAt index: Int) -> QLPreviewItem! {
        urls[index] as NSURL
    }
}
