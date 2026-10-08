import AppKit
import Observation
import ZancunjiaCore

@MainActor
@Observable
final class ShelfChrome {
    var isExpanded = false
    var isPinned = false
    var dropTargeted = false
    var isAdjusting = false
    var dockSide: DockSide = .bottom
    var togglePin: () -> Void = {}
    var reposition: (NSPoint) -> Void = { _ in }
    var finishReposition: () -> Void = {}
}
