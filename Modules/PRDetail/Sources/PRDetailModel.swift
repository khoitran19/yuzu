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
    /// True while parts from GitHub are still arriving.
    public private(set) var isRefreshing = false
    /// Time from `load()` to the first diff on screen.
    public private(set) var firstPaint: Duration?
    /// Time from `load()` to the last part.
    public private(set) var liveLoad: Duration?
    /// `nil` until the details arrive.
    public private(set) var summaryPage: SummaryPage?
    public var tab: Tab = .files {
        didSet { if tab == .files, oldValue != .files { filesController.diff.focus() } }
    }

    @ObservationIgnored public let filesController = FilesChangedViewController()
    /// Called once when all parts have arrived.
    @ObservationIgnored public var onLoaded: (() -> Void)?
    @ObservationIgnored public var onDetail: ((PullRequest) -> Void)?
    @ObservationIgnored private let service: any PullRequestService
    @ObservationIgnored private let highlighter: (any SyntaxHighlighting)?
    @ObservationIgnored private let rules: ReviewRules
    @ObservationIgnored private var pullRequestID: String?
    @ObservationIgnored private var files: [ChangedFile] = []
    @ObservationIgnored private var threads: [ReviewThread]?
    @ObservationIgnored private var conversation: Conversation?
    @ObservationIgnored private var summaryGeneration = 0
    /// True when `summaryPage.document` does not show the current details.
    @ObservationIgnored private var summaryDocumentStale = true
    /// True when `summaryPage.timeline` does not show the current conversation and threads.
    @ObservationIgnored private var summaryTimelineStale = true
    @ObservationIgnored private let checksRefreshInterval: Duration
    @ObservationIgnored private var checksRefresh: Task<Void, Never>?
    @ObservationIgnored private var autoViewedSent: Set<String> = []

    @ObservationIgnored private var highlightTask: Task<Void, Never>?
    @ObservationIgnored private var items: [String: DiffFileItem] = [:]
    /// Increments on every content change of a file; results computed for an older generation are dropped.
    @ObservationIgnored private var generations: [String: Int] = [:]
    @ObservationIgnored private var expansions: [String: Task<Void, Never>] = [:]
    @ObservationIgnored private var headLines: [String: [String]] = [:]
    @ObservationIgnored private var mergeBase: String?
    @ObservationIgnored private var viewedGenerations: [String: Int] = [:]
    /// Viewed state GitHub last confirmed; a failed request reverts to it.
    @ObservationIgnored private var confirmedViewed: [String: Bool] = [:]
    @ObservationIgnored private var viewedSync: Task<Void, Never>?
    @ObservationIgnored private let signposter = OSSignposter(subsystem: "dev.khoitran.prviewer", category: "PRDetail")

    public init(
        ref: PRRef, service: any PullRequestService, highlighter: (any SyntaxHighlighting)?, rules: ReviewRules,
        checksRefreshInterval: Duration = .seconds(15)
    ) {
        self.ref = ref
        self.service = service
        self.highlighter = highlighter
        self.rules = rules
        self.checksRefreshInterval = checksRefreshInterval
        filesController.onToggleViewed = { [weak self] path, viewed in self?.setViewed(viewed, paths: [path]) }
        filesController.onLoadFullDiff = { [weak self] path in self?.loadFullDiff(path) }
        filesController.onExpand = { [weak self] path, hunk in self?.expand(path, hunk: hunk) }
    }

    public var viewedCount: Int { viewedPaths.count }

    /// Waits for queued Viewed requests; tests use it.
    func settleViewedSync() async {
        await viewedSync?.value
    }

    /// Shows the diff when files and Viewed states arrive; details and threads fill in when they arrive.
    /// On a reload, Viewed changes made since opening win over the loaded states.
    public func load() async {
        let start = ContinuousClock.now
        let loadState = signposter.beginInterval("load", "\(self.ref.displayName)")
        defer { signposter.endInterval("load", loadState) }
        if items.isEmpty { phase = .loading }
        isRefreshing = true
        defer { isRefreshing = false }
        do {
            for try await part in service.parts(of: ref) {
                switch part {
                case let .files(id, files):
                    await receiveFiles(id: id, files: files)
                    if firstPaint == nil { firstPaint = .now - start }
                case let .detail(pullRequest):
                    receiveDetail(pullRequest)
                case let .threads(threads):
                    receiveThreads(threads)
                case let .conversation(conversation):
                    self.conversation = conversation
                    summaryTimelineStale = true
                    rebuildSummary()
                    scheduleChecksRefresh()
                }
            }
            liveLoad = .now - start
            onLoaded?()
        } catch {
            if phase == .loaded {
                errorBanner = "Could not refresh from GitHub: \(error.localizedDescription)"
            } else {
                phase = .failed(error.localizedDescription)
            }
        }
    }

    private func receiveDetail(_ pullRequest: PullRequest) {
        self.pullRequest = pullRequest
        summaryDocumentStale = true
        rebuildSummary()
        updateIncompleteNotice()
        onDetail?(pullRequest)
    }

    /// Builds the HTML off the main actor. Only the newest build is shown.
    /// Parts that did not change keep their HTML, so the web view does not replace them.
    private func rebuildSummary() {
        guard let pullRequest else { return }
        summaryGeneration += 1
        let generation = summaryGeneration
        let conversation = conversation
        let threads = threads ?? []
        let document = summaryDocumentStale ? nil : summaryPage?.document
        let timeline = summaryTimelineStale ? nil : summaryPage?.timeline
        Task {
            let page = await Task.detached(priority: .userInitiated) {
                let now = Date.now
                let timeline = timeline
                    ?? SummaryHTML.timeline(conversation, threads: threads, pullRequestAuthor: pullRequest.author?.login, now: now)
                let checks = SummaryHTML.checks(conversation?.checks ?? [])
                return SummaryPage(
                    document: document ?? SummaryHTML.document(pullRequest: pullRequest, timeline: timeline, checks: checks, now: now),
                    timeline: timeline,
                    checks: checks
                )
            }.value
            guard generation == summaryGeneration else { return }
            if document == nil { summaryDocumentStale = false }
            if timeline == nil { summaryTimelineStale = false }
            summaryPage = page
        }
    }

    /// Reloads only the checks while any check runs. Stops when all finish or the model is released.
    private func scheduleChecksRefresh() {
        checksRefresh?.cancel()
        guard conversation?.checks.contains(where: { $0.state == .pending }) == true else { return }
        checksRefresh = Task { [weak self, ref, service, checksRefreshInterval] in
            try? await Task.sleep(for: checksRefreshInterval)
            guard !Task.isCancelled else { return }
            let checks = try? await service.checks(of: ref)
            guard !Task.isCancelled, let self else { return }
            if let checks, let conversation = self.conversation, checks != conversation.checks {
                self.conversation = Conversation(items: conversation.items, checks: checks)
                self.rebuildSummary()
            }
            self.scheduleChecksRefresh()
        }
    }

    private func updateIncompleteNotice() {
        guard let pullRequest, !files.isEmpty else { return }
        let missing = pullRequest.changedFiles - files.count
        incompleteNotice = missing > 0
            ? "GitHub returns at most 3,000 files. \(missing) of \(pullRequest.changedFiles) changed files are not shown."
            : nil
    }

    private func receiveFiles(id: String, files incoming: [ChangedFile]) async {
        pullRequestID = id
        let matcher = rules.matcher
        var files = incoming
        var autoViewed: [String] = []
        for index in files.indices {
            let path = files[index].path
            confirmedViewed[path] = files[index].viewedState == .viewed
            if viewedGenerations[path, default: 0] > 0 {
                files[index].viewedState = viewedPaths.contains(path) ? .viewed : .unviewed
            } else if files[index].viewedState != .viewed, matcher.isAutoViewed(file: path) {
                files[index].viewedState = .viewed
                if !autoViewedSent.contains(path) { autoViewed.append(path) }
            }
        }

        if !items.isEmpty, Self.sameContent(self.files, files) {
            self.files = files
            let viewedNow = Set(files.filter { $0.viewedState == .viewed }.map(\.path))
            let newlyViewed = viewedNow.subtracting(viewedPaths)
            let newlyUnviewed = viewedPaths.subtracting(viewedNow)
            if !newlyViewed.isEmpty { apply(viewed: true, paths: Array(newlyViewed)) }
            if !newlyUnviewed.isEmpty { apply(viewed: false, paths: Array(newlyUnviewed)) }
        } else {
            self.files = files
            fileCount = files.count
            viewedPaths = Set(files.filter { $0.viewedState == .viewed }.map(\.path))
            let order = filesController.setTreeFiles(files)
            let buildState = signposter.beginInterval("build")
            let built = await Self.buildItems(files, threads: threads ?? [], order: order)
            signposter.endInterval("build", buildState)
            filesController.setDiffFiles(built)
            items = Dictionary(built.map { ($0.file.path, $0) }, uniquingKeysWith: { first, _ in first })
            for path in items.keys { generations[path, default: 0] += 1 }
            phase = .loaded
            startHighlighting(built)
        }
        updateIncompleteNotice()
        if !autoViewed.isEmpty {
            autoViewedSent.formUnion(autoViewed)
            sync(viewed: true, paths: autoViewed)
        }
    }

    private func receiveThreads(_ threads: [ReviewThread]) {
        self.threads = threads
        if conversation != nil {
            summaryTimelineStale = true
            rebuildSummary()
        }
        let byPath = DiffItemFactory.placeableThreads(threads)
        var changed: [DiffFileItem] = []
        for (path, item) in items {
            let placed = byPath[path] ?? []
            guard placed != item.threads else { continue }
            var updated = item
            updated.threads = placed
            items[path] = updated
            changed.append(updated)
        }
        if !changed.isEmpty { filesController.updateDiffFiles(changed) }
    }

    /// Same files and patches: the rows on screen stay, and only Viewed states update.
    private nonisolated static func sameContent(_ lhs: [ChangedFile], _ rhs: [ChangedFile]) -> Bool {
        guard lhs.count == rhs.count else { return false }
        let old = Dictionary(lhs.map { ($0.path, $0) }, uniquingKeysWith: { first, _ in first })
        return rhs.allSatisfy { file in
            guard let previous = old[file.path] else { return false }
            return previous.patch == file.patch && previous.status == file.status && previous.previousPath == file.previousPath
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
        guard let pullRequest, let item = items[path], case let .diff(shown) = item.content else { return }
        // The new-side line that starts the clicked hunk; earlier queued expansions can renumber hunks.
        let boundary = hunk.flatMap { shown.hunks[safe: $0]?.firstNewLine }
        if hunk != nil, boundary == nil { return }
        let previous = expansions[path]
        expansions[path] = Task {
            await previous?.value
            do {
                let lines = try await headFileLines(path, oid: pullRequest.headOid)
                guard let item = items[path], case let .diff(diff) = item.content else { return }
                let generation = generations[path, default: 0]
                var target: Int?
                if let boundary {
                    guard let index = diff.hunks.firstIndex(where: { $0.firstNewLine == boundary }) else { return }
                    target = index
                }
                let hunkIndex = target
                let expanded = await Task.detached(priority: .userInitiated) {
                    hunkIndex.map { diff.expandingGap(before: $0, newFileLines: lines) } ?? diff.expandingTail(newFileLines: lines)
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
        guard let id = pullRequestID, !paths.isEmpty else { return }
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
                for path in paths { confirmedViewed[path] = viewed }
            } catch {
                let failed = if case let GitHubError.partialFailure(failedPaths) = error { failedPaths } else { paths }
                let failedSet = Set(failed)
                for path in paths where !failedSet.contains(path) { confirmedViewed[path] = viewed }
                let revert = failed.filter { viewedGenerations[$0] == sent[$0] }
                for (confirmed, group) in Dictionary(grouping: revert, by: { confirmedViewed[$0] ?? false }) {
                    apply(viewed: confirmed, paths: group)
                }
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

    private nonisolated static func buildItems(_ files: [ChangedFile], threads: [ReviewThread], order: [String]) async -> [DiffFileItem] {
        await Task.detached(priority: .userInitiated) {
            DiffItemFactory.items(files: files, threads: threads, order: order)
        }.value
    }

    /// Highlights the content that `load` installed; files replaced since then keep their newer highlights.
    private func startHighlighting(_ items: [DiffFileItem]) {
        guard let highlighter else { return }
        highlightTask?.cancel()
        let state = signposter.beginInterval("highlight")
        let started = generations
        highlightTask = Task {
            let stream = Self.highlightStream(items, highlighter: highlighter)
            for await batch in stream {
                let current = batch.filter { generations[$0.key] == started[$0.key] }
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

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
