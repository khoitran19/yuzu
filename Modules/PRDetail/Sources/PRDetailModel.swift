import AppKit
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

    /// A confirmation sheet over the pull request screen.
    public enum ActionSheet: Identifiable, Equatable {
        case review(PullRequestAction.ReviewEvent)
        /// `bypass` merges now past the branch rules. `headOid` is the head the viewer reviewed when the sheet opened.
        case merge(bypass: Bool, headOid: String)

        public var id: String {
            switch self {
            case let .review(event): "review-\(event.rawValue)"
            case let .merge(bypass, _): bypass ? "bypass" : "merge"
            }
        }
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
    public private(set) var hasMarkdownFiles = false
    /// `nil` until the conversation arrives, or when the service has no merge box state.
    public private(set) var mergeStatus: MergeStatus?
    /// The sidebar action that runs now. Only one runs at a time.
    private(set) var runningAction: SidebarAction?
    public var sheet: ActionSheet?
    /// The split button's method; it starts at the repository default and stays for this pull request.
    private var selectedMethod: MergeMethod?
    public var tab: Tab = .files {
        didSet {
            guard tab != oldValue else { return }
            switch tab {
            case .files:
                summaryFocusPending = false
                filesController.diff.focus()
            case .summary: filesController.resignFocus()
            }
        }
    }
    /// The Summary page takes keyboard focus when it is in a window, then calls `summaryDidTakeFocus()`.
    public private(set) var summaryFocusPending = false

    @ObservationIgnored public let filesController = FilesChangedViewController()

    /// Selects `tab` and moves keyboard focus into it: the diff table or the Summary page.
    public func show(_ tab: Tab) {
        self.tab = tab
        switch tab {
        case .files: filesController.diff.focus()
        case .summary:
            filesController.resignFocus()
            summaryFocusPending = true
        }
    }

    public func summaryDidTakeFocus() {
        summaryFocusPending = false
    }
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
    @ObservationIgnored private let statusRefreshInterval: Duration
    @ObservationIgnored private let mergeableRefreshInterval: Duration
    @ObservationIgnored private var statusRefresh: Task<Void, Never>?
    /// Consecutive refreshes while GitHub still computes mergeability.
    @ObservationIgnored private var unknownMergeableRefreshes = 0
    @ObservationIgnored private let refreshRetryInterval: Duration
    @ObservationIgnored private var actionTask: Task<Void, Never>?
    /// The banner of a refresh that failed after an action; a later successful refresh clears it.
    @ObservationIgnored private var refreshFailureBanner: String?
    /// Opens GitHub pages that must not open in the app; tests replace it.
    @ObservationIgnored var openExternal: (URL) -> Void = { NSWorkspace.shared.open($0) }
    @ObservationIgnored private var autoViewedSent: Set<String> = []
    @ObservationIgnored private var previewGeneration = 0
    /// A preview asked for before the details arrived; it needs the head commit.
    @ObservationIgnored private var pendingPreview: String?

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
    @ObservationIgnored private let signposter = OSSignposter(subsystem: "dev.khoitran.yuzu", category: "PRDetail")

    public init(
        ref: PRRef, service: any PullRequestService, highlighter: (any SyntaxHighlighting)?, rules: ReviewRules,
        statusRefreshInterval: Duration = .seconds(15), mergeableRefreshInterval: Duration = .seconds(3),
        refreshRetryInterval: Duration = .seconds(3)
    ) {
        self.ref = ref
        self.service = service
        self.highlighter = highlighter
        self.rules = rules
        self.statusRefreshInterval = statusRefreshInterval
        self.mergeableRefreshInterval = mergeableRefreshInterval
        self.refreshRetryInterval = refreshRetryInterval
        filesController.onToggleViewed = { [weak self] path, viewed in self?.setViewed(viewed, paths: [path]) }
        filesController.onLoadFullDiff = { [weak self] path in self?.loadFullDiff(path) }
        filesController.onExpand = { [weak self] path, hunk in self?.expand(path, hunk: hunk) }
        filesController.onPreview = { [weak self] path in self?.loadPreview(path) }
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
                    receiveConversation(conversation)
                    scheduleStatusRefresh()
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
        applyMergeStatus()
        summaryDocumentStale = true
        rebuildSummary()
        updateIncompleteNotice()
        onDetail?(pullRequest)
        if let path = pendingPreview { loadPreview(path) }
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
        let sidebar = conversation.map { conversation in
            SidebarContent(
                checks: conversation.checks, status: conversation.merge, state: pullRequest.state, isDraft: pullRequest.isDraft,
                method: mergeMethod, running: runningAction, reviewedHead: pullRequest.headOid
            )
        }
        Task {
            let page = await Task.detached(priority: .userInitiated) {
                let now = Date.now
                let timeline = timeline
                    ?? SummaryHTML.timeline(conversation, threads: threads, pullRequestAuthor: pullRequest.author?.login, now: now)
                let sidebar = sidebar.map(SummaryHTML.sidebar) ?? ""
                return SummaryPage(
                    document: document ?? SummaryHTML.document(pullRequest: pullRequest, timeline: timeline, sidebar: sidebar, now: now),
                    timeline: timeline,
                    sidebar: sidebar
                )
            }.value
            guard generation == summaryGeneration else { return }
            if document == nil { summaryDocumentStale = false }
            if timeline == nil { summaryTimelineStale = false }
            summaryPage = page
        }
    }

    private func receiveConversation(_ conversation: Conversation) {
        self.conversation = conversation
        summaryTimelineStale = true
        applyMergeStatus()
        rebuildSummary()
    }

    /// Keeps the timeline HTML; a status without merge fields keeps the last merge box state.
    private func receive(_ status: PullRequestStatus) {
        guard var conversation else { return }
        let merge = status.merge ?? conversation.merge
        guard status.checks != conversation.checks || merge != conversation.merge else { return }
        conversation.checks = status.checks
        conversation.merge = merge
        self.conversation = conversation
        applyMergeStatus()
        rebuildSummary()
    }

    /// Updates the header badge from the merge box state; the Summary document stays.
    private func applyMergeStatus() {
        if conversation?.merge?.headOid != mergeStatus?.headOid { unknownMergeableRefreshes = 0 }
        mergeStatus = conversation?.merge
        guard let merge = mergeStatus, var pullRequest, pullRequest.state != merge.state || pullRequest.isDraft != merge.isDraft
        else { return }
        pullRequest.state = merge.state
        pullRequest.isDraft = merge.isDraft
        self.pullRequest = pullRequest
    }

    /// Reloads the checks and the merge box while they can change without the viewer: a check runs, the pull request is
    /// queued, auto-merge is on, or GitHub still computes mergeability. Stops when the pull request closes or the model is released.
    private func scheduleStatusRefresh() {
        statusRefresh?.cancel()
        guard let delay = nextStatusRefresh() else { return }
        statusRefresh = Task { [weak self, ref, service] in
            try? await Task.sleep(for: delay)
            guard !Task.isCancelled else { return }
            let status = try? await service.status(of: ref)
            guard !Task.isCancelled, let self else { return }
            if let status { self.receive(status) }
            self.scheduleStatusRefresh()
        }
    }

    private func nextStatusRefresh() -> Duration? {
        guard let conversation, (conversation.merge?.state ?? pullRequest?.state ?? .open) == .open else { return nil }
        let merge = conversation.merge
        if merge?.mergeable == .unknown {
            unknownMergeableRefreshes += 1
            if unknownMergeableRefreshes <= 5 { return mergeableRefreshInterval }
        } else {
            unknownMergeableRefreshes = 0
        }
        let changing = conversation.checks.contains { $0.state == .pending } || merge?.queueEntry != nil || merge?.autoMerge != nil
        return changing ? statusRefreshInterval : nil
    }

    // MARK: Pull request actions

    var sidebarState: SidebarState {
        SidebarState(
            status: mergeStatus, state: pullRequest?.state ?? .open, isDraft: pullRequest?.isDraft ?? false,
            reviewedHead: pullRequest?.headOid
        )
    }

    public var allowedMethods: [MergeMethod] { mergeStatus?.allowedMethods ?? [] }

    public var mergeMethod: MergeMethod {
        let allowed = allowedMethods
        if let selectedMethod, allowed.contains(selectedMethod) { return selectedMethod }
        if let status = mergeStatus, allowed.contains(status.defaultMethod) { return status.defaultMethod }
        return allowed.first ?? .merge
    }

    public var isQueued: Bool { mergeStatus?.state == .open && mergeStatus?.queueEntry != nil }

    /// False until the conversation arrives, while an action runs, and for the author.
    public var canReview: Bool {
        conversation != nil && runningAction == nil && sidebarState.canReview
    }

    /// True when the merge box has a primary action: merge, enqueue, or enable auto-merge.
    public var canMerge: Bool {
        runningAction == nil && sidebarState.primary != nil
    }

    /// "Mark as Ready for Review" or "Convert to Draft" when the viewer can change it, else `nil`.
    public var draftToggleTitle: String? {
        let actions = sidebarState.actions
        if actions.contains(.markReady) { return "Mark as Ready for Review" }
        if actions.contains(.convertToDraft) { return "Convert to Draft" }
        return nil
    }

    public func startReview(_ event: PullRequestAction.ReviewEvent) {
        handle(event == .approve ? .approve : .requestChanges)
    }

    /// Runs the primary merge action, as a click on its button does.
    public func runPrimaryMergeAction() {
        if let primary = sidebarState.primary { handle(primary) }
    }

    public func toggleDraft() {
        handle(sidebarState.actions.contains(.markReady) ? .markReady : .convertToDraft)
    }

    public func selectMethod(_ method: MergeMethod) {
        guard allowedMethods.contains(method), method != mergeMethod else { return }
        selectedMethod = method
        rebuildSummary()
    }

    public func submitReview(_ event: PullRequestAction.ReviewEvent, body: String) {
        sheet = nil
        guard canReview, event == .approve || !body.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        run(.review(event, body: body), as: event == .approve ? .approve : .requestChanges)
    }

    /// `nil` title or body lets GitHub use the repository default. Rebase merges send neither.
    /// GitHub refuses the merge when the head is no longer `headOid`.
    public func confirmMerge(method: MergeMethod, title: String?, body: String?, bypass: Bool, headOid: String) {
        sheet = nil
        let button: SidebarAction = bypass ? .bypassMerge : .merge
        guard runningAction == nil, sidebarState.actions.contains(button) else { return }
        selectMethod(method)
        let rebase = method == .rebase
        run(.merge(method, headOid: headOid, title: rebase ? nil : title, body: rebase ? nil : body), as: button)
    }

    /// Clicks in the sidebar. An action the sidebar does not offer now is ignored.
    func handle(_ action: SidebarAction) {
        guard runningAction == nil, sidebarState.actions.contains(action) else { return }
        switch action {
        case .approve: if canReview { sheet = .review(.approve) }
        case .requestChanges: if canReview { sheet = .review(.requestChanges) }
        case .merge: if let headOid { sheet = .merge(bypass: false, headOid: headOid) }
        case .bypassMerge: if let headOid { sheet = .merge(bypass: true, headOid: headOid) }
        case .enqueue: if let headOid { run(.enqueue(headOid: headOid), as: action) }
        case .enableAutoMerge: if let headOid { run(.enableAutoMerge(mergeMethod, headOid: headOid), as: action) }
        case .dequeue: run(.dequeue, as: action)
        case .disableAutoMerge: run(.disableAutoMerge, as: action)
        case .markReady: run(.markReadyForReview, as: action)
        case .convertToDraft: run(.convertToDraft, as: action)
        case .resolveConflicts: openExternal(ref.webURL.appending(path: "conflicts"))
        case .viewMergeQueue: if let url = mergeStatus?.mergeQueueURL { openExternal(url) }
        case .reload: reload()
        case .chooseMethod: break
        }
    }

    private func reload() {
        guard !isRefreshing else { return }
        statusRefresh?.cancel()
        runningAction = .reload
        rebuildSummary()
        actionTask = Task {
            await load()
            runningAction = nil
            rebuildSummary()
        }
    }

    /// Waits for the running action and its refresh; tests use it.
    func settleAction() async {
        await actionTask?.value
    }

    /// The head of the loaded diff: the commit the viewer reviewed.
    private var headOid: String? { pullRequest?.headOid }

    /// Shows the spinner, runs the action, then shows the new state. A review also reloads the timeline.
    private func run(_ action: PullRequestAction, as button: SidebarAction) {
        guard runningAction == nil, let id = pullRequest?.nodeID ?? pullRequestID else { return }
        statusRefresh?.cancel()
        runningAction = button
        rebuildSummary()
        actionTask = Task {
            let isReview = if case .review = action { true } else { false }
            var refreshed = true
            do {
                try await service.perform(action, pullRequestID: id)
                unknownMergeableRefreshes = 0
                refreshed = await refresh(afterReview: isReview)
            } catch {
                errorBanner = "Could not \(button.failureTitle): \(error.localizedDescription)"
            }
            runningAction = nil
            rebuildSummary()
            if refreshed { scheduleStatusRefresh() } else { retryRefresh(afterReview: isReview, remaining: 3) }
        }
    }

    /// Returns false and shows a banner when GitHub did not answer.
    private func refresh(afterReview: Bool) async -> Bool {
        do {
            if afterReview { receiveConversation(try await service.conversation(of: ref)) } else { receive(try await service.status(of: ref)) }
            if let banner = refreshFailureBanner, errorBanner == banner { errorBanner = nil }
            refreshFailureBanner = nil
            return true
        } catch {
            let banner = "Done, but could not refresh from GitHub: \(error.localizedDescription)"
            refreshFailureBanner = banner
            errorBanner = banner
            return false
        }
    }

    /// Retries even when nothing else polls, so the sidebar does not keep offering an action that already ran.
    private func retryRefresh(afterReview: Bool, remaining: Int) {
        statusRefresh?.cancel()
        statusRefresh = Task { [weak self, refreshRetryInterval] in
            try? await Task.sleep(for: refreshRetryInterval)
            guard !Task.isCancelled, let self else { return }
            if await self.refresh(afterReview: afterReview) {
                self.scheduleStatusRefresh()
            } else if remaining > 1 {
                self.retryRefresh(afterReview: afterReview, remaining: remaining - 1)
            }
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
            hasMarkdownFiles = filesController.hasMarkdownFiles
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

    public func toggleMarkdownPreview() {
        filesController.toggleMarkdownPreview()
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
            if filesController.previewPath == path { loadPreview(path) }
        }
    }

    // MARK: Markdown preview

    /// Renders the head version, or the merge-base version of a removed file, off the main actor.
    private func loadPreview(_ path: String) {
        previewGeneration += 1
        let generation = previewGeneration
        guard let pullRequest else {
            pendingPreview = path
            return
        }
        pendingPreview = nil
        guard let item = items[path] else { return }
        let file = item.file
        let changes: MarkdownChanges? = if case let .diff(diff) = item.content, file.status != .added, file.status != .removed {
            MarkdownChanges(diff: diff)
        } else {
            nil
        }
        let status = switch file.status {
        case .added: "New file"
        case .removed: "Deleted file"
        default: ""
        }
        let highlighter = highlighter
        Task {
            do {
                let oid: String
                let source: String
                if file.status == .removed {
                    oid = try await mergeBaseOid(pullRequest)
                    source = try await service.fileContents(of: ref, oid: oid, path: path) ?? ""
                } else {
                    oid = pullRequest.headOid
                    source = try await headFileLines(path, oid: oid).joined(separator: "\n")
                }
                let context = MarkdownHTML.Context(owner: ref.owner, repo: ref.repo, oid: oid, path: path)
                let rendered = await Task.detached(priority: .userInitiated) {
                    MarkdownHTML.render(source: source, changes: changes, context: context, highlighter: highlighter)
                }.value
                guard generation == previewGeneration else { return }
                let changeText = rendered.changedBlocks == 1 ? "1 change" : "\(rendered.changedBlocks) changes"
                filesController.showPreview(MarkdownPreviewPage(
                    path: path, html: MarkdownHTML.document(rendered), context: context,
                    status: status.isEmpty && changes != nil ? changeText : status, changedBlocks: rendered.changedBlocks
                ))
            } catch {
                guard generation == previewGeneration else { return }
                filesController.showPreviewError(path: path, message: error.localizedDescription)
            }
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
