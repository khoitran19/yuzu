import DiffEngine
import DiffView
import Foundation
import GitHubKit
import Observation
import os
import PRModels
import ReviewRules

@MainActor
@Observable
public final class PRDetailModel {
    public enum Phase: Equatable {
        case loading
        case loaded
        case failed(String)
    }

    public enum Tab: String, CaseIterable, Sendable {
        case summary = "Summary"
        case files = "Files changed"
    }

    public let ref: PRRef
    public private(set) var phase: Phase = .loading
    public private(set) var pullRequest: PullRequest?
    public private(set) var viewedPaths: Set<String> = []
    public private(set) var fileCount = 0
    public private(set) var errorBanner: String?
    /// Set when GitHub returned fewer files than the pull request changes.
    public private(set) var incompleteNotice: String?
    public var tab: Tab = .files

    @ObservationIgnored public let filesController = FilesChangedViewController()
    @ObservationIgnored public var onLoaded: ((PullRequest) -> Void)?
    @ObservationIgnored private let service: any PullRequestService
    @ObservationIgnored private let highlighter: (any SyntaxHighlighting)?
    @ObservationIgnored private let rules: ReviewRules
    @ObservationIgnored private var snapshot: PullRequestSnapshot?
    @ObservationIgnored private var highlightTask: Task<Void, Never>?
    @ObservationIgnored private var items: [String: DiffFileItem] = [:]
    /// Increments on every content change of a file; results computed for an older generation are dropped.
    @ObservationIgnored private var generations: [String: Int] = [:]
    @ObservationIgnored private var expansions: [String: Task<Void, Never>] = [:]
    @ObservationIgnored private var headLines: [String: [String]] = [:]
    @ObservationIgnored private var mergeBase: String?
    @ObservationIgnored private var viewedGenerations: [String: Int] = [:]
    @ObservationIgnored private var viewedSync: Task<Void, Never>?
    @ObservationIgnored private let signposter = OSSignposter(subsystem: "dev.khoitran.prviewer", category: "PRDetail")

    public init(ref: PRRef, service: any PullRequestService, highlighter: (any SyntaxHighlighting)?, rules: ReviewRules) {
        self.ref = ref
        self.service = service
        self.highlighter = highlighter
        self.rules = rules
        filesController.onToggleViewed = { [weak self] path, viewed in self?.setViewed(viewed, paths: [path]) }
        filesController.onLoadFullDiff = { [weak self] path in self?.loadFullDiff(path) }
        filesController.onExpand = { [weak self] path, hunk in self?.expand(path, hunk: hunk) }
    }

    public var viewedCount: Int { viewedPaths.count }

    public func load() async {
        phase = .loading
        let loadState = signposter.beginInterval("load", "\(self.ref.displayName)")
        do {
            var snapshot = try await service.snapshot(of: ref)
            signposter.endInterval("load", loadState)
            let matcher = rules.matcher
            let autoViewed = snapshot.files
                .filter { $0.viewedState != .viewed && matcher.isAutoViewed(file: $0.path) }
                .map(\.path)
            let autoViewedSet = Set(autoViewed)
            for index in snapshot.files.indices where autoViewedSet.contains(snapshot.files[index].path) {
                snapshot.files[index].viewedState = .viewed
            }
            self.snapshot = snapshot
            pullRequest = snapshot.pullRequest
            fileCount = snapshot.files.count
            viewedPaths = Set(snapshot.files.filter { $0.viewedState == .viewed }.map(\.path))
            let missing = snapshot.pullRequest.changedFiles - snapshot.files.count
            incompleteNotice = missing > 0
                ? "GitHub returns at most 3,000 files. \(missing) of \(snapshot.pullRequest.changedFiles) changed files are not shown."
                : nil

            let order = filesController.setTreeFiles(snapshot.files, matcher: matcher)
            let buildState = signposter.beginInterval("build")
            let items = await Self.buildItems(snapshot, order: order)
            signposter.endInterval("build", buildState)
            filesController.setDiffFiles(items)
            self.items = Dictionary(items.map { ($0.file.path, $0) }, uniquingKeysWith: { first, _ in first })
            generations = [:]
            phase = .loaded
            onLoaded?(snapshot.pullRequest)
            startHighlighting(items)
            if !autoViewed.isEmpty { sync(viewed: true, paths: autoViewed) }
        } catch {
            signposter.endInterval("load", loadState)
            phase = .failed(error.localizedDescription)
        }
    }

    public func setViewed(_ viewed: Bool, paths: [String]) {
        apply(viewed: viewed, paths: paths)
        sync(viewed: viewed, paths: paths)
    }

    public func setAllCollapsed(_ collapsed: Bool) {
        filesController.setAllCollapsed(collapsed)
    }

    public func dismissError() {
        errorBanner = nil
    }

    public func dismissIncompleteNotice() {
        incompleteNotice = nil
    }

    /// Shows unchanged lines above `hunk`, or after the last hunk when `hunk` is `nil`.
    /// Expansions of one file run in order, so each one starts from the previous result.
    public func expand(_ path: String, hunk: Int?) {
        guard let pullRequest, items[path] != nil else { return }
        let previous = expansions[path]
        expansions[path] = Task {
            await previous?.value
            do {
                let lines = try await headFileLines(path, oid: pullRequest.headOid)
                guard let item = items[path], case let .diff(diff) = item.content else { return }
                let generation = generations[path, default: 0]
                let expanded = await Task.detached(priority: .userInitiated) {
                    hunk.map { diff.expandingGap(before: $0, newFileLines: lines) } ?? diff.expandingTail(newFileLines: lines)
                }.value
                guard generations[path, default: 0] == generation, var current = items[path] else { return }
                current.content = .diff(expanded)
                current.tailExpandable = expanded.trailingLineCount(newFileLineCount: lines.count) > 0
                current.highlights = nil
                install(current)
            } catch {
                errorBanner = "Could not load \(path): \(error.localizedDescription)"
            }
        }
    }

    // MARK: Viewed state

    private func apply(viewed: Bool, paths: [String]) {
        for path in paths {
            if viewed { viewedPaths.insert(path) } else { viewedPaths.remove(path) }
            items[path]?.file.viewedState = viewed ? .viewed : .unviewed
        }
        filesController.setViewed(viewed, paths: paths)
    }

    /// Sends mutations in order. A failure reverts only failed paths that the user has not changed since.
    private func sync(viewed: Bool, paths: [String]) {
        guard let id = snapshot?.pullRequest.nodeID, !paths.isEmpty else { return }
        var sent: [String: Int] = [:]
        for path in paths {
            let generation = viewedGenerations[path, default: 0] + 1
            viewedGenerations[path] = generation
            sent[path] = generation
        }
        let previous = viewedSync
        viewedSync = Task {
            await previous?.value
            do {
                try await service.setViewed(viewed, paths: paths, pullRequestID: id)
            } catch {
                let failed = if case let GitHubError.partialFailure(failedPaths) = error { failedPaths } else { paths }
                let revert = failed.filter { viewedGenerations[$0] == sent[$0] }
                if !revert.isEmpty { apply(viewed: !viewed, paths: revert) }
                errorBanner = "GitHub did not save the Viewed state of \(failed.count) file\(failed.count == 1 ? "" : "s"): \(error.localizedDescription)"
            }
        }
    }

    // MARK: File content

    /// Replaces a file's content and highlights it in the background.
    private func install(_ item: DiffFileItem) {
        let path = item.file.path
        let generation = generations[path, default: 0] + 1
        generations[path] = generation
        items[path] = item
        filesController.updateDiffFile(item)
        guard let highlighter, case .diff = item.content else { return }
        Task {
            let highlights = await Task.detached(priority: .userInitiated) { DiffItemFactory.highlights(for: item, using: highlighter) }.value
            guard let highlights, generations[path] == generation else { return }
            items[path]?.highlights = highlights
            filesController.updateHighlights([path: highlights])
        }
    }

    private func headFileLines(_ path: String, oid: String) async throws -> [String] {
        if let cached = headLines[path] { return cached }
        let text = try await service.fileContents(of: ref, oid: oid, path: path) ?? ""
        let lines = await Task.detached(priority: .userInitiated) { FileDiffBuilder.lines(of: text) }.value
        headLines[path] = lines
        return lines
    }

    private func mergeBaseOid(_ pullRequest: PullRequest) async throws -> String {
        if let mergeBase { return mergeBase }
        let oid = try await service.mergeBaseOid(of: ref, base: pullRequest.baseOid, head: pullRequest.headOid)
        mergeBase = oid
        return oid
    }

    private func loadFullDiff(_ path: String) {
        guard let pullRequest, var loading = items[path] else { return }
        let file = loading.file
        loading.content = .loading
        install(loading)
        Task {
            let content: DiffFileItem.Content
            do {
                let base = try await mergeBaseOid(pullRequest)
                async let old = file.status == .added ? "" : service.fileContents(of: ref, oid: base, path: file.previousPath ?? path)
                async let new = file.status == .removed ? "" : service.fileContents(of: ref, oid: pullRequest.headOid, path: path)
                if let old = try await old, let new = try await new {
                    content = .diff(await Task.detached(priority: .userInitiated) { FileDiffBuilder.build(old: old, new: new) }.value)
                } else {
                    content = .binary
                }
            } catch {
                content = .failed(error.localizedDescription)
            }
            guard var current = items[path] else { return }
            current.content = content
            install(current)
        }
    }

    // MARK: Background work

    private nonisolated static func buildItems(_ snapshot: PullRequestSnapshot, order: [String]) async -> [DiffFileItem] {
        await Task.detached(priority: .userInitiated) {
            DiffItemFactory.items(for: snapshot, order: order)
        }.value
    }

    /// Highlights the content that `load` installed; files replaced since then keep their newer highlights.
    private func startHighlighting(_ items: [DiffFileItem]) {
        guard let highlighter else { return }
        highlightTask?.cancel()
        let state = signposter.beginInterval("highlight")
        highlightTask = Task {
            let stream = Self.highlightStream(items, highlighter: highlighter)
            for await batch in stream {
                let current = batch.filter { generations[$0.key, default: 0] == 0 }
                for (path, highlights) in current { self.items[path]?.highlights = highlights }
                filesController.updateHighlights(current)
            }
            signposter.endInterval("highlight", state)
        }
    }

    /// Highlights in parallel and yields batches so visible rows recolor while the rest continue.
    private nonisolated static func highlightStream(_ items: [DiffFileItem], highlighter: any SyntaxHighlighting) -> AsyncStream<[String: SideHighlights]> {
        AsyncStream { continuation in
            let task = Task.detached(priority: .userInitiated) {
                let width = max(2, ProcessInfo.processInfo.activeProcessorCount - 1)
                await withTaskGroup(of: (String, SideHighlights?).self) { group in
                    var next = 0
                    var batch: [String: SideHighlights] = [:]
                    var lastFlush = ContinuousClock.now
                    func enqueue() {
                        guard next < items.count else { return }
                        let item = items[next]
                        next += 1
                        group.addTask { (item.file.path, DiffItemFactory.highlights(for: item, using: highlighter)) }
                    }
                    for _ in 0..<width { enqueue() }
                    for await (path, highlights) in group {
                        if Task.isCancelled { break }
                        if let highlights { batch[path] = highlights }
                        if ContinuousClock.now - lastFlush > .milliseconds(50) {
                            continuation.yield(batch)
                            batch = [:]
                            lastFlush = .now
                        }
                        enqueue()
                    }
                    if !batch.isEmpty { continuation.yield(batch) }
                }
                continuation.finish()
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }
}
