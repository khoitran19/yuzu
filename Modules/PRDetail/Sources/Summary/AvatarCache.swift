import CryptoKit
import Foundation

/// Avatar images in memory and on disk. A stale file is served at once and refreshed in the background.
actor AvatarCache {
    typealias Fetch = @Sendable (URL) async throws -> Data

    static let shared = AvatarCache(
        directory: URL.cachesDirectory.appending(path: "dev.khoitran.prviewer/Avatars", directoryHint: .isDirectory),
        fetch: { url in
            let (data, response) = try await URLSession.shared.data(from: url)
            guard (response as? HTTPURLResponse)?.statusCode == 200, !data.isEmpty else { throw URLError(.badServerResponse) }
            return data
        }
    )

    private let directory: URL
    private let maxAge: TimeInterval
    private let fetch: Fetch
    private var memory: [URL: Data] = [:]
    private var inFlight: [URL: Task<Data, Error>] = [:]

    init(directory: URL, maxAge: TimeInterval = 7 * 86_400, fetch: @escaping Fetch) {
        self.directory = directory
        self.maxAge = maxAge
        self.fetch = fetch
    }

    func data(for url: URL) async throws -> Data {
        if let data = memory[url] { return data }
        let file = fileURL(for: url)
        if let data = try? Data(contentsOf: file) {
            memory[url] = data
            let modified = (try? file.resourceValues(forKeys: [.contentModificationDateKey]))?.contentModificationDate ?? .distantPast
            if Date.now.timeIntervalSince(modified) > maxAge { Task { _ = try? await download(url) } }
            return data
        }
        return try await download(url)
    }

    private func download(_ url: URL) async throws -> Data {
        if let running = inFlight[url] { return try await running.value }
        let task = Task { [fetch] in try await fetch(url) }
        inFlight[url] = task
        defer { inFlight[url] = nil }
        let data = try await task.value
        memory[url] = data
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try? data.write(to: fileURL(for: url), options: .atomic)
        return data
    }

    private func fileURL(for url: URL) -> URL {
        let digest = SHA256.hash(data: Data(url.absoluteString.utf8)).map { String(format: "%02x", $0) }.joined()
        return directory.appending(path: digest, directoryHint: .notDirectory)
    }
}
