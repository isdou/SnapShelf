import AppKit
import SwiftUI

final class ClearHostingView<Content: View>: NSHostingView<Content> {
    override var isOpaque: Bool { false }
    private var needsBackgroundClearing = true

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        needsBackgroundClearing = true
        clearBackgroundsIfNeeded()
    }

    override func didAddSubview(_ subview: NSView) {
        super.didAddSubview(subview)
        needsBackgroundClearing = true
    }

    override func layout() {
        super.layout()
        clearBackgroundsIfNeeded()
    }

    private func clearBackgroundsIfNeeded() {
        guard needsBackgroundClearing else { return }
        wantsLayer = true
        layer?.backgroundColor = NSColor.clear.cgColor
        for subview in subviews {
            subview.wantsLayer = true
            subview.layer?.backgroundColor = NSColor.clear.cgColor
        }
        clearScrollViews(in: self)
        needsBackgroundClearing = false
    }

    private func clearScrollViews(in view: NSView) {
        if let scroll = view as? NSScrollView {
            scroll.drawsBackground = false
            scroll.backgroundColor = .clear
            scroll.contentView.drawsBackground = false
        }
        for subview in view.subviews {
            clearScrollViews(in: subview)
        }
    }
}
