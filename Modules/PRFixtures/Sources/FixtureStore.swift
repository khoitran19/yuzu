import Foundation
import PRModels

public enum FixtureError: Error, LocalizedError, Equatable {
    case unsafePath(String)
    case unreadableContents(String)

    public var errorDescription: String? {
        switch self {
        case let .unsafePath(path): "The fixture cannot store the path \(path)."
        case let .unreadableContents(path): "The fixture file \(path) is not UTF-8 text."
        }
    }
}

/// A directory with `snapshot.json` and raw files at `contents/<oid>/<path>`.
public struct FixtureStore: Sendable {
    public let directory: URL

    public init(directory: URL) {
        self.directory = directory
    }

    public var snapshotURL: URL { directory.appending(path: "snapshot.json") }
    public var contentsURL: URL { directory.appending(path: "contents", directoryHint: .isDirectory) }

    public func readSnapshot() throws -> PullRequestSnapshot {
        try Self.decoder.decode(PullRequestSnapshot.self, from: Data(contentsOf: snapshotURL))
    }

    public func writeSnapshot(_ snapshot: PullRequestSnapshot) throws {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try Self.encoder.encode(snapshot).write(to: snapshotURL, options: .atomic)
    }

    /// Returns `nil` when the fixture has no file for `oid` and `path`.
    public func contents(oid: String, path: String) throws -> String? {
        let url = try contentURL(oid: oid, path: path)
        guard FileManager.default.fileExists(atPath: url.path(percentEncoded: false)) else { return nil }
        guard let text = String(data: try Data(contentsOf: url), encoding: .utf8) else {
            throw FixtureError.unreadableContents(path)
        }
        return text
    }

    public func writeContents(_ text: String, oid: String, path: String) throws {
        let url = try contentURL(oid: oid, path: path)
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try Data(text.utf8).write(to: url, options: .atomic)
    }

    /// Deletes the directory and everything in it, then creates it again.
    public func reset() throws {
        let manager = FileManager.default
        if manager.fileExists(atPath: directory.path(percentEncoded: false)) {
            try manager.removeItem(at: directory)
        }
        try manager.createDirectory(at: directory, withIntermediateDirectories: true)
    }

    public func write(_ fixture: Fixture) throws {
        try reset()
        try writeSnapshot(fixture.snapshot)
        for content in fixture.contents {
            try writeContents(content.text, oid: content.oid, path: content.path)
        }
    }

    public func read() throws -> Fixture {
        let root = contentsURL.standardizedFileURL.path(percentEncoded: false)
        var files: [FixtureContent] = []
        if let enumerator = FileManager.default.enumerator(
            at: contentsURL, includingPropertiesForKeys: [.isRegularFileKey]
        ) {
            for case let url as URL in enumerator
            where try url.resourceValues(forKeys: [.isRegularFileKey]).isRegularFile == true {
                let relative = url.standardizedFileURL.path(percentEncoded: false).dropFirst(root.count)
                let parts = relative.split(separator: "/", maxSplits: 1)
                guard parts.count == 2, let text = try contents(oid: String(parts[0]), path: String(parts[1])) else {
                    continue
                }
                files.append(FixtureContent(oid: String(parts[0]), path: String(parts[1]), text: text))
            }
        }
        return Fixture(snapshot: try readSnapshot(), contents: files)
    }

    private func contentURL(oid: String, path: String) throws -> URL {
        let components = path.split(separator: "/", omittingEmptySubsequences: false)
        guard !oid.isEmpty, !oid.contains("/"), !path.hasPrefix("/"),
              components.allSatisfy({ !$0.isEmpty && $0 != "." && $0 != ".." })
        else { throw FixtureError.unsafePath("\(oid)/\(path)") }
        return contentsURL.appending(path: oid, directoryHint: .isDirectory).appending(path: path)
    }

    static let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }()

    static let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()
}
