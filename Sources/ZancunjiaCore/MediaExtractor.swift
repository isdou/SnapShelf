import AVFoundation
import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

public nonisolated enum MediaExtractor {
    public static func isMovieFile(_ url: URL) -> Bool {
        guard let type = UTType(filenameExtension: url.pathExtension) else {
            return ["mov", "mp4", "m4v", "webm", "avi"].contains(url.pathExtension.lowercased())
        }
        return type.conforms(to: .movie) || type.conforms(to: .video) || type.conforms(to: .quickTimeMovie) || type.conforms(to: .mpeg4Movie)
    }

    public static func isImageFile(_ url: URL) -> Bool {
        guard let type = UTType(filenameExtension: url.pathExtension) else {
            return ["png", "jpg", "jpeg", "heic", "tiff", "gif", "webp"].contains(url.pathExtension.lowercased())
        }
        return type.conforms(to: .image)
    }

    public static func videoInfo(at url: URL) async -> (width: Int, height: Int, duration: TimeInterval, thumbnailPNG: Data)? {
        let asset = AVURLAsset(url: url)
        do {
            let durationTime = try await asset.load(.duration)
            let duration = CMTimeGetSeconds(durationTime)
            let tracks = try await asset.loadTracks(withMediaType: .video)
            guard let videoTrack = tracks.first else { return nil }
            let naturalSize = try await videoTrack.load(.naturalSize)
            let transform = try await videoTrack.load(.preferredTransform)

            let transformedSize = naturalSize.applying(transform)
            let width = max(1, Int(abs(transformedSize.width)))
            let height = max(1, Int(abs(transformedSize.height)))

            let generator = AVAssetImageGenerator(asset: asset)
            generator.appliesPreferredTrackTransform = true
            generator.maximumSize = CGSize(width: 560, height: 560)

            let targetSeconds = min(0.5, max(0.0, duration / 2))
            let targetTime = CMTime(seconds: targetSeconds, preferredTimescale: 600)
            let cgImage = try await generator.image(at: targetTime).image

            guard let thumbData = pngData(from: cgImage) else { return nil }
            return (width, height, duration, thumbData)
        } catch {
            return nil
        }
    }

    public static func livePhotoInfo(imageURL: URL, videoURL: URL) async -> (width: Int, height: Int, duration: TimeInterval, thumbnailPNG: Data)? {
        let asset = AVURLAsset(url: videoURL)
        let durationTime = (try? await asset.load(.duration)) ?? .zero
        let duration = CMTimeGetSeconds(durationTime)

        if let data = try? Data(contentsOf: imageURL),
           let encoded = ImageEncoding.encodeSync(data) {
            return (encoded.pixelWidth, encoded.pixelHeight, duration, encoded.thumbnailPNG)
        }

        if let videoInfo = await videoInfo(at: videoURL) {
            return (videoInfo.width, videoInfo.height, duration, videoInfo.thumbnailPNG)
        }

        return nil
    }

    public static func imageLivePhotoIdentifier(at url: URL) -> String? {
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil) else { return nil }
        guard let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any] else { return nil }
        if let makerApple = properties[kCGImagePropertyMakerAppleDictionary] as? [CFString: Any] {
            if let id = makerApple["17" as CFString] as? String {
                return id
            }
        }
        return nil
    }

    public static func videoLivePhotoIdentifier(at url: URL) async -> String? {
        let asset = AVURLAsset(url: url)
        do {
            let formats = try await asset.load(.availableMetadataFormats)
            for format in formats {
                let items = try await asset.loadMetadata(for: format)
                for item in items {
                    let key = (item.key as? String) ?? item.identifier?.rawValue
                    if key == "com.apple.quicktime.content.identifier" || key?.contains("content.identifier") == true {
                        if let str = try await item.load(.stringValue) {
                            return str
                        }
                    }
                }
            }
        } catch {}
        return nil
    }

    public static func pngData(from image: CGImage) -> Data? {
        guard let mutable = CFDataCreateMutable(kCFAllocatorDefault, 0) else { return nil }
        guard let destination = CGImageDestinationCreateWithData(mutable, UTType.png.identifier as CFString, 1, nil) else {
            return nil
        }
        CGImageDestinationAddImage(destination, image, nil)
        guard CGImageDestinationFinalize(destination) else { return nil }
        return mutable as Data
    }
}
