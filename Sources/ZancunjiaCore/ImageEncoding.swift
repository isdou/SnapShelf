import CoreGraphics
import CryptoKit
import Foundation
import ImageIO
import UniformTypeIdentifiers

nonisolated struct EncodedImage: Sendable {
    var png: Data
    var thumbnailPNG: Data
    var pixelWidth: Int
    var pixelHeight: Int
    var contentHash: String
}

nonisolated enum ImageEncoding {
    private static let byteLimit = 80 * 1024 * 1024

    static func encodeSync(_ data: Data) -> EncodedImage? {
        guard !data.isEmpty, data.count <= byteLimit else { return nil }
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else { return nil }
        guard let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any] else {
            return nil
        }

        var pixelWidth = properties[kCGImagePropertyPixelWidth] as? Int ?? 0
        var pixelHeight = properties[kCGImagePropertyPixelHeight] as? Int ?? 0
        let orientation = properties[kCGImagePropertyOrientation] as? Int ?? 1
        if orientation >= 5 {
            swap(&pixelWidth, &pixelHeight)
        }
        guard pixelWidth > 1, pixelHeight > 1 else { return nil }

        let sourceType = CGImageSourceGetType(source) as String?
        let png: Data
        if sourceType == UTType.png.identifier, orientation == 1 {
            png = data
        } else if let upright = transformedImage(source, maxPixel: max(pixelWidth, pixelHeight)),
                  let encoded = pngData(from: upright) {
            png = encoded
        } else {
            return nil
        }

        guard let thumb = transformedImage(source, maxPixel: 560),
              let thumbnailPNG = pngData(from: thumb) else {
            return nil
        }

        let digest = SHA256.hash(data: png)
        let contentHash = digest.compactMap { String(format: "%02x", $0) }.joined()
        return EncodedImage(
            png: png,
            thumbnailPNG: thumbnailPNG,
            pixelWidth: pixelWidth,
            pixelHeight: pixelHeight,
            contentHash: contentHash
        )
    }

    @concurrent
    static func encode(_ data: Data) async -> EncodedImage? {
        encodeSync(data)
    }

    private static func transformedImage(_ source: CGImageSource, maxPixel: Int) -> CGImage? {
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixel,
        ]
        return CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary)
    }

    private static func pngData(from image: CGImage) -> Data? {
        guard let mutable = CFDataCreateMutable(kCFAllocatorDefault, 0) else { return nil }
        guard let destination = CGImageDestinationCreateWithData(mutable, UTType.png.identifier as CFString, 1, nil) else {
            return nil
        }
        CGImageDestinationAddImage(destination, image, nil)
        guard CGImageDestinationFinalize(destination) else { return nil }
        return mutable as Data
    }
}
