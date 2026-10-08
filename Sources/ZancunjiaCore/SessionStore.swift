import Foundation

/// The on-disk session cache. Removal is nonisolated so a signal handler can call it.
public nonisolated enum SessionCache {
    public static let root: URL = FileManager.default
        .urls(for: .cachesDirectory, in: .userDomainMask)[0]
        .appending(path: "Zancunjia", directoryHint: .isDirectory)

    /// Removes every staged file. A missing folder counts as success.
    @discardableResult
    public static func discardAll() -> Bool {
        remove(root)
    }

    @discardableResult
    static func remove(_ url: URL) -> Bool {
        do {
            try FileManager.default.removeItem(at: url)
            return true
        } catch {
            let ns = error as NSError
            if ns.domain == NSCocoaErrorDomain && ns.code == NSFileNoSuchFileError {
                return true
            }
            ShelfLog.main.error("清空缓存失败 \(ns.localizedDescription, privacy: .public)")
            return false
        }
    }
}

public final class SessionStore {
    let directory: URL
    private let fileManager = FileManager.default

    init(directory: URL) throws {
        self.directory = directory
        try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
    }

    /// A fresh cache folder. Anything left by a previous launch is removed first,
    /// including files that survived a force quit.
    public static func launchSession() throws -> SessionStore {
        SessionCache.discardAll()
        let directory = SessionCache.root.appending(path: UUID().uuidString, directoryHint: .isDirectory)
        return try SessionStore(directory: directory)
    }

    func write(_ data: Data, named name: String) throws -> URL {
        let url = directory.appending(path: name)
        try data.write(to: url, options: .atomic)
        return url
    }

    func copyFile(from sourceURL: URL, named name: String) throws -> URL {
        let destinationURL = directory.appending(path: name)
        try? fileManager.removeItem(at: destinationURL)
        try fileManager.copyItem(at: sourceURL, to: destinationURL)
        return destinationURL
    }

    func discard() {
        let path = directory.path
        if !SessionCache.remove(directory) {
            ShelfLog.main.error("会话目录还在 \(path, privacy: .public)")
        }
    }
}
