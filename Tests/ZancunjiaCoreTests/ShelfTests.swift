import AppKit
import CoreGraphics
import Foundation
import Testing
@testable import ZancunjiaCore

struct SessionCacheTests {
    @Test func removeDeletesADirectoryAndAcceptsAMissingOne() throws {
        let directory = FileManager.default.temporaryDirectory
            .appending(path: "zancunjia-discard-\(UUID().uuidString)", directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try Data([1, 2, 3]).write(to: directory.appending(path: "截图.png"))

        #expect(SessionCache.remove(directory))
        #expect(!FileManager.default.fileExists(atPath: directory.path))
        #expect(SessionCache.remove(directory))
    }
}

struct ShelfGeometryTests {
    @Test func leftEdgeStaysFlushWithTheVisibleFrame() {
        let visible = CGRect(x: 10, y: 40, width: 1400, height: 900)
        let collapsed = ShelfGeometry.frame(expanded: false, visible: visible, edge: .left)
        let expanded = ShelfGeometry.frame(expanded: true, visible: visible, edge: .left)

        #expect(collapsed.minX == visible.minX)
        #expect(collapsed.width == ShelfGeometry.tabWidth)
        #expect(expanded.minX == visible.minX)
        #expect(expanded.width == ShelfGeometry.expandedWidth)
        #expect(expanded.maxX <= visible.maxX)
        #expect(abs(collapsed.midY - visible.midY) < 0.5)
        #expect(abs(expanded.midY - visible.midY) < 0.5)
    }

    @Test func rightEdgeStaysFlushWithTheVisibleFrame() {
        let visible = CGRect(x: 0, y: 24, width: 1280, height: 800)
        let collapsed = ShelfGeometry.frame(expanded: false, visible: visible, edge: .right)
        let expanded = ShelfGeometry.frame(expanded: true, visible: visible, edge: .right)

        #expect(collapsed.maxX == visible.maxX)
        #expect(expanded.maxX == visible.maxX)
        #expect(expanded.minX < collapsed.minX)
    }

    @Test func sidebarAnchorSlidesVerticallyAndStaysOnScreen() {
        let visible = CGRect(x: 0, y: 20, width: 1200, height: 800)
        let low = ShelfGeometry.frame(expanded: false, visible: visible, edge: .left, anchor: 0.1)
        let high = ShelfGeometry.frame(expanded: false, visible: visible, edge: .left, anchor: 0.95)

        #expect(low.midY < visible.midY)
        #expect(high.midY > visible.midY)
        #expect(low.minY >= visible.minY)
        #expect(high.maxY <= visible.maxY)
        #expect(low.minX == visible.minX)
    }

    @Test func islandHangsFromTheTopCenter() {
        let visible = CGRect(x: 100, y: 40, width: 1600, height: 900)
        let collapsed = ShelfGeometry.frame(
            expanded: false, visible: visible, edge: .left, placement: .island
        )
        let expanded = ShelfGeometry.frame(
            expanded: true, visible: visible, edge: .left, itemCount: 2, placement: .island
        )

        #expect(abs(collapsed.midX - visible.midX) < 1)
        #expect(collapsed.height == 32)
        #expect(collapsed.maxY == visible.maxY)
        #expect(abs(expanded.midX - visible.midX) < 1)
        #expect(expanded.width > collapsed.width)
        #expect(expanded.maxY == visible.maxY)
    }

    @Test func islandSitsInTheNotchUntilItOpens() {
        let full = CGRect(x: 0, y: 0, width: 1728, height: 1117)
        let visible = CGRect(x: 0, y: 0, width: 1728, height: 1084)
        let notch = CGRect(x: 771.5, y: 1085, width: 185, height: 32)
        let collapsed = ShelfGeometry.frame(
            expanded: false, visible: visible, edge: .left, placement: .island, full: full, notch: notch
        )
        let expanded = ShelfGeometry.frame(
            expanded: true, visible: visible, edge: .left, itemCount: 2, placement: .island, full: full, notch: notch
        )

        #expect(abs(collapsed.maxY - full.maxY) < 1)
        #expect(abs(collapsed.minY - notch.minY) < 1)
        #expect(abs(collapsed.height - notch.height) < 1)
        #expect(abs(collapsed.width - (notch.width + 70)) < 1)
        #expect(collapsed.minX < notch.minX)
        #expect(collapsed.maxX > notch.maxX)
        #expect(abs(collapsed.midX - notch.midX) < 1)
        #expect(expanded.maxY == full.maxY)
        #expect(expanded.minY < notch.minY)
        #expect(abs(expanded.width - 548) < 1)
        #expect(abs(expanded.height - 176) < 1)
        #expect(abs(expanded.midX - notch.midX) < 1)
    }

    @Test func islandGrowsWithContentAndCapsItsHeight() {
        let screen = CGRect(x: 0, y: 0, width: 1728, height: 1117)
        let one = ShelfGeometry.frame(
            expanded: true, visible: screen, edge: .left, itemCount: 1, placement: .island, full: screen
        )
        let many = ShelfGeometry.frame(
            expanded: true, visible: screen, edge: .left, itemCount: 20, placement: .island, full: screen
        )

        #expect(one.height == 128)
        #expect(many.height == 380)
    }

    @Test func dockPillSitsInTheGapBesideABottomDock() {
        let screen = CGRect(x: 0, y: 0, width: 1440, height: 900)
        let visible = CGRect(x: 0, y: 64, width: 1440, height: 812)
        let tile = CGRect(x: 520, y: 4, width: 400, height: 56)
        let dock = DockMetrics(tile: tile, side: .bottom, hidden: false)

        let left = ShelfGeometry.frame(
            expanded: false, visible: visible, edge: .left, placement: .dock, full: screen, dock: dock
        )
        let right = ShelfGeometry.frame(
            expanded: false, visible: visible, edge: .right, placement: .dock, full: screen, dock: dock
        )

        #expect(left.maxX <= tile.minX)
        #expect(left.minY >= screen.minY)
        #expect(left.maxY <= visible.minY)
        #expect(tile.minX - left.maxX < 12)
        #expect(right.minX >= tile.maxX)
        #expect(right.minX - tile.maxX < 12)
        #expect(!left.intersects(tile))
        #expect(!right.intersects(tile))
    }

    @Test func dockSheetOpensAboveTheBottomDockWithoutCoveringIt() {
        let screen = CGRect(x: 0, y: 0, width: 1440, height: 900)
        let visible = CGRect(x: 0, y: 64, width: 1440, height: 812)
        let tile = CGRect(x: 520, y: 4, width: 400, height: 56)
        let dock = DockMetrics(tile: tile, side: .bottom, hidden: false)
        let sheet = ShelfGeometry.frame(
            expanded: true, visible: visible, edge: .left, placement: .dock, full: screen, dock: dock
        )

        #expect(sheet.minY >= visible.minY)
        #expect(sheet.maxY <= visible.maxY)
        #expect(sheet.maxX <= tile.minX)
        #expect(!sheet.intersects(tile))
        #expect(sheet.width > 300)
        #expect(sheet.height > 300)
    }

    @Test func fullSideDockPutsTheShelfInsideTheDockBar() {
        let screen = CGRect(x: 0, y: 0, width: 1728, height: 1117)
        let visible = CGRect(x: 0, y: 0, width: 1665, height: 1084)
        let tile = CGRect(x: 1669, y: 32, width: 59, height: 1021)
        let dock = DockMetrics(tile: tile, side: .right, hidden: false)
        let collapsed = ShelfGeometry.frame(
            expanded: false, visible: visible, edge: .left, placement: .dock, full: screen, dock: dock
        )
        let sheet = ShelfGeometry.frame(
            expanded: true, visible: visible, edge: .left, itemCount: 1, placement: .dock, full: screen, dock: dock
        )

        #expect(tile.contains(collapsed))
        #expect(abs(collapsed.minX - tile.minX) < 1)
        #expect(abs(collapsed.width - tile.width) < 1)
        #expect(collapsed.minY <= tile.minY + 1)
        #expect(collapsed.maxY < tile.midY)
        #expect(!visible.contains(collapsed))
        #expect(sheet.maxX <= visible.maxX + 1)
        #expect(!sheet.intersects(tile))
    }

    @Test func hiddenDockIsALipUntilItOpens() {
        let screen = CGRect(x: 0, y: 0, width: 1440, height: 900)
        let visible = CGRect(x: 0, y: 0, width: 1440, height: 876)
        let dock = DockMetrics(tile: CGRect(x: 400, y: -80, width: 640, height: 64), side: .bottom, hidden: true)
        let lip = ShelfGeometry.frame(
            expanded: false, visible: visible, edge: .left, placement: .dock, full: screen, dock: dock
        )
        let sheet = ShelfGeometry.frame(
            expanded: true, visible: visible, edge: .left, placement: .dock, full: screen, dock: dock
        )

        #expect(abs(lip.minY - screen.minY) < 1)
        #expect(lip.height <= 20)
        #expect(lip.minX < 20)
        #expect(sheet.minY == screen.minY)
        #expect(sheet.height > lip.height)
        #expect(sheet.maxY <= visible.maxY)
    }
}

struct ImageEncodingTests {
    @Test func rejectsBytesThatAreNotAnImage() {
        #expect(ImageEncoding.encodeSync(Data([0, 1, 2, 3, 4])) == nil)
    }

    @Test @MainActor func readsSizeAndKeepsAStableHash() throws {
        let png = Fixtures.png(width: 40, height: 24, red: 0.2)
        let first = try #require(ImageEncoding.encodeSync(png))
        let second = try #require(ImageEncoding.encodeSync(png))

        #expect(first.pixelWidth == 40)
        #expect(first.pixelHeight == 24)
        #expect(first.contentHash == second.contentHash)
        #expect(first.png.starts(with: [0x89, 0x50, 0x4E, 0x47]))
    }

    @Test @MainActor func differentPixelsHaveDifferentHashes() throws {
        let red = try #require(ImageEncoding.encodeSync(Fixtures.png(red: 0.2)))
        let blue = try #require(ImageEncoding.encodeSync(Fixtures.png(red: 0.9)))
        #expect(red.contentHash != blue.contentHash)
    }
}

struct ShelfModelTests {
    @Test @MainActor func storesAClipboardImageAndDedupesIt() async throws {
        let store = try makeStore()
        defer { store.discard() }
        let model = ShelfModel(store: store, limit: 100)
        let png = Fixtures.png(red: 0.3)

        await model.importPayloads([png, png])

        #expect(model.items.count == 1)
        let url = try #require(model.items.first?.fileURL)
        #expect(FileManager.default.fileExists(atPath: url.path))
        #expect(model.arrivalCount == 1)
    }

    @Test @MainActor func keepsTheNewestImagesWhenTheShelfIsFull() async throws {
        let store = try makeStore()
        defer { store.discard() }
        let model = ShelfModel(store: store, limit: 2)

        await model.importPayloads([
            Fixtures.png(red: 0.1),
            Fixtures.png(red: 0.5),
            Fixtures.png(red: 0.9),
        ])

        #expect(model.items.count == 2)
        #expect(model.items.allSatisfy { FileManager.default.fileExists(atPath: $0.fileURL.path) })
    }

    @Test @MainActor func clearDeletesTheFiles() async throws {
        let store = try makeStore()
        defer { store.discard() }
        let model = ShelfModel(store: store)
        await model.importPayloads([Fixtures.png(red: 0.4)])
        let url = try #require(model.items.first?.fileURL)

        model.clear()

        #expect(model.items.isEmpty)
        #expect(!FileManager.default.fileExists(atPath: url.path))
    }

    @Test @MainActor func undoRestoresAnUndoableClear() async throws {
        let store = try makeStore()
        defer { store.discard() }
        let model = ShelfModel(store: store)
        await model.importPayloads([Fixtures.png(red: 0.2), Fixtures.png(red: 0.8)])
        let urls = model.items.map(\.fileURL)

        model.clear(undoable: true)

        #expect(model.items.isEmpty)
        #expect(model.canUndo)
        #expect(urls.allSatisfy { FileManager.default.fileExists(atPath: $0.path) })

        model.undo()

        #expect(model.items.count == 2)
        #expect(urls.allSatisfy { FileManager.default.fileExists(atPath: $0.path) })
    }

    @Test @MainActor func selectionBuildsABatchAndTracksRemoval() async throws {
        let store = try makeStore()
        defer { store.discard() }
        let model = ShelfModel(store: store)
        await model.importPayloads([
            Fixtures.png(red: 0.2),
            Fixtures.png(red: 0.5),
            Fixtures.png(red: 0.8),
        ])
        let ids = model.items.map(\.id)

        model.toggleSelection(ids[0])
        model.toggleSelection(ids[2])

        #expect(model.selectedIDs == Set([ids[0], ids[2]]))
        #expect(model.itemsForAction(startingWith: ids[0]).map(\.id) == [ids[0], ids[2]])
        #expect(model.itemsForAction(startingWith: ids[1]).map(\.id) == [ids[1]])

        model.remove(ids[0])

        #expect(model.selectedIDs == Set([ids[2]]))
    }

    @Test @MainActor func copyingDoesNotImportAgain() async throws {
        let store = try makeStore()
        defer { store.discard() }
        let model = ShelfModel(store: store)
        await model.importPayloads([Fixtures.png(red: 0.6)])
        let id = try #require(model.items.first?.id)
        let pasteboard = NSPasteboard(name: NSPasteboard.Name("ZancunjiaTest.\(UUID().uuidString)"))

        model.copy(id, to: pasteboard)

        #expect(model.items.count == 1)
        #expect(!model.claimPasteboard(changeCount: pasteboard.changeCount))
        #expect(pasteboard.data(forType: .png)?.isEmpty == false)
    }

    @Test @MainActor func claimsEachPasteboardGenerationOnce() {
        let store = try! makeStore()
        defer { store.discard() }
        let model = ShelfModel(store: store)

        #expect(model.claimPasteboard(changeCount: 4))
        #expect(!model.claimPasteboard(changeCount: 4))
        model.suppressPasteboard(changeCount: 6)
        #expect(!model.claimPasteboard(changeCount: 6))
        #expect(model.claimPasteboard(changeCount: 7))
    }

    @Test @MainActor func shutdownRemovesTheSessionDirectory() async throws {
        let store = try makeStore()
        let directory = store.directory
        let model = ShelfModel(store: store)
        await model.importPayloads([Fixtures.png(red: 0.7)])

        model.shutdown()

        #expect(model.items.isEmpty)
        #expect(!FileManager.default.fileExists(atPath: directory.path))
    }

    @Test @MainActor func importsAndCopiesLivePhotoWithBothFiles() async throws {
        let store = try makeStore()
        defer { store.discard() }
        let model = ShelfModel(store: store)

        let tempDir = FileManager.default.temporaryDirectory
            .appending(path: "zancunjia-live-\(UUID().uuidString)", directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let imgURL = tempDir.appending(path: "IMG_0001.heic")
        let movURL = tempDir.appending(path: "IMG_0001.mov")
        let png = Fixtures.png(red: 0.5)
        try png.write(to: imgURL)
        try Data("fake-video-bytes".utf8).write(to: movURL)

        await model.importMedia([
            .livePhoto(imageURL: imgURL, videoURL: movURL, width: 40, height: 24, duration: 1.5, thumbnailPNG: png)
        ])

        #expect(model.items.count == 1)
        let item = try #require(model.items.first)
        #expect(item.kind == .livePhoto)
        #expect(item.isLivePhoto)
        #expect(item.pairedVideoURL != nil)
        #expect(item.duration == 1.5)

        // Test copy
        let pb = NSPasteboard(name: NSPasteboard.Name("ZancunjiaTest.\(UUID().uuidString)"))
        model.copy(item.id, to: pb)
        let copiedURLs = pb.readObjects(forClasses: [NSURL.self], options: nil) as? [URL]
        #expect(copiedURLs?.count == 2)
        #expect(copiedURLs?.contains(where: { $0.pathExtension.lowercased() == "heic" || $0.pathExtension.lowercased() == "png" }) == true)
        #expect(copiedURLs?.contains(where: { $0.pathExtension.lowercased() == "mov" }) == true)

        // Test remove deletes both files
        let storedImg = item.fileURL
        let storedMov = try #require(item.pairedVideoURL)
        #expect(FileManager.default.fileExists(atPath: storedImg.path))
        #expect(FileManager.default.fileExists(atPath: storedMov.path))

        model.remove(item.id)
        #expect(!FileManager.default.fileExists(atPath: storedImg.path))
        #expect(!FileManager.default.fileExists(atPath: storedMov.path))
    }

    @Test @MainActor func importsAndCopiesVideo() async throws {
        let store = try makeStore()
        defer { store.discard() }
        let model = ShelfModel(store: store)

        let tempDir = FileManager.default.temporaryDirectory
            .appending(path: "zancunjia-vid-\(UUID().uuidString)", directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let vidURL = tempDir.appending(path: "screen_recording.mp4")
        try Data("fake-video-content".utf8).write(to: vidURL)
        let png = Fixtures.png(red: 0.3)

        await model.importMedia([
            .video(fileURL: vidURL, width: 1920, height: 1080, duration: 12.0, thumbnailPNG: png)
        ])

        #expect(model.items.count == 1)
        let item = try #require(model.items.first)
        #expect(item.kind == .video)
        #expect(item.isVideo)
        #expect(item.duration == 12.0)

        let pb = NSPasteboard(name: NSPasteboard.Name("ZancunjiaTest.\(UUID().uuidString)"))
        model.copy(item.id, to: pb)
        let copiedURLs = pb.readObjects(forClasses: [NSURL.self], options: nil) as? [URL]
        #expect(copiedURLs?.count == 1)
        #expect(copiedURLs?.first?.pathExtension.lowercased() == "mp4")
    }

    @Test @MainActor func keepsDifferentVideosWithTheSameThumbnail() async throws {
        let store = try makeStore()
        defer { store.discard() }
        let model = ShelfModel(store: store)
        let source = FileManager.default.temporaryDirectory
            .appending(path: "zancunjia-video-dedupe-\(UUID().uuidString)", directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: source, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: source) }
        let first = source.appending(path: "first.mov")
        let second = source.appending(path: "second.mov")
        try Data("first video".utf8).write(to: first)
        try Data("second video".utf8).write(to: second)
        let thumbnail = Fixtures.png(red: 0.3)

        await model.importMedia([
            .video(fileURL: first, width: 40, height: 24, duration: 1, thumbnailPNG: thumbnail),
            .video(fileURL: second, width: 40, height: 24, duration: 1, thumbnailPNG: thumbnail),
        ])
        #expect(model.items.count == 2)
        #expect(model.items[0].contentHash != model.items[1].contentHash)
        let firstID = model.items[1].id

        await model.importMedia([.video(fileURL: first, width: 40, height: 24, duration: 1, thumbnailPNG: thumbnail)])
        #expect(model.items.count == 2)
        #expect(model.items[0].id == firstID)
        #expect(model.arrivalCount == 2)
    }

    @Test @MainActor func keepsLivePhotosWithDifferentMotion() async throws {
        let store = try makeStore()
        defer { store.discard() }
        let model = ShelfModel(store: store)
        let source = FileManager.default.temporaryDirectory
            .appending(path: "zancunjia-live-dedupe-\(UUID().uuidString)", directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: source, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: source) }
        let image = source.appending(path: "image.heic")
        let first = source.appending(path: "first.mov")
        let second = source.appending(path: "second.mov")
        let thumbnail = Fixtures.png(red: 0.4)
        try thumbnail.write(to: image)
        try Data("first motion".utf8).write(to: first)
        try Data("second motion".utf8).write(to: second)

        await model.importMedia([
            .livePhoto(imageURL: image, videoURL: first, width: 40, height: 24, duration: 1, thumbnailPNG: thumbnail),
            .livePhoto(imageURL: image, videoURL: second, width: 40, height: 24, duration: 1, thumbnailPNG: thumbnail),
        ])
        #expect(model.items.count == 2)
        #expect(model.items[0].contentHash != model.items[1].contentHash)
    }

    @Test @MainActor func extractsRealVideoIfPresent() async throws {
        // Set SNAPSHELF_TEST_VIDEO to a local video file to run this check.
        guard let path = ProcessInfo.processInfo.environment["SNAPSHELF_TEST_VIDEO"],
              FileManager.default.fileExists(atPath: path) else { return }
        let url = URL(fileURLWithPath: path)
        let info = await MediaExtractor.videoInfo(at: url)
        #expect(info != nil)
        #expect((info?.width ?? 0) > 0)
        #expect((info?.duration ?? 0) > 0)
        #expect((info?.thumbnailPNG.count ?? 0) > 0)
    }
}

struct ClipboardReaderTests {
    @Test @MainActor func readsAPngAndIgnoresPlainText() throws {
        let name = NSPasteboard.Name("ZancunjiaTest.\(UUID().uuidString)")
        let pasteboard = NSPasteboard(name: name)
        let png = Fixtures.png(red: 0.25)
        pasteboard.clearContents()
        pasteboard.setData(png, forType: .png)

        let payloads = ClipboardReader.payloads(from: pasteboard)
        #expect(payloads.count == 1)
        #expect(payloads.first == png)

        pasteboard.clearContents()
        pasteboard.setString("hello", forType: .string)
        #expect(ClipboardReader.payloads(from: pasteboard).isEmpty)
    }

    @Test @MainActor func dragWriterRoundTripsTheFile() throws {
        let directory = FileManager.default.temporaryDirectory
            .appending(path: "zancunjia-writer-\(UUID().uuidString)", directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appending(path: "截图 01.png")
        let png = Fixtures.png(red: 0.8)
        try png.write(to: url)

        let pasteboard = NSPasteboard(name: NSPasteboard.Name("ZancunjiaTest.\(UUID().uuidString)"))
        pasteboard.clearContents()
        #expect(pasteboard.writeObjects([ScratchFileWriter(url: url)]))

        let urls = pasteboard.readObjects(forClasses: [NSURL.self], options: nil) as? [URL]
        #expect(urls?.first?.standardizedFileURL == url.standardizedFileURL)
        #expect(pasteboard.data(forType: .png) == png)
    }

    @Test @MainActor func dragWriterConvertsNonPNGImageBytes() throws {
        let directory = FileManager.default.temporaryDirectory
            .appending(path: "zancunjia-writer-image-\(UUID().uuidString)", directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appending(path: "photo.jpg")
        let rep = try #require(NSBitmapImageRep(data: Fixtures.png(red: 0.8)))
        let jpeg = try #require(rep.representation(using: .jpeg, properties: [:]))
        try jpeg.write(to: url)

        let pasteboard = NSPasteboard(name: NSPasteboard.Name("ZancunjiaTest.\(UUID().uuidString)"))
        pasteboard.clearContents()
        #expect(pasteboard.writeObjects([ScratchFileWriter(url: url)]))
        let png = try #require(pasteboard.data(forType: .png))
        #expect(png.starts(with: [0x89, 0x50, 0x4E, 0x47]))
        #expect(png != jpeg)
    }

    @Test @MainActor func failedRawVideoLeavesNoTemporaryFile() async {
        let pasteboard = NSPasteboard(name: NSPasteboard.Name("ZancunjiaTest.\(UUID().uuidString)"))
        pasteboard.clearContents()
        pasteboard.setData(Data("invalid movie".utf8), forType: NSPasteboard.PasteboardType("com.apple.quicktime-movie"))
        let before = (try? FileManager.default.contentsOfDirectory(atPath: SessionCache.root.path)) ?? []

        _ = await ClipboardReader.readMedia(from: pasteboard)

        let after = (try? FileManager.default.contentsOfDirectory(atPath: SessionCache.root.path)) ?? []
        #expect(Set(after.filter { $0.hasPrefix("clip-") }) == Set(before.filter { $0.hasPrefix("clip-") }))
    }

    @Test @MainActor func ignoresPrivateClipboardMedia() async {
        let pasteboard = NSPasteboard(name: NSPasteboard.Name("ZancunjiaTest.\(UUID().uuidString)"))
        let concealed = NSPasteboard.PasteboardType("org.nspasteboard.ConcealedType")
        pasteboard.declareTypes([.png, concealed], owner: nil)
        pasteboard.setData(Fixtures.png(red: 0.5), forType: .png)
        pasteboard.setString("private", forType: concealed)

        #expect(ClipboardReader.payloads(from: pasteboard).isEmpty)
        #expect(await ClipboardReader.readMedia(from: pasteboard).isEmpty)
    }

    @Test @MainActor func readMediaPairsLivePhotoByFilename() async throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appending(path: "zancunjia-pb-live-\(UUID().uuidString)", directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let imgURL = tempDir.appending(path: "IMG_9999.png")
        let movURL = tempDir.appending(path: "IMG_9999.mov")
        let png = Fixtures.png(red: 0.4)
        try png.write(to: imgURL)
        try Data("dummy-mov".utf8).write(to: movURL)

        let pb = NSPasteboard(name: NSPasteboard.Name("ZancunjiaTest.\(UUID().uuidString)"))
        pb.clearContents()
        pb.writeObjects([imgURL as NSURL, movURL as NSURL])

        let payloads = await ClipboardReader.readMedia(from: pb)
        #expect(payloads.count == 1)
        if case .livePhoto(let imageURL, let videoURL, _, _, _, _) = payloads.first {
            #expect(imageURL.lastPathComponent == "IMG_9999.png")
            #expect(videoURL.lastPathComponent == "IMG_9999.mov")
        } else {
            Issue.record("Expected livePhoto payload")
        }
    }
}

@MainActor
private enum Fixtures {
    static func png(width: Int = 40, height: Int = 24, red: CGFloat) -> Data {
        let rep = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: width,
            pixelsHigh: height,
            bitsPerSample: 8,
            samplesPerPixel: 4,
            hasAlpha: true,
            isPlanar: false,
            colorSpaceName: .deviceRGB,
            bytesPerRow: 0,
            bitsPerPixel: 0
        )!
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
        NSColor(calibratedRed: red, green: 0.42, blue: 0.28, alpha: 1).setFill()
        NSRect(x: 0, y: 0, width: width, height: height).fill()
        NSGraphicsContext.restoreGraphicsState()
        return rep.representation(using: .png, properties: [:])!
    }
}

@MainActor
private func makeStore() throws -> SessionStore {
    let directory = FileManager.default.temporaryDirectory
        .appending(path: "zancunjia-\(UUID().uuidString)", directoryHint: .isDirectory)
    return try SessionStore(directory: directory)
}
