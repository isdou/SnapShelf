import AppKit
import CryptoKit
import Foundation
import Observation

public enum ScratchItemKind: String, Sendable, Codable {
    case image
    case livePhoto
    case video
}

public struct ScratchItem: Identifiable {
    public let id: UUID
    public let fileURL: URL
    public let pairedVideoURL: URL?
    public let createdAt: Date
    public let pixelWidth: Int
    public let pixelHeight: Int
    public let duration: TimeInterval?
    public let contentHash: String
    public let thumbnailPNG: Data
    public let kind: ScratchItemKind

    public var isLivePhoto: Bool { kind == .livePhoto }
    public var isVideo: Bool { kind == .video }

    public init(
        id: UUID,
        fileURL: URL,
        pairedVideoURL: URL? = nil,
        createdAt: Date,
        pixelWidth: Int,
        pixelHeight: Int,
        duration: TimeInterval? = nil,
        contentHash: String,
        thumbnailPNG: Data,
        kind: ScratchItemKind = .image
    ) {
        self.id = id
        self.fileURL = fileURL
        self.pairedVideoURL = pairedVideoURL
        self.createdAt = createdAt
        self.pixelWidth = pixelWidth
        self.pixelHeight = pixelHeight
        self.duration = duration
        self.contentHash = contentHash
        self.thumbnailPNG = thumbnailPNG
        self.kind = kind
    }
}

@Observable
public final class ShelfModel {
    public private(set) var items: [ScratchItem] = []
    public private(set) var selectedIDs: Set<UUID> = []
    public private(set) var notice: String?
    public private(set) var arrivalCount = 0

    public var canUndo: Bool { undoManager.canUndo }
    public var undoActionName: String { undoManager.undoActionName }

    private let store: SessionStore
    private let limit: Int
    private let undoManager = UndoManager()
    private var lastChangeCount = -1
    private var ignoredChangeCount: Int?
    private var alive = true
    private var noticeTask: Task<Void, Never>?

    public init(store: SessionStore, limit: Int = 100) {
        self.store = store
        self.limit = limit
    }

    /// Records a pasteboard generation. Returns true when its image should be imported.
    /// Synchronous so two timer ticks can't import the same copy.
    public func claimPasteboard(changeCount: Int) -> Bool {
        guard changeCount != lastChangeCount else { return false }
        lastChangeCount = changeCount
        return changeCount != ignoredChangeCount
    }

    public func suppressPasteboard(changeCount: Int) {
        ignoredChangeCount = changeCount
        lastChangeCount = changeCount
    }

    public func importPayloads(_ payloads: [Data]) async {
        await importMedia(payloads.map { .image(data: $0, sourceURL: nil) })
    }

    public func importMedia(_ payloads: [MediaPayload]) async {
        guard alive, !Task.isCancelled else { return }
        if payloads.count > limit {
            flash("一次最多放 \(limit) 个")
        }
        for payload in payloads.prefix(limit) {
            guard alive, !Task.isCancelled else { return }
            switch payload {
            case .image(let data, let sourceURL):
                guard let encoded = await ImageEncoding.encode(data) else {
                    ShelfLog.main.error("Skipped an unreadable image, \(data.count, privacy: .public) bytes")
                    continue
                }
                guard alive, !Task.isCancelled else { return }
                addImageEncoded(encoded, originalURL: sourceURL)

            case .video(let fileURL, let width, let height, let duration, let thumbnailPNG):
                await addVideo(fileURL: fileURL, width: width, height: height, duration: duration, thumbnailPNG: thumbnailPNG)

            case .livePhoto(let imageURL, let videoURL, let width, let height, let duration, let thumbnailPNG):
                await addLivePhoto(imageURL: imageURL, videoURL: videoURL, width: width, height: height, duration: duration, thumbnailPNG: thumbnailPNG)
            }
        }
    }

    public func copy(_ id: UUID, to pasteboard: NSPasteboard = .general) {
        guard let item = items.first(where: { $0.id == id }) else { return }
        pasteboard.clearContents()
        switch item.kind {
        case .image:
            pasteboard.writeObjects([ScratchFileWriter(url: item.fileURL)])
            flash("已复制")
        case .video:
            pasteboard.writeObjects([ScratchFileWriter(url: item.fileURL, isVideo: true)])
            flash("已复制视频")
        case .livePhoto:
            if let videoURL = item.pairedVideoURL {
                pasteboard.writeObjects([
                    ScratchFileWriter(url: item.fileURL),
                    ScratchFileWriter(url: videoURL, isVideo: true)
                ])
            } else {
                pasteboard.writeObjects([ScratchFileWriter(url: item.fileURL)])
            }
            flash("已复制实况照片")
        }
        suppressPasteboard(changeCount: pasteboard.changeCount)
    }

    public func toggleSelection(_ id: UUID) {
        guard items.contains(where: { $0.id == id }) else { return }
        if !selectedIDs.insert(id).inserted {
            selectedIDs.remove(id)
        }
    }

    public func clearSelection() {
        selectedIDs.removeAll()
    }

    public func itemsForAction(startingWith id: UUID) -> [ScratchItem] {
        guard let item = items.first(where: { $0.id == id }) else { return [] }
        guard selectedIDs.contains(id) else { return [item] }
        return items.filter { selectedIDs.contains($0.id) }
    }

    public func remove(_ id: UUID, undoable: Bool = false) {
        removeItems(ids: [id], undoable: undoable, actionName: "移除")
    }

    public func clear(undoable: Bool = false) {
        removeItems(ids: items.map(\.id), undoable: undoable, actionName: "清空")
    }

    public func undo() {
        undoManager.undo()
    }

    public func shutdown() {
        alive = false
        noticeTask?.cancel()
        undoManager.removeAllActions()
        selectedIDs.removeAll()
        items.removeAll()
        store.discard()
    }

    private struct RemovedItem {
        let index: Int
        let item: ScratchItem
    }

    private func removeItems(ids: [UUID], undoable: Bool, actionName: String) {
        let ids = Set(ids)
        let removed = items.enumerated().compactMap { index, item in
            ids.contains(item.id) ? RemovedItem(index: index, item: item) : nil
        }
        guard !removed.isEmpty else { return }
        items.removeAll { ids.contains($0.id) }
        selectedIDs.subtract(ids)

        if undoable {
            undoManager.registerUndo(withTarget: self) { target in
                target.restore(removed, actionName: actionName)
            }
            undoManager.setActionName(actionName)
            flash("已\(actionName) · ⌘Z 撤销")
        } else {
            deleteFiles(for: removed.map(\.item))
        }
    }

    private func restore(_ removed: [RemovedItem], actionName: String) {
        for entry in removed.sorted(by: { $0.index < $1.index }) {
            items.insert(entry.item, at: min(entry.index, items.count))
        }
        undoManager.registerUndo(withTarget: self) { target in
            target.removeItems(ids: removed.map(\.item.id), undoable: true, actionName: actionName)
        }
        undoManager.setActionName(actionName)
        flash("已恢复")
    }

    private func deleteFiles(for items: [ScratchItem]) {
        for item in items {
            try? FileManager.default.removeItem(at: item.fileURL)
            if let videoURL = item.pairedVideoURL {
                try? FileManager.default.removeItem(at: videoURL)
            }
        }
    }

    private func addLivePhoto(imageURL: URL, videoURL: URL, width: Int, height: Int, duration: TimeInterval, thumbnailPNG: Data) async {
        let hash: String
        do {
            hash = try await Self.hashFiles([imageURL, videoURL])
        } catch is CancellationError {
            return
        } catch {
            ShelfLog.main.error("Could not read Live Photo: \(error.localizedDescription, privacy: .public)")
            return
        }
        guard alive, !Task.isCancelled else { return }
        if let index = items.firstIndex(where: { $0.kind == .livePhoto && $0.contentHash == hash }) {
            let existing = items.remove(at: index)
            items.insert(existing, at: 0)
            return
        }

        let id = UUID()
        let createdAt = Date()
        let base = filenameBase(for: createdAt, id: id, prefix: "实况照片")
        let imgExt = imageURL.pathExtension.isEmpty ? "heic" : imageURL.pathExtension
        let videoExt = videoURL.pathExtension.isEmpty ? "mov" : videoURL.pathExtension
        do {
            let destImageURL = try store.copyFile(from: imageURL, named: "\(base).\(imgExt)")
            let destVideoURL = try store.copyFile(from: videoURL, named: "\(base).\(videoExt)")
            let item = ScratchItem(
                id: id,
                fileURL: destImageURL,
                pairedVideoURL: destVideoURL,
                createdAt: createdAt,
                pixelWidth: width,
                pixelHeight: height,
                duration: duration,
                contentHash: hash,
                thumbnailPNG: thumbnailPNG,
                kind: .livePhoto
            )
            items.insert(item, at: 0)
            arrivalCount += 1
            ShelfLog.main.info("Stored Live Photo \(width, privacy: .public)×\(height, privacy: .public)")
        } catch {
            ShelfLog.main.error("Could not store Live Photo: \(error.localizedDescription, privacy: .public)")
            return
        }
        trimExcessItems()
    }

    private func addVideo(fileURL: URL, width: Int, height: Int, duration: TimeInterval, thumbnailPNG: Data) async {
        let hash: String
        do {
            hash = try await Self.hashFiles([fileURL])
        } catch is CancellationError {
            return
        } catch {
            ShelfLog.main.error("Could not read Video: \(error.localizedDescription, privacy: .public)")
            return
        }
        guard alive, !Task.isCancelled else { return }
        if let index = items.firstIndex(where: { $0.kind == .video && $0.contentHash == hash }) {
            let existing = items.remove(at: index)
            items.insert(existing, at: 0)
            return
        }

        let id = UUID()
        let createdAt = Date()
        let base = filenameBase(for: createdAt, id: id, prefix: "视频")
        let videoExt = fileURL.pathExtension.isEmpty ? "mov" : fileURL.pathExtension
        do {
            let destVideoURL = try store.copyFile(from: fileURL, named: "\(base).\(videoExt)")
            let item = ScratchItem(
                id: id,
                fileURL: destVideoURL,
                pairedVideoURL: nil,
                createdAt: createdAt,
                pixelWidth: width,
                pixelHeight: height,
                duration: duration,
                contentHash: hash,
                thumbnailPNG: thumbnailPNG,
                kind: .video
            )
            items.insert(item, at: 0)
            arrivalCount += 1
            ShelfLog.main.info("Stored Video \(width, privacy: .public)×\(height, privacy: .public)")
        } catch {
            ShelfLog.main.error("Could not store Video: \(error.localizedDescription, privacy: .public)")
            return
        }
        trimExcessItems()
    }

    @concurrent nonisolated private static func hashFiles(_ urls: [URL]) async throws -> String {
        var combined = SHA256()
        for url in urls {
            var fileHash = SHA256()
            let file = try FileHandle(forReadingFrom: url)
            defer { try? file.close() }
            while let chunk = try file.read(upToCount: 1_048_576), !chunk.isEmpty {
                try Task.checkCancellation()
                fileHash.update(data: chunk)
            }
            combined.update(data: Data(fileHash.finalize()))
        }
        return combined.finalize().map { String(format: "%02x", $0) }.joined()
    }

    private func addImageEncoded(_ encoded: EncodedImage, originalURL: URL?) {
        if let index = items.firstIndex(where: { $0.contentHash == encoded.contentHash }) {
            let existing = items.remove(at: index)
            items.insert(existing, at: 0)
            return
        }

        let id = UUID()
        let createdAt = Date()
        let base = filenameBase(for: createdAt, id: id, prefix: "截图")
        do {
            let url = try store.write(encoded.png, named: "\(base).png")
            let item = ScratchItem(
                id: id,
                fileURL: url,
                pairedVideoURL: nil,
                createdAt: createdAt,
                pixelWidth: encoded.pixelWidth,
                pixelHeight: encoded.pixelHeight,
                duration: nil,
                contentHash: encoded.contentHash,
                thumbnailPNG: encoded.thumbnailPNG,
                kind: .image
            )
            items.insert(item, at: 0)
            arrivalCount += 1
            ShelfLog.main.info("Stored \(encoded.pixelWidth, privacy: .public)×\(encoded.pixelHeight, privacy: .public)")
        } catch {
            ShelfLog.main.error("Could not write screenshot: \(error.localizedDescription, privacy: .public)")
            return
        }
        trimExcessItems()
    }

    private func filenameBase(for date: Date, id: UUID, prefix: String) -> String {
        let parts = Calendar.current.dateComponents([.hour, .minute, .second], from: date)
        let clock = String(format: "%02d-%02d-%02d", parts.hour ?? 0, parts.minute ?? 0, parts.second ?? 0)
        return "\(prefix) \(clock)-\(id.uuidString.prefix(4))"
    }

    private func trimExcessItems() {
        while items.count > limit {
            let dropped = items.removeLast()
            selectedIDs.remove(dropped.id)
            try? FileManager.default.removeItem(at: dropped.fileURL)
            if let videoURL = dropped.pairedVideoURL {
                try? FileManager.default.removeItem(at: videoURL)
            }
        }
    }

    private func flash(_ text: String) {
        notice = text
        noticeTask?.cancel()
        noticeTask = Task {
            do {
                try await Task.sleep(for: .seconds(1.3))
            } catch {
                return
            }
            guard !Task.isCancelled else { return }
            notice = nil
        }
    }
}
