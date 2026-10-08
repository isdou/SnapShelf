import AppKit
import Foundation

let output = URL(fileURLWithPath: CommandLine.arguments.dropFirst().first ?? "Support", isDirectory: true)
try FileManager.default.createDirectory(at: output, withIntermediateDirectories: true)

let master = NSImage(size: NSSize(width: 1024, height: 1024), flipped: false) { _ in
    let bounds = NSRect(x: 0, y: 0, width: 1024, height: 1024)
    NSGradient(colors: [
        NSColor(srgbRed: 0.09, green: 0.10, blue: 0.11, alpha: 1),
        NSColor(srgbRed: 0.22, green: 0.24, blue: 0.27, alpha: 1),
    ])?.draw(in: bounds, angle: 90)

    let handle = NSBezierPath(roundedRect: NSRect(x: 92, y: 188, width: 74, height: 648), xRadius: 37, yRadius: 37)
    NSColor(srgbRed: 0.95, green: 0.94, blue: 0.91, alpha: 1).setFill()
    handle.fill()

    func card(rect: NSRect, rotation: CGFloat, tint: NSColor, sun: NSPoint) {
        guard let context = NSGraphicsContext.current else { return }
        context.saveGraphicsState()
        let transform = NSAffineTransform()
        transform.translateX(by: rect.midX, yBy: rect.midY)
        transform.rotate(byDegrees: rotation)
        transform.translateX(by: -rect.midX, yBy: -rect.midY)
        transform.concat()

        let shadow = NSShadow()
        shadow.shadowColor = NSColor.black.withAlphaComponent(0.28)
        shadow.shadowOffset = NSSize(width: 0, height: -12)
        shadow.shadowBlurRadius = 24
        shadow.set()

        let path = NSBezierPath(roundedRect: rect, xRadius: 40, yRadius: 40)
        NSColor(srgbRed: 0.97, green: 0.96, blue: 0.93, alpha: 1).setFill()
        path.fill()
        shadow.shadowColor = .clear
        shadow.set()
        path.addClip()

        tint.setFill()
        NSBezierPath(rect: NSRect(x: rect.minX, y: rect.minY, width: rect.width, height: rect.height * 0.42)).fill()
        NSColor(srgbRed: 0.93, green: 0.72, blue: 0.38, alpha: 1).setFill()
        NSBezierPath(ovalIn: NSRect(x: sun.x, y: sun.y, width: 78, height: 78)).fill()
        context.restoreGraphicsState()
    }

    card(
        rect: NSRect(x: 250, y: 230, width: 560, height: 420),
        rotation: -7,
        tint: NSColor(srgbRed: 0.55, green: 0.66, blue: 0.60, alpha: 1),
        sun: NSPoint(x: 620, y: 470)
    )
    card(
        rect: NSRect(x: 300, y: 360, width: 590, height: 440),
        rotation: 5,
        tint: NSColor(srgbRed: 0.45, green: 0.58, blue: 0.62, alpha: 1),
        sun: NSPoint(x: 700, y: 620)
    )
    return true
}

func pngData(_ image: NSImage, side: Int) -> Data {
    let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: side,
        pixelsHigh: side,
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    )!
    rep.size = NSSize(width: side, height: side)
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    image.draw(in: NSRect(x: 0, y: 0, width: side, height: side), from: .zero, operation: .copy, fraction: 1)
    NSGraphicsContext.restoreGraphicsState()
    return rep.representation(using: .png, properties: [:])!
}

let masterURL = output.appending(path: "AppIcon-1024.png")
try pngData(master, side: 1024).write(to: masterURL)

let iconset = output.appending(path: "AppIcon.iconset", directoryHint: .isDirectory)
try? FileManager.default.removeItem(at: iconset)
try FileManager.default.createDirectory(at: iconset, withIntermediateDirectories: true)

let sizes = [
    (16, "icon_16x16.png"),
    (32, "icon_16x16@2x.png"),
    (32, "icon_32x32.png"),
    (64, "icon_32x32@2x.png"),
    (128, "icon_128x128.png"),
    (256, "icon_128x128@2x.png"),
    (256, "icon_256x256.png"),
    (512, "icon_256x256@2x.png"),
    (512, "icon_512x512.png"),
    (1024, "icon_512x512@2x.png"),
]
for (side, name) in sizes {
    try pngData(master, side: side).write(to: iconset.appending(path: name))
}

let icns = output.appending(path: "AppIcon.icns")
let tool = Process()
tool.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
tool.arguments = ["-c", "icns", iconset.path, "-o", icns.path]
try tool.run()
tool.waitUntilExit()
guard tool.terminationStatus == 0 else {
    fputs("iconutil failed\n", stderr)
    exit(1)
}
print(icns.path)
