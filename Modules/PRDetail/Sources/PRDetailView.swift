import AppKit
import AppShortcuts
import PRModels
import SwiftUI

public struct PRDetailView: View {
    @Bindable var model: PRDetailModel

    public init(model: PRDetailModel) {
        self.model = model
    }

    public var body: some View {
        VStack(spacing: 0) {
            PRHeaderView(ref: model.ref, pullRequest: model.pullRequest, isQueued: model.isQueued)
            tabBar
            Divider()
            if let banner = model.errorBanner {
                ErrorBanner(message: banner, dismiss: model.dismissError)
            }
            if let notice = model.incompleteNotice {
                ErrorBanner(message: notice, dismiss: model.dismissIncompleteNotice)
            }
            ZStack {
                FilesChangedView(controller: model.filesController)
                    .opacity(model.tab == .files && model.phase == .loaded ? 1 : 0)
                    .allowsHitTesting(model.tab == .files)
                if let page = model.summaryPage {
                    SummaryView(
                        page: page, focusPending: model.summaryFocusPending, onFocus: model.summaryDidTakeFocus,
                        methods: MethodMenu(allowed: model.allowedMethods, selected: model.mergeMethod, select: model.selectMethod),
                        onAction: model.handle
                    )
                    .opacity(model.tab == .summary ? 1 : 0)
                    .allowsHitTesting(model.tab == .summary)
                } else if model.tab == .summary, model.phase == .loaded {
                    ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                switch model.phase {
                case .loading:
                    ProgressView("Loading \(model.ref.displayName)…")
                        .controlSize(.large)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                case let .failed(message):
                    ContentUnavailableView {
                        Label("Could not load the pull request", systemImage: "exclamationmark.triangle")
                    } description: {
                        Text(message)
                    } actions: {
                        Button("Try Again") { Task { await model.load() } }
                    }
                case .loaded:
                    EmptyView()
                }
            }
        }
        .task(id: model.ref) {
            if model.pullRequest == nil { await model.load() }
        }
        .sheet(item: $model.sheet) { sheet in
            switch sheet {
            case let .review(event):
                ReviewSheet(event: event, submit: { model.submitReview(event, body: $0) }, cancel: { model.sheet = nil })
            case .finishReview:
                finishReviewSheet
            case let .merge(bypass, headOid):
                if let pullRequest = model.pullRequest {
                    MergeSheet(
                        pullRequest: pullRequest, methods: model.allowedMethods, method: model.mergeMethod, bypass: bypass,
                        confirm: { model.confirmMerge(method: $0, title: $1, body: $2, bypass: bypass, headOid: headOid) },
                        cancel: { model.sheet = nil }
                    )
                }
            }
        }
    }

    private var finishReviewSheet: FinishReviewSheet {
        let model = model
        let canDiscard = model.pendingReviewID != nil && model.commentsInFlight == 0
        let discard: (() -> Void)? = canDiscard ? { model.discardPendingReview() } : nil
        return FinishReviewSheet(
            pendingCount: model.pendingCommentCount, canApprove: model.sidebarState.canReview,
            canSubmit: { model.canSubmit($0, body: $1) }, submit: { model.submitReview($0, body: $1) },
            discard: discard, cancel: { model.sheet = nil }
        )
    }

    private var tabBar: some View {
        HStack(spacing: 4) {
            ForEach(PRDetailModel.Tab.allCases, id: \.self) { tab in
                TabButton(
                    title: tab.rawValue,
                    count: tab == .files && model.fileCount > 0 ? model.fileCount : nil,
                    selected: model.tab == tab
                ) { model.tab = tab }
                    .fixedSize()
                    .keyboardShortcut((tab == .summary ? Shortcut.summaryTab : Shortcut.filesTab).keyboardShortcut)
                    .accessibilityIdentifier("prDetail.tab.\(tab == .summary ? "summary" : "files")")
            }
            Spacer()
            if model.isRefreshing, model.phase == .loaded {
                ProgressView().controlSize(.mini).help("Updating from GitHub")
            }
            if model.tab == .files, model.phase == .loaded {
                FinishReviewButton(pendingCount: model.pendingCommentCount) { model.sheet = .finishReview }
                ViewedProgress(viewed: model.viewedCount, total: model.fileCount)
                Menu {
                    Button(Shortcut.collapseAll.title) { model.setAllCollapsed(true) }
                        .keyboardShortcut(Shortcut.collapseAll.keyboardShortcut)
                    Button(Shortcut.expandAll.title) { model.setAllCollapsed(false) }
                        .keyboardShortcut(Shortcut.expandAll.keyboardShortcut)
                    Divider()
                    Button(Shortcut.toggleFileTree.title) { model.filesController.toggleFileTree() }
                        .keyboardShortcut(Shortcut.toggleFileTree.keyboardShortcut)
                    Button(Shortcut.toggleMarkdownPreview.title) { model.toggleMarkdownPreview() }
                        .keyboardShortcut(Shortcut.toggleMarkdownPreview.keyboardShortcut)
                        .disabled(!model.hasMarkdownFiles)
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
                .menuStyle(.borderlessButton)
                .menuIndicator(.hidden)
                .fixedSize()
                .help("File actions")
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 6)
    }
}

struct PRHeaderView: View {
    let ref: PRRef
    let pullRequest: PullRequest?
    let isQueued: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(pullRequest?.title ?? ref.displayName)
                    .font(.title2.weight(.semibold))
                    .textSelection(.enabled)
                    .lineLimit(2)
                Text("#\(String(ref.number))")
                    .font(.title2)
                    .foregroundStyle(.secondary)
            }
            if let pullRequest {
                HStack(spacing: 8) {
                    StateBadge(state: pullRequest.state, isDraft: pullRequest.isDraft, isQueued: isQueued)
                    Group {
                        Text(pullRequest.author?.login ?? "ghost").bold()
                            + Text(" wants to merge \(pullRequest.commitCount) commit\(pullRequest.commitCount == 1 ? "" : "s") into ")
                            + Text(pullRequest.baseRefName).font(.system(.callout, design: .monospaced))
                            + Text(" from ")
                            + Text(pullRequest.headRefName).font(.system(.callout, design: .monospaced))
                    }
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
                    Spacer()
                    Text("+\(pullRequest.additions)").foregroundStyle(.green).bold()
                    Text("−\(pullRequest.deletions)").foregroundStyle(.red).bold()
                    Link(destination: ref.webURL) { Image(systemName: "safari") }
                        .help("Open on GitHub")
                }
                .font(.callout)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 4)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct StateBadge: View {
    let state: PullRequest.State
    let isDraft: Bool
    let isQueued: Bool

    var body: some View {
        let (title, icon, color): (String, String, Color) = switch (state, isDraft) {
        case (.open, false) where isQueued: ("Queued", "clock", Color(red: 0.75, green: 0.53, blue: 0))
        case (.open, true): ("Draft", "circle.dashed", .gray)
        case (.open, false): ("Open", "arrow.triangle.pull", .green)
        case (.merged, _): ("Merged", "arrow.triangle.merge", .purple)
        case (.closed, _): ("Closed", "xmark.circle", .red)
        }
        Label(title, systemImage: icon)
            .font(.callout.weight(.medium))
            .foregroundStyle(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(color, in: Capsule())
            .accessibilityIdentifier("prDetail.state")
    }
}

struct TabButton: View {
    let title: String
    let count: Int?
    let selected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                HStack(spacing: 6) {
                    Text(title).fontWeight(selected ? .semibold : .regular)
                    if let count {
                        Text("\(count)")
                            .font(.caption.weight(.medium))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 1)
                            .background(.quaternary, in: Capsule())
                    }
                }
                .padding(.horizontal, 8)
                Rectangle()
                    .fill(selected ? Color.orange : .clear)
                    .frame(height: 2)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

/// "Review changes", or "Finish your review (N)" while the viewer's review has pending comments.
struct FinishReviewButton: View {
    let pendingCount: Int
    let action: () -> Void

    var body: some View {
        Group {
            if pendingCount > 0 {
                Button("Finish your review (\(pendingCount))", action: action).buttonStyle(.borderedProminent)
            } else {
                Button("Review changes", action: action).buttonStyle(.bordered)
            }
        }
        .controlSize(.small)
        .accessibilityIdentifier("prDetail.finishReview")
    }
}

struct ViewedProgress: View {
    let viewed: Int
    let total: Int

    var body: some View {
        HStack(spacing: 6) {
            ProgressView(value: Double(viewed), total: Double(max(total, 1)))
                .progressViewStyle(.circular)
                .controlSize(.mini)
            Text("\(viewed) / \(total) viewed")
                .font(.callout.monospacedDigit())
                .foregroundStyle(.secondary)
        }
        .accessibilityIdentifier("prDetail.viewedProgress")
    }
}

struct ErrorBanner: View {
    let message: String
    let dismiss: () -> Void

    var body: some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(.yellow)
            Text(message).lineLimit(2)
            Spacer()
            Button("Dismiss", action: dismiss)
        }
        .font(.callout)
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(.yellow.opacity(0.12))
    }
}

struct FilesChangedView: NSViewControllerRepresentable {
    let controller: FilesChangedViewController

    func makeNSViewController(context: Context) -> FilesChangedViewController { controller }
    func updateNSViewController(_ controller: FilesChangedViewController, context: Context) {}

    /// Takes the proposed size, so SwiftUI does not measure the AppKit subtree when rows change during scroll.
    func sizeThatFits(_ proposal: ProposedViewSize, nsViewController: FilesChangedViewController, context: Context) -> CGSize? {
        proposal.replacingUnspecifiedDimensions(by: CGSize(width: 800, height: 600))
    }
}
