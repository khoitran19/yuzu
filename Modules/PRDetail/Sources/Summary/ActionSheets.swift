import AppShortcuts
import GitHubKit
import PRModels
import SwiftUI

/// A Markdown comment for Approve (optional) or Request changes (required).
struct ReviewSheet: View {
    let event: PullRequestAction.ReviewEvent
    let submit: (String) -> Void
    let cancel: () -> Void
    @State private var text = ""
    @FocusState private var editorFocused: Bool

    private var isApprove: Bool { event == .approve }
    private var canSubmit: Bool { isApprove || !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(isApprove ? "Approve" : "Request Changes").font(.headline)
            CommentEditor(
                text: $text,
                placeholder: isApprove
                    ? "Leave a comment (optional). Markdown is supported." : "Describe the changes you want. Markdown is supported."
            )
            .focused($editorFocused)
            .accessibilityIdentifier("reviewSheet.editor")
            HStack {
                Spacer()
                Button("Cancel", action: cancel)
                    .keyboardShortcut(Shortcut.cancelSheet.keyboardShortcut)
                Button(isApprove ? "Approve" : "Request Changes") { submit(text) }
                    .keyboardShortcut(Shortcut.submitSheet.keyboardShortcut)
                    .buttonStyle(.borderedProminent)
                    .tint(isApprove ? .green : nil)
                    .disabled(!canSubmit)
                    .help("\(isApprove ? "Approve" : "Request changes") (\(Shortcut.submitSheet.symbols))")
                    .accessibilityIdentifier("reviewSheet.submit")
            }
        }
        .padding(20)
        .frame(width: 520)
        .onAppear { editorFocused = true }
        .accessibilityIdentifier("reviewSheet")
    }
}

/// Comment, Approve, or Request changes. The viewer's pending comments go with the review.
struct FinishReviewSheet: View {
    let pendingCount: Int
    /// False for the author: GitHub lets the author only comment.
    let canApprove: Bool
    let canSubmit: (PullRequestAction.ReviewEvent, String) -> Bool
    let submit: (PullRequestAction.ReviewEvent, String) -> Void
    /// `nil` when there is no pending review.
    let discard: (() -> Void)?
    let cancel: () -> Void
    @State private var event: PullRequestAction.ReviewEvent = .comment
    @State private var text = ""
    @State private var confirmDiscard = false
    @FocusState private var editorFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Text("Finish your review").font(.headline)
                Spacer()
                if pendingCount > 0 {
                    Text("\(pendingCount) pending comment\(pendingCount == 1 ? "" : "s")").foregroundStyle(.secondary)
                }
            }
            CommentEditor(text: $text, placeholder: "Leave a comment. Markdown is supported.")
                .focused($editorFocused)
                .accessibilityIdentifier("finishReview.editor")
            Picker("Review", selection: $event) {
                Text("Comment").tag(PullRequestAction.ReviewEvent.comment)
                Text("Approve").tag(PullRequestAction.ReviewEvent.approve).disabled(!canApprove)
                Text("Request changes").tag(PullRequestAction.ReviewEvent.requestChanges).disabled(!canApprove)
            }
            .pickerStyle(.radioGroup)
            .labelsHidden()
            HStack {
                if discard != nil {
                    Button("Discard review", role: .destructive) { confirmDiscard = true }
                }
                Spacer()
                Button("Cancel", action: cancel)
                    .keyboardShortcut(Shortcut.cancelSheet.keyboardShortcut)
                Button("Submit review") { submit(event, text) }
                    .keyboardShortcut(Shortcut.submitSheet.keyboardShortcut)
                    .buttonStyle(.borderedProminent)
                    .disabled(!canSubmit(event, text))
                    .help("Submit review (\(Shortcut.submitSheet.symbols))")
                    .accessibilityIdentifier("finishReview.submit")
            }
        }
        .padding(20)
        .frame(width: 520)
        .onAppear { editorFocused = true }
        .confirmationDialog("Discard your pending review?", isPresented: $confirmDiscard) {
            Button("Discard", role: .destructive) { discard?() }
        } message: {
            Text("GitHub deletes its \(pendingCount) pending comment\(pendingCount == 1 ? "" : "s").")
        }
        .accessibilityIdentifier("finishReview")
    }
}

/// Confirms a merge, which GitHub cannot undo. Empty fields let GitHub use the repository default.
struct MergeSheet: View {
    let pullRequest: PullRequest
    let methods: [MergeMethod]
    let bypass: Bool
    let confirm: (MergeMethod, String?, String?) -> Void
    let cancel: () -> Void
    @State private var method: MergeMethod
    @State private var headline: String
    @State private var message = ""
    @FocusState private var headlineFocused: Bool

    init(
        pullRequest: PullRequest, methods: [MergeMethod], method: MergeMethod, bypass: Bool,
        confirm: @escaping (MergeMethod, String?, String?) -> Void, cancel: @escaping () -> Void
    ) {
        self.pullRequest = pullRequest
        self.methods = methods
        self.bypass = bypass
        self.confirm = confirm
        self.cancel = cancel
        _method = State(initialValue: method)
        _headline = State(initialValue: Self.defaultHeadline(method, pullRequest: pullRequest))
    }

    static func defaultHeadline(_ method: MergeMethod, pullRequest: PullRequest) -> String {
        switch method {
        case .squash: "\(pullRequest.title) (#\(pullRequest.ref.number))"
        case .merge: "Merge pull request #\(pullRequest.ref.number) from \(pullRequest.headRefName)"
        case .rebase: ""
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(bypass ? "Bypass Rules and Merge" : "Merge Pull Request").font(.headline)
            if bypass {
                Label(
                    "This merges now and bypasses the branch rules of \(pullRequest.baseRefName).",
                    systemImage: "exclamationmark.triangle.fill"
                )
                .foregroundStyle(.red)
                .font(.callout)
            }
            if methods.count > 1 {
                Picker("Method", selection: $method) {
                    ForEach(methods, id: \.self) { Text($0.buttonTitle).tag($0) }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .accessibilityIdentifier("mergeSheet.method")
            } else {
                Text(method.buttonTitle).font(.callout.weight(.medium))
            }
            if method == .rebase {
                Text("The commits from this branch are rebased and added to \(pullRequest.baseRefName). GitHub keeps their messages.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            } else {
                TextField("Commit message", text: $headline)
                    .textFieldStyle(.roundedBorder)
                    .focused($headlineFocused)
                    .accessibilityIdentifier("mergeSheet.headline")
                CommentEditor(text: $message, placeholder: "Extended description (optional). Leave it empty to use the repository default.")
                    .accessibilityIdentifier("mergeSheet.body")
            }
            HStack {
                Spacer()
                Button("Cancel", action: cancel)
                    .keyboardShortcut(Shortcut.cancelSheet.keyboardShortcut)
                Button(confirmTitle) {
                    let rebase = method == .rebase
                    confirm(method, rebase || headline.isEmpty ? nil : headline, rebase || message.isEmpty ? nil : message)
                }
                .keyboardShortcut(Shortcut.submitSheet.keyboardShortcut)
                .buttonStyle(.borderedProminent)
                .tint(bypass ? .red : .green)
                .help("\(confirmTitle) (\(Shortcut.submitSheet.symbols))")
                .accessibilityIdentifier("mergeSheet.confirm")
            }
        }
        .padding(20)
        .frame(width: 520)
        .onAppear { headlineFocused = true }
        .onChange(of: method) { old, new in
            if headline == Self.defaultHeadline(old, pullRequest: pullRequest) {
                headline = Self.defaultHeadline(new, pullRequest: pullRequest)
            }
        }
        .accessibilityIdentifier("mergeSheet")
    }

    private var confirmTitle: String {
        if bypass { return "Bypass Rules and Merge" }
        return switch method {
        case .merge: "Confirm Merge"
        case .squash: "Confirm Squash and Merge"
        case .rebase: "Confirm Rebase and Merge"
        }
    }
}

private struct CommentEditor: View {
    @Binding var text: String
    let placeholder: String

    var body: some View {
        TextEditor(text: $text)
            .font(.body)
            .scrollContentBackground(.hidden)
            .padding(6)
            .frame(minHeight: 120, maxHeight: 240)
            .background(Color(nsColor: .textBackgroundColor), in: RoundedRectangle(cornerRadius: 6))
            .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color(nsColor: .separatorColor)))
            .overlay(alignment: .topLeading) {
                if text.isEmpty {
                    Text(placeholder)
                        .foregroundStyle(.tertiary)
                        .padding(.horizontal, 11)
                        .padding(.vertical, 6)
                        .allowsHitTesting(false)
                }
            }
    }
}
