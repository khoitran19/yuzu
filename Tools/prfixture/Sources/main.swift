import Foundation
import GitHubKit
import PRFixtures
import PRModels

let usage = """
usage: prfixture record <PR link or owner/repo#N> --out <dir>
       prfixture synth --files <N> --lines <N> --seed <N> --out <dir>
"""

struct UsageError: LocalizedError {
    let description: String
    var errorDescription: String? { description }
}

func options(_ arguments: ArraySlice<String>) throws -> (positional: [String], named: [String: String]) {
    var positional: [String] = []
    var named: [String: String] = [:]
    var iterator = arguments.makeIterator()
    while let argument = iterator.next() {
        if argument.hasPrefix("--") {
            guard let value = iterator.next() else { throw UsageError(description: "\(argument) needs a value") }
            named[String(argument.dropFirst(2))] = value
        } else {
            positional.append(argument)
        }
    }
    return (positional, named)
}

func require(_ named: [String: String], _ key: String) throws -> String {
    guard let value = named[key] else { throw UsageError(description: "missing --\(key)") }
    return value
}

func integer(_ named: [String: String], _ key: String) throws -> Int {
    guard let value = Int(try require(named, key)), value >= 0 else { throw UsageError(description: "--\(key) must be a number") }
    return value
}

func gitHubToken() throws -> String {
    if let token = ProcessInfo.processInfo.environment["PRVIEWER_GITHUB_TOKEN"], !token.isEmpty { return token }
    let process = Process()
    let pipe = Pipe()
    process.executableURL = URL(filePath: "/usr/bin/env")
    process.arguments = ["gh", "auth", "token"]
    process.standardOutput = pipe
    try process.run()
    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    process.waitUntilExit()
    let token = String(decoding: data, as: UTF8.self).trimmingCharacters(in: .whitespacesAndNewlines)
    guard process.terminationStatus == 0, !token.isEmpty else {
        throw UsageError(description: "set PRVIEWER_GITHUB_TOKEN or sign in with `gh auth login`")
    }
    return token
}

func directorySummary(_ store: FixtureStore) throws -> String {
    let snapshot = try store.readSnapshot()
    var bytes = 0
    let keys: [URLResourceKey] = [.fileSizeKey, .isRegularFileKey]
    for case let url as URL in FileManager.default.enumerator(at: store.directory, includingPropertiesForKeys: keys) ?? .init() {
        let values = try url.resourceValues(forKeys: Set(keys))
        if values.isRegularFile == true { bytes += values.fileSize ?? 0 }
    }
    let changed = snapshot.files.reduce(0) { $0 + $1.additions + $1.deletions }
    return "\(snapshot.files.count) files, \(changed) changed lines, \(snapshot.threads.count) threads, \(bytes) bytes"
}

func run() async throws {
    let arguments = CommandLine.arguments.dropFirst()
    guard let command = arguments.first else { throw UsageError(description: usage) }
    let (positional, named) = try options(arguments.dropFirst())
    let store = FixtureStore(directory: URL(filePath: try require(named, "out"), directoryHint: .isDirectory))
    let clock = ContinuousClock()
    let start = clock.now

    switch command {
    case "record":
        guard positional.count == 1, let ref = PRRef(string: positional[0]) else {
            throw UsageError(description: "record needs one pull request link or owner/repo#N")
        }
        let summary = try await FixtureRecorder.record(ref, from: GitHubClient(token: try gitHubToken()), to: store)
        for skipped in summary.skipped { print("skipped \(skipped)") }
        print("recorded \(ref.displayName): \(summary.contentCount) content files")
    case "synth":
        let fixture = SyntheticPullRequest.make(
            fileCount: try integer(named, "files"),
            changedLines: try integer(named, "lines"),
            seed: UInt64(try integer(named, "seed"))
        )
        try store.write(fixture)
        print("wrote \(fixture.snapshot.pullRequest.ref.displayName)")
    default:
        throw UsageError(description: usage)
    }
    print("\(store.directory.path(percentEncoded: false)): \(try directorySummary(store)) in \(clock.now - start)")
}

do {
    try await run()
} catch {
    FileHandle.standardError.write(Data("prfixture: \(error.localizedDescription)\n".utf8))
    exit(1)
}
