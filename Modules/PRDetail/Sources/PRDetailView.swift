import AppKit
import PRModels
import SwiftUI

public struct PRDetailView: View {
    @Bindable var model: PRDetailModel

    public init(model: PRDetailModel) {
        self.model = model
    }

    public var body: some View {
        VStack(spacing: 0) {
            PRHeaderView(ref: model.ref, pullRequest: model.pullRequest)
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
                if model.tab == .summary {
                    if let pullRequest = model.pullRequest {
                        SummaryView(pullRequest: pullRequest)
                    } else if model.phase == .loaded {
                        ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
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
                    .keyboardShortcut(tab == .summary ? "1" : "2", modifiers: .command)
                    .accessibilityIdentifier("prDetail.tab.\(tab == .summary ? "summary" : "files")")
            }
            Spacer()
            if model.isRefreshing, model.phase == .loaded {
                ProgressView().controlSize(.mini).help("Updating from GitHub")
            }
            if model.tab == .files, model.phase == .loaded {
                ViewedProgress(viewed: model.viewedCount, total: model.fileCount)
                Menu {
                    Button("Collapse All Files") { model.setAllCollapsed(true) }
                        .keyboardShortcut("[", modifiers: [.command, .option])
                    Button("Expand All Files") { model.setAllCollapsed(false) }
                        .keyboardShortcut("]", modifiers: [.command, .option])
                    Divider()
                    Button("Show or Hide File Tree") { model.filesController.toggleFileTree() }
                        .keyboardShortcut("b", modifiers: [.command, .shift])
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
                    StateBadge(state: pullRequest.state, isDraft: pullRequest.isDraft)
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

    var body: some View {
        let (title, icon, color): (String, String, Color) = switch (state, isDraft) {
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
