import DiffEngine
import Foundation
import PRModels
import Testing
@testable import PRFixtures

struct SyntheticPullRequestTests {
    static let fixture = SyntheticPullRequest.make(fileCount: 300, changedLines: 20_000, seed: 1)

    var snapshot: PullRequestSnapshot { Self.fixture.snapshot }

    @Test func sameSeedGivesSameOutput() {
        let first = SyntheticPullRequest.make(fileCount: 50, changedLines: 1_000, seed: 1)
        #expect(first == SyntheticPullRequest.make(fileCount: 50, changedLines: 1_000, seed: 1))
        #expect(first != SyntheticPullRequest.make(fileCount: 50, changedLines: 1_000, seed: 2))
    }

    @Test func matchesRequestedSize() {
        #expect(snapshot.files.count == 300)
        #expect(snapshot.files.reduce(0) { $0 + $1.additions + $1.deletions } == 20_000)
        let pullRequest = snapshot.pullRequest
        #expect(pullRequest.changedFiles == 300)
        #expect(pullRequest.additions == snapshot.files.reduce(0) { $0 + $1.additions })
        #expect(pullRequest.deletions == snapshot.files.reduce(0) { $0 + $1.deletions })
        #expect(Set(snapshot.files.map(\.path)).count == 300)
    }

    @Test func coversReviewEdgeCases() {
        let files = snapshot.files
        let patches = files.compactMap(\.patch)
        #expect(Set(files.map(\.status)).isSuperset(of: [.added, .removed, .modified, .renamed]))
        #expect(Set(files.map(\.viewedState)) == [.viewed, .unviewed, .dismissed])
        #expect(files.contains { $0.path.hasSuffix(".png") && $0.patch == nil })
        #expect(files.contains { $0.patch == nil && $0.additions > 0 })
        #expect(files.contains { $0.status == .renamed && $0.patch == nil && $0.previousPath != nil })
        #expect(files.contains { $0.path.contains("/__tests__/") && $0.path.hasSuffix(".spec.ts") })
        #expect(Set(files.map { ($0.path as NSString).pathExtension }).isSuperset(of: ["ts", "swift", "sql", "md", "json", "yml"]))
        #expect(files.filter { $0.path.hasPrefix("apps/") }.allSatisfy { $0.path.hasPrefix("apps/platform/gateway/src/") })
        #expect(patches.contains { $0.contains("\t") })
        #expect(patches.contains { $0.split(separator: "\n").contains { $0.count >= 300 } })
        #expect(patches.contains { $0.contains("注文") || $0.contains("订单") })
        #expect(patches.contains { $0.contains("🚚") || $0.contains("📦") })
        #expect(patches.contains { $0.contains("\\ No newline at end of file") })
        #expect(patches.contains { $0.split(separator: "\n").count { $0.hasPrefix("@@") } >= 4 })

        let threads = snapshot.threads
        #expect(Set(threads.compactMap { $0.line == nil ? nil : $0.side }) == [.left, .right])
        #expect(Set(threads.map(\.isResolved)) == [true, false])
        #expect(threads.contains { $0.comments.count > 1 })
        #expect(threads.contains { $0.startLine != nil })
        #expect(threads.contains { $0.isOutdated && $0.line == nil })
        #expect(threads.contains { thread in thread.comments.contains { $0.bodyText.contains("\n\n") } })
    }

    @Test func patchHunkCountsMatchHeaders() throws {
        for file in snapshot.files {
            guard let patch = file.patch else { continue }
            let hunks = try RawHunk.parse(patch)
            let diff = FileDiffBuilder.build(patch: patch)
            #expect(diff.hunks.count == hunks.count, "\(file.path)")
            for (raw, parsed) in zip(hunks, diff.hunks) {
                #expect(raw.oldLines.count == raw.oldCount && raw.newLines.count == raw.newCount, "\(file.path) \(parsed.headerText)")
                let rows = parsed.rows
                #expect(rows.count { $0.left != nil } == parsed.oldCount, "\(file.path) \(parsed.headerText)")
                #expect(rows.count { $0.right != nil } == parsed.newCount, "\(file.path) \(parsed.headerText)")
            }
            #expect(hunks.reduce(0) { $0 + $1.additions } == file.additions, "\(file.path)")
            #expect(hunks.reduce(0) { $0 + $1.deletions } == file.deletions, "\(file.path)")
        }
    }

    @Test func threadsPointAtDiffLines() throws {
        let files = Dictionary(uniqueKeysWithValues: snapshot.files.map { ($0.path, $0) })
        for thread in snapshot.threads where !thread.isOutdated {
            let patch = try #require(files[thread.path]?.patch, "\(thread.id)")
            let rows = FileDiffBuilder.build(patch: patch).hunks.flatMap(\.rows)
            let numbers = Set(rows.compactMap { thread.side == .left ? $0.left?.number : $0.right?.number })
            let line = try #require(thread.line, "\(thread.id)")
            #expect(numbers.contains(line), "\(thread.id) \(thread.path):\(line)")
            if let startLine = thread.startLine {
                #expect(startLine < line && (startLine...line).allSatisfy(numbers.contains), "\(thread.id)")
            }
        }
    }

    @Test func patchesApplyToRecordedContents() throws {
        let pullRequest = snapshot.pullRequest
        let contents = Dictionary(uniqueKeysWithValues: Self.fixture.contents.map { ("\($0.oid)/\($0.path)", $0.text) })
        for file in snapshot.files {
            guard let patch = file.patch else { continue }
            let base = file.status == .added ? "" : try #require(contents["\(pullRequest.baseOid)/\(file.previousPath ?? file.path)"])
            let head = file.status == .removed ? "" : try #require(contents["\(pullRequest.headOid)/\(file.path)"])
            #expect(try RawHunk.apply(patch, to: base) == head, "\(file.path)")
        }
    }

    @Test func largeFilesHaveBothVersions() throws {
        let pullRequest = snapshot.pullRequest
        let contents = Dictionary(uniqueKeysWithValues: Self.fixture.contents.map { ("\($0.oid)/\($0.path)", $0.text) })
        let large = snapshot.files.filter { $0.patch == nil && $0.additions + $0.deletions > 0 }
        #expect(!large.isEmpty)
        for file in large {
            let old = try #require(contents["\(pullRequest.baseOid)/\(file.path)"])
            let new = try #require(contents["\(pullRequest.headOid)/\(file.path)"])
            let rows = FileDiffBuilder.build(old: old, new: new).hunks.flatMap(\.rows)
            #expect(rows.count { $0.right?.kind == .addition } == file.additions, "\(file.path)")
            #expect(rows.count { $0.left?.kind == .deletion } == file.deletions, "\(file.path)")
        }
    }

    @Test func textFilesHaveContentsAndBinaryFilesDoNot() {
        let pullRequest = snapshot.pullRequest
        let keys = Set(Self.fixture.contents.map { "\($0.oid)/\($0.path)" })
        for file in snapshot.files {
            let isBinary = FixtureRecorder.isBinary(file)
            let baseKey = "\(pullRequest.baseOid)/\(file.previousPath ?? file.path)"
            let headKey = "\(pullRequest.headOid)/\(file.path)"
            #expect(keys.contains(baseKey) == (!isBinary && file.status != .added), "\(file.path)")
            #expect(keys.contains(headKey) == (!isBinary && file.status != .removed), "\(file.path)")
        }
    }
}

/// An independent patch reader, so the tests do not trust `PatchWriter`.
struct RawHunk {
    enum ParseError: Error { case badHeader(String), lineOutsideHunk(String) }

    let oldStart: Int
    let oldCount: Int
    let newStart: Int
    let newCount: Int
    var lines: [(marker: Character, text: Substring, hasNewline: Bool)] = []

    var oldLines: [Substring] { lines.filter { $0.marker != "+" }.map(\.text) }
    var newLines: [Substring] { lines.filter { $0.marker != "-" }.map(\.text) }
    var additions: Int { lines.count { $0.marker == "+" } }
    var deletions: Int { lines.count { $0.marker == "-" } }

    static func parse(_ patch: String) throws -> [RawHunk] {
        var hunks: [RawHunk] = []
        for line in patch.split(separator: "\n", omittingEmptySubsequences: false) {
            if line.hasPrefix("@@ ") {
                let ranges = line.split(separator: " ")
                guard ranges.count >= 4, let old = range(ranges[1].dropFirst()), let new = range(ranges[2].dropFirst()) else {
                    throw ParseError.badHeader(String(line))
                }
                hunks.append(RawHunk(oldStart: old.0, oldCount: old.1, newStart: new.0, newCount: new.1))
            } else if line == "\\ No newline at end of file", !hunks.isEmpty, !hunks[hunks.count - 1].lines.isEmpty {
                hunks[hunks.count - 1].lines[hunks[hunks.count - 1].lines.count - 1].hasNewline = false
            } else if let marker = line.first, "+- ".contains(marker), !hunks.isEmpty {
                hunks[hunks.count - 1].lines.append((marker, line.dropFirst(), true))
            } else {
                throw ParseError.lineOutsideHunk(String(line))
            }
        }
        return hunks
    }

    /// Applies the hunks to `base` and returns the new text, with the newline state the patch records.
    static func apply(_ patch: String, to base: String) throws -> String {
        var baseLines = base.split(separator: "\n", omittingEmptySubsequences: false)
        let baseHasNewline = baseLines.last == ""
        if baseHasNewline || base.isEmpty { baseLines.removeLast() }
        var output: [(text: Substring, hasNewline: Bool)] = []
        var cursor = 0
        for hunk in try parse(patch) {
            let start = hunk.oldCount == 0 ? hunk.oldStart : hunk.oldStart - 1
            output += baseLines[cursor..<start].map { ($0, true) }
            cursor = start
            for line in hunk.lines {
                if line.marker != "+" {
                    guard cursor < baseLines.count, baseLines[cursor] == line.text else { return "<mismatch at \(cursor + 1)>" }
                    cursor += 1
                }
                if line.marker != "-" { output.append((line.text, line.hasNewline)) }
            }
        }
        output += baseLines[cursor...].enumerated().map { index, text in
            (text, cursor + index < baseLines.count - 1 || baseHasNewline)
        }
        return output.map { $0.text + ($0.hasNewline ? "\n" : "") }.joined()
    }

    private static func range(_ text: Substring) -> (Int, Int)? {
        let numbers = text.split(separator: ",").map { Int($0) }
        guard let start = numbers.first ?? nil else { return nil }
        return (start, numbers.count > 1 ? numbers[1] ?? -1 : 1)
    }
}
