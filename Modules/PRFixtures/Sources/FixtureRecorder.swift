import Foundation
import GitHubKit
import PRModels

public enum FixtureRecorder {
    public struct Summary: Sendable, Equatable {
        public let mergeBaseOid: String
        public let fileCount: Int
        public let contentCount: Int
        /// `<oid>/<path>` of each file the recorder did not store, with the reason.
        public let skipped: [String]
    }

    /// Records the snapshot, the merge base, and the merge base and head contents of every text file.
    public static func record(
        _ ref: PRRef,
        from service: some PullRequestService,
        to store: FixtureStore,
        maxFileBytes: Int = 1_000_000,
        concurrency: Int = 8
    ) async throws -> Summary {
        let snapshot = try await service.snapshot(of: ref)
        try store.reset()
        try store.writeSnapshot(snapshot)
        let pullRequest = snapshot.pullRequest
        let mergeBase = try await service.mergeBaseOid(of: ref, base: pullRequest.baseOid, head: pullRequest.headOid)
        try store.writeMergeBaseOid(mergeBase)

        var requests: [(oid: String, path: String)] = []
        var skipped: [String] = []
        for file in snapshot.files {
            if isBinary(file) {
                skipped.append("\(file.path): binary")
                continue
            }
            if file.status != .added { requests.append((mergeBase, file.previousPath ?? file.path)) }
            if file.status != .removed { requests.append((pullRequest.headOid, file.path)) }
        }

        let outcomes = try await withThrowingTaskGroup(of: String?.self) { group in
            var pending = requests.makeIterator()
            func addNext() {
                guard let request = pending.next() else { return }
                group.addTask {
                    guard let text = try await service.fileContents(of: ref, oid: request.oid, path: request.path) else {
                        return "\(request.oid)/\(request.path): missing or binary"
                    }
                    if text.utf8.count > maxFileBytes { return "\(request.oid)/\(request.path): larger than \(maxFileBytes) bytes" }
                    if text.utf8.contains(0) { return "\(request.oid)/\(request.path): binary" }
                    try store.writeContents(text, oid: request.oid, path: request.path)
                    return nil
                }
            }
            for _ in 0..<max(1, concurrency) { addNext() }
            var outcomes: [String?] = []
            while let outcome = try await group.next() {
                outcomes.append(outcome)
                addNext()
            }
            return outcomes
        }
        let failures = outcomes.compactMap(\.self)
        return Summary(
            mergeBaseOid: mergeBase,
            fileCount: snapshot.files.count,
            contentCount: outcomes.count - failures.count,
            skipped: skipped + failures.sorted()
        )
    }

    static func isBinary(_ file: ChangedFile) -> Bool {
        let fileExtension = (file.path as NSString).pathExtension.lowercased()
        if binaryExtensions.contains(fileExtension) { return true }
        return file.patch == nil && file.additions == 0 && file.deletions == 0 && file.status != .renamed
    }

    private static let binaryExtensions: Set<String> = [
        "png", "jpg", "jpeg", "gif", "webp", "ico", "icns", "heic", "pdf", "zip", "gz", "tgz", "woff", "woff2",
        "ttf", "otf", "mp3", "mp4", "mov", "wasm", "a", "dylib", "so", "jar", "car",
    ]
}
