import AppKit
import UniformTypeIdentifiers

/// Puts file URL and media bytes on the drag/copy pasteboard.
/// Browsers, Figma, Photos, and Finder each look for a different type.
public final class ScratchFileWriter: NSObject, NSPasteboardWriting {
    public let url: URL
    public let isVideo: Bool

    public init(url: URL, isVideo: Bool? = nil) {
        self.url = url
        if let isVideo {
            self.isVideo = isVideo
        } else {
            let ext = url.pathExtension
            if let type = UTType(filenameExtension: ext) {
                self.isVideo = type.conforms(to: .movie) || type.conforms(to: .video) || type.conforms(to: .quickTimeMovie) || type.conforms(to: .mpeg4Movie)
            } else {
                self.isVideo = ["mov", "mp4", "m4v", "webm", "avi"].contains(ext.lowercased())
            }
        }
    }

    public func writableTypes(for pasteboard: NSPasteboard) -> [NSPasteboard.PasteboardType] {
        if isVideo {
            return [
                .fileURL,
                NSPasteboard.PasteboardType("com.apple.quicktime-movie"),
                NSPasteboard.PasteboardType("public.movie"),
                NSPasteboard.PasteboardType("public.mpeg-4")
            ]
        } else {
            return [.fileURL, .png]
        }
    }

    public func pasteboardPropertyList(forType type: NSPasteboard.PasteboardType) -> Any? {
        switch type {
        case .fileURL:
            return (url as NSURL).pasteboardPropertyList(forType: .fileURL)
        case .png:
            guard let data = try? Data(contentsOf: url) else { return nil }
            return ImageEncoding.encodeSync(data)?.png
        case NSPasteboard.PasteboardType("com.apple.quicktime-movie"),
             NSPasteboard.PasteboardType("public.movie"),
             NSPasteboard.PasteboardType("public.mpeg-4"):
            return try? Data(contentsOf: url)
        default:
            return nil
        }
    }
}
