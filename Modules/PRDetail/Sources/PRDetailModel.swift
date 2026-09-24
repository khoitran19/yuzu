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
    public var tab: Tab = .files

    @ObservationIgnored public let filesController = FilesChangedViewController()
    @ObservationIgnored public var onLoaded: ((PullRequest) -> Void)?
    @ObservationIgnored private let service: any PullRequestService
    @ObservationIgnored private let highlighter: (any SyntaxHighlighting)?
    @ObservationIgnored private let rules: ReviewRules
    @ObservationIgnored private var snapshot: PullRequestSnapshot?
    @ObservationIgnored private var highlightTask: Task<Void, Never>?
    @ObservationIgnored private var items: [String: DiffFileItem] = [:]
    @ObservationIgnored private var headLines: [String: [String]] = [:]
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

            let order = filesController.setTreeFiles(snapshot.files, matcher: matcher)
            let buildState = signposter.beginInterval("build")
            let items = await Self.buildItems(snapshot, order: order)
            signposter.endInterval("build", buildState)
            filesController.setDiffFiles(items)
            self.items = Dictionary(items.map { ($0.file.path, $0) }, uniquingKeysWith: { first, _ in first })
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

    private func apply(viewed: Bool, paths: [String]) {
        for path in paths {
            if viewed { viewedPaths.insert(path) } else { viewedPaths.remove(path) }
            items[path]?.file.viewedState = viewed ? .viewed : .unviewed
            filesController.setViewed(viewed, path: path)
        }
    }

    private func sync(viewed: Bool, paths: [String]) {
        guard let id = snapshot?.pullRequest.nodeID else { return }
        Task {
            do {
                try await service.setViewed(viewed, paths: paths, pullRequestID: id)
            } catch {
                apply(viewed: !viewed, paths: paths)
                errorBanner = "GitHub did not save the Viewed state: \(error.localizedDescription)"
            }
        }
    }

    private func expand(_ path: String, hunk: Int?) {
        guard let pullRequest, var item = items[path], case let .diff(diff) = item.content else { return }
        Task {
            do {
                let lines: [String]
                if let cached = headLines[path] {
                    lines = cached
                } else {
                    let text = try await service.fileContents(of: ref, oid: pullRequest.headOid, path: path) ?? ""
                    lines = Self.lines(of: text)
                    headLines[path] = lines
                }
                let expanded = hunk.map { diff.expandingGap(before: $0, newFileLines: lines) } ?? diff.expandingTail(newFileLines: lines)
                item.content = .diff(expanded)
                item.tailExpandable = expanded.trailingLineCount(newFileLineCount: lines.count) > 0
                if let highlighter {
                    let pending = item
                    item.highlights = await Task.detached(priority: .userInitiated) { DiffItemFactory.highlights(for: pending, using: highlighter) }.value
                }
                items[path] = item
                filesController.updateDiffFile(item)
            } catch {
                errorBanner = "Could not load \(path): \(error.localizedDescription)"
            }
        }
    }

    private nonisolated static func lines(of text: String) -> [String] {
        var lines = text.split(separator: "\n", omittingEmptySubsequences: false).map { String($0.hasSuffix("\r") ? $0.dropLast() : $0) }
        if lines.last == "" { lines.removeLast() }
        return lines
    }

    private func loadFullDiff(_ path: String) {
        guard let snapshot, let file = items[path]?.file else { return }
        filesController.updateDiffFile(DiffFileItem(file: file, content: .loading))
        let pr = snapshot.pullRequest
        Task {
            let content: DiffFileItem.Content
            do {
                async let old = file.status == .added ? "" : service.fileContents(of: ref, oid: pr.baseOid, path: file.previousPath ?? path)
                async let new = file.status == .removed ? "" : service.fileContents(of: ref, oid: pr.headOid, path: path)
                if let old = try await old, let new = try await new {
                    content = .diff(await Task.detached(priority: .userInitiated) { FileDiffBuilder.build(old: old, new: new) }.value)
                } else {
                    content = .binary
                }
            } catch {
                content = .failed(error.localizedDescription)
            }
            var item = DiffFileItem(file: file, content: content, threads: snapshot.threads.filter { $0.path == path && $0.line != nil && !$0.isOutdated })
            if let highlighter {
                let pending = item
                item.highlights = await Task.detached(priority: .userInitiated) { DiffItemFactory.highlights(for: pending, using: highlighter) }.value
            }
            items[path] = item
            filesController.updateDiffFile(item)
        }
    }

    // MARK: Background work

    private nonisolated static func buildItems(_ snapshot: PullRequestSnapshot, order: [String]) async -> [DiffFileItem] {
        await Task.detached(priority: .userInitiated) {
            DiffItemFactory.items(for: snapshot, order: order)
        }.value
    }

    private func startHighlighting(_ items: [DiffFileItem]) {
        guard let highlighter else { return }
        highlightTask?.cancel()
        let state = signposter.beginInterval("highlight")
        highlightTask = Task {
            let stream = Self.highlightStream(items, highlighter: highlighter)
            for await batch in stream {
                for (path, highlights) in batch { items[path]?.highlights = highlights }
                filesController.updateHighlights(batch)
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
