import AppKit
import AppShortcuts
import PRDetail
import PRModels
import SwiftUI

extension View {
    /// Shows the open pull request panel over the trailing edge. A click outside the panel closes it.
    public func pullRequestListPanel(_ model: PRListModel, open: @escaping (PRRef) -> Void) -> some View {
        overlay(alignment: .trailing) {
            ZStack(alignment: .trailing) {
                if model.panel.isOpen {
                    Color.clear
                        .contentShape(Rectangle())
                        .onTapGesture { model.close() }
                    PRListPanel(model: model, open: open)
                        .transition(.move(edge: .trailing))
                }
            }
            .animation(.snappy(duration: 0.2), value: model.panel.isOpen)
        }
    }
}

struct PRListPanel: View {
    @Bindable var model: PRListModel
    let open: (PRRef) -> Void
    @FocusState private var focused: Bool

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            content.frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(width: 480)
        .frame(maxHeight: .infinity, alignment: .top)
        .background(Color(nsColor: .windowBackgroundColor))
        .overlay(alignment: .leading) { Rectangle().fill(.separator).frame(width: 1) }
        .compositingGroup()
        .shadow(color: .black.opacity(0.2), radius: 14, x: -3)
        .focusable()
        .focusEffectDisabled()
        .focused($focused)
        .onKeyPress(Shortcut.panelPrevious.keyEquivalent) {
            model.moveSelection(by: -1)
            return .handled
        }
        .onKeyPress(Shortcut.panelNext.keyEquivalent) {
            model.moveSelection(by: 1)
            return .handled
        }
        .onKeyPress(Shortcut.panelOpen.keyEquivalent) {
            if let selection = model.selection { activate(selection) }
            return .handled
        }
        .onKeyPress(Shortcut.panelClose.keyEquivalent) {
            model.close()
            return .handled
        }
        .onChange(of: model.focusRequests, initial: true) { focused = true }
        .accessibilityIdentifier("prList.panel")
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(nsImage: Octicon.repo.image).foregroundStyle(.secondary)
                Text(model.repo?.displayName ?? "")
                    .font(.headline)
                    .lineLimit(1)
                    .truncationMode(.middle)
                Spacer()
                if model.content(model.tab).isLoading, model.content(model.tab).list != nil {
                    ProgressView().controlSize(.small).help("Updating from GitHub")
                }
                Button(action: model.close) { Image(systemName: "xmark") }
                    .buttonStyle(.borderless)
                    .help("Close (\(Shortcut.panelClose.symbols))")
            }
            Picker("Pull requests", selection: $model.tab) {
                Text(title(.mine)).tag(PullRequestListScope.mine)
                Text(title(.others)).tag(PullRequestListScope.others)
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .accessibilityIdentifier("prList.tab")
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }

    @ViewBuilder private var content: some View {
        let content = model.content(model.tab)
        if let list = content.list {
            if list.pullRequests.isEmpty {
                PanelMessage(icon: Image(nsImage: Octicon.gitPullRequest.image), title: "No open pull requests")
            } else {
                rows(list.pullRequests)
            }
        } else if let error = content.error {
            PanelMessage(icon: Image(systemName: "exclamationmark.triangle"), title: "Could not load pull requests", detail: error) {
                Button("Retry", action: model.refresh)
            }
        } else {
            ProgressView()
        }
    }

    private func rows(_ pullRequests: [PullRequestSummary]) -> some View {
        let selection = model.selection
        return ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(pullRequests) { pullRequest in
                        PRListRow(
                            pullRequest: pullRequest,
                            showsAuthor: model.tab == .others,
                            isCurrent: pullRequest.ref == model.current,
                            isSelected: pullRequest.ref == selection
                        ) { activate(pullRequest.ref) }
                        .id(pullRequest.ref)
                        Divider()
                    }
                }
            }
            .task(id: selection) {
                if let selection { proxy.scrollTo(selection, anchor: .center) }
            }
        }
    }

    private func title(_ scope: PullRequestListScope) -> String {
        let name = scope == .mine ? "Mine" : "Others"
        guard let count = model.content(scope).list?.totalCount else { return name }
        return "\(name) (\(count))"
    }

    private func activate(_ ref: PRRef) {
        model.close()
        if ref != model.current { open(ref) }
    }
}

private struct PanelMessage<Actions: View>: View {
    let icon: Image
    let title: String
    var detail: String?
    @ViewBuilder var actions: Actions

    var body: some View {
        VStack(spacing: 8) {
            icon.resizable().scaledToFit().frame(width: 28, height: 28).foregroundStyle(.secondary)
            Text(title).font(.headline)
            if let detail {
                Text(detail).font(.callout).foregroundStyle(.secondary).multilineTextAlignment(.center)
            }
            actions.padding(.top, 4)
        }
        .padding(24)
    }
}

extension PanelMessage where Actions == EmptyView {
    init(icon: Image, title: String) {
        self.init(icon: icon, title: title, detail: nil) { EmptyView() }
    }
}
