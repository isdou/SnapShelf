import Foundation
import Observation
import ZancunjiaCore

/// Which Liquid Glass plate the shelf keeps. The system otherwise flips
/// between these two as the desktop behind the panel changes.
enum ShelfAppearance: String {
    /// See-through glass. The desktop shows through, blurred.
    case clear
    /// Frosted glass. The panel stays a milky gray.
    case regular
}

@MainActor
@Observable
final class ShelfSettings {
    private(set) var edge: ShelfEdge
    private(set) var placement: ShelfPlacement
    private(set) var captureEnabled: Bool
    private(set) var appearance: ShelfAppearance
    /// 0 sits on the bottom of the screen, 1 on the top. Sidebar only.
    private(set) var anchor: CGFloat

    init() {
        let edgeRaw = UserDefaults.standard.string(forKey: Self.edgeKey) ?? ""
        edge = ShelfEdge(rawValue: edgeRaw) ?? .left
        let placementRaw = UserDefaults.standard.string(forKey: Self.placementKey) ?? ""
        placement = ShelfPlacement(rawValue: placementRaw) ?? .sidebar
        captureEnabled = UserDefaults.standard.object(forKey: Self.captureKey) as? Bool ?? true
        let appearanceRaw = UserDefaults.standard.string(forKey: Self.appearanceKey) ?? ""
        // An older build stored a flat fill under "solid". That is not one of the
        // two glass plates, so it opens as the frosted one.
        appearance = appearanceRaw == "solid" ? .regular : (ShelfAppearance(rawValue: appearanceRaw) ?? .clear)
        let storedAnchor = UserDefaults.standard.object(forKey: Self.anchorKey) as? Double
        anchor = storedAnchor.map { min(max($0, 0), 1) } ?? 0.5
    }

    func setEdge(_ edge: ShelfEdge) {
        self.edge = edge
        UserDefaults.standard.set(edge.rawValue, forKey: Self.edgeKey)
    }

    func setPlacement(_ placement: ShelfPlacement) {
        self.placement = placement
        UserDefaults.standard.set(placement.rawValue, forKey: Self.placementKey)
    }

    func setAppearance(_ appearance: ShelfAppearance) {
        self.appearance = appearance
        UserDefaults.standard.set(appearance.rawValue, forKey: Self.appearanceKey)
    }

    func toggleCapture() {
        captureEnabled.toggle()
        UserDefaults.standard.set(captureEnabled, forKey: Self.captureKey)
    }

    func setAnchor(_ anchor: CGFloat, persist: Bool) {
        self.anchor = min(max(anchor, 0), 1)
        if persist {
            persistAnchor()
        }
    }

    func persistAnchor() {
        UserDefaults.standard.set(anchor, forKey: Self.anchorKey)
    }

    private static let edgeKey = "Zancunjia.edge"
    private static let placementKey = "Zancunjia.placement"
    private static let captureKey = "Zancunjia.captureEnabled"
    private static let anchorKey = "Zancunjia.anchor"
    private static let appearanceKey = "Zancunjia.appearance"
}
