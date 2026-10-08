import AppKit

extension NSScreen {
    var shelfID: String {
        let number = deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber
        return "\(localizedName)#\(number?.intValue ?? 0)"
    }

    /// The housing notch, in the same bottom-left space as `frame`. Nil on displays without one.
    var notchRect: CGRect? {
        guard let left = auxiliaryTopLeftArea, let right = auxiliaryTopRightArea else { return nil }
        let width = right.minX - left.maxX
        guard width > 1 else { return nil }
        let bottom = min(left.minY, right.minY)
        return CGRect(x: left.maxX, y: bottom, width: width, height: frame.maxY - bottom)
    }

    /// Points already occupied by the menu bar inside `visibleFrame`. Zero when
    /// `visibleFrame` stops at the menu bar.
    var shelfMenuClearance: CGFloat {
        let reserved = frame.maxY - visibleFrame.maxY
        if reserved >= 20 { return 0 }
        return NSStatusBar.system.thickness
    }
}
