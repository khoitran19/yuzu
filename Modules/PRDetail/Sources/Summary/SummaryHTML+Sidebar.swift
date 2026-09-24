import Foundation
import PRModels

/// Everything the sidebar shows. The model builds it on the main actor; the HTML builds off it.
nonisolated struct SidebarContent: Sendable, Equatable {
    let checks: [Check]
    let status: MergeStatus?
    let state: PullRequest.State
    let isDraft: Bool
    let method: MergeMethod
    /// The action that runs now; its button shows a spinner, and every button is disabled.
    let running: SidebarAction?
    /// The head of the loaded diff.
    let reviewedHead: String?

    var sidebarState: SidebarState {
        SidebarState(status: status, state: state, isDraft: isDraft, reviewedHead: reviewedHead)
    }
}

nonisolated extension SummaryHTML {
    static let sidebarElementID = "sidebar"

    /// The review card, the merge box with the checks, and the draft link.
    static func sidebar(_ content: SidebarContent) -> String {
        let state = content.sidebarState
        var html = reviewCard(state, content: content)
        if let status = content.status, let box = state.box {
            html += mergeBox(status, box: box, content: content)
        } else if !content.checks.isEmpty {
            html += "<section class=\"box merge-box\">\(checks(content.checks))</section>"
        }
        if state.canConvertToDraft {
            html += "<div class=\"side-footer\">\(button(.convertToDraft, "Convert to draft", style: "btn-link", content: content))</div>"
        }
        return html
    }

    // MARK: Review

    private static func reviewCard(_ state: SidebarState, content: SidebarContent) -> String {
        var html = ""
        switch content.status?.viewerReviewState {
        case .approved: html += "<div class=\"viewer-review success\">\(Octicon.check.svg()) You approved these changes</div>"
        case .changesRequested: html += "<div class=\"viewer-review failure\">\(Octicon.fileDiff.svg()) You requested changes</div>"
        default: break
        }
        if state.canReview {
            html +=
                "<div class=\"btn-row\">"
                + button(.approve, "Approve", icon: .check, style: "btn-primary", content: content)
                + button(.requestChanges, "Request changes", content: content) + "</div>"
        } else if content.status?.viewerDidAuthor == true, content.state == .open {
            html += "<div class=\"muted small\">You opened this pull request, so you cannot review it.</div>"
        }
        guard !html.isEmpty else { return "" }
        return "<section class=\"side-section\"><h3 class=\"side-title\">Review</h3>\(html)</section>"
    }

    // MARK: Merge box

    private static func mergeBox(_ status: MergeStatus, box: MergeBoxState, content: SidebarContent) -> String {
        var parts: [String] = []
        if content.sidebarState.headChanged {
            parts.append(part(
                row(.alert, tone: "pending", title: "New commits were pushed.", detail: "Reload to review them.")
                    + actions(button(.reload, "Reload", style: "btn-block", content: content))
            ))
        }
        let showsRequirements =
            switch box.action {
            case .merged, .closed, .draft, .queued: false
            default: true
            }
        if showsRequirements, let decision = status.reviewDecision { parts.append(part(reviewDecisionRow(decision))) }
        if !content.checks.isEmpty { parts.append(checks(content.checks, expanded: status.state == .open)) }
        if showsRequirements { parts.append(part(mergeabilityRow(status))) }
        parts.append(part(actionRow(status, box: box, content: content)))
        return "<section class=\"box merge-box\">\(parts.joined())</section>"
    }

    private static func reviewDecisionRow(_ decision: PullRequestSummary.ReviewDecision) -> String {
        switch decision {
        case .approved:
            row(.checkCircleFill, tone: "success", title: "Changes approved", detail: "An approving review is on the latest changes.")
        case .changesRequested: row(.xCircleFill, tone: "failure", title: "Changes requested", detail: "A reviewer asked for changes.")
        case .reviewRequired: row(.alert, tone: "pending", title: "Review required", detail: "An approving review is required to merge.")
        }
    }

    private static func mergeabilityRow(_ status: MergeStatus) -> String {
        if status.mergeable == .conflicting || status.mergeStateStatus == .dirty {
            return row(.xCircleFill, tone: "failure", title: "This branch has conflicts that must be resolved", detail: nil)
        }
        if status.mergeStateStatus == .behind {
            return row(
                .alert, tone: "pending", title: "This branch is out-of-date with the base branch", detail: "Update the branch on GitHub.")
        }
        if status.mergeable == .unknown {
            return row(.dotFill, tone: "pending", title: "Checking for the ability to merge automatically…", detail: nil)
        }
        return row(.checkCircleFill, tone: "success", title: "No conflicts with base branch", detail: "Changes can be cleanly merged.")
    }

    private static func actionRow(_ status: MergeStatus, box: MergeBoxState, content: SidebarContent) -> String {
        var html: String
        switch box.action {
        case .merged:
            html = row(.gitMerge, tone: "done", title: "Pull request successfully merged", detail: nil)
        case .closed:
            html = row(.gitPullRequestClosed, tone: "failure", title: "This pull request is closed", detail: nil)
        case let .draft(canMarkReady):
            html = row(
                .gitPullRequestDraft, tone: "muted", title: "This pull request is still a work in progress",
                detail: "Draft pull requests cannot be merged.")
            if canMarkReady { html += actions(button(.markReady, "Ready for review", style: "btn-block", content: content)) }
        case let .queued(canDequeue):
            html = row(.gitMergeQueue, tone: "pending", title: "Queued to merge", detail: queueDetail(status.queueEntry))
            var buttons = canDequeue ? button(.dequeue, "Remove from queue", style: "btn-block", content: content) : ""
            if status.mergeQueueURL != nil { buttons += button(.viewMergeQueue, "View merge queue", style: "btn-link", content: content) }
            html += actions(buttons)
        case let .autoMerge(canDisable):
            let method = status.autoMerge?.method ?? content.method
            let enabledBy = status.autoMerge?.enabledBy.map { " Enabled by \(escape($0))." } ?? ""
            html = row(
                .gitMerge, tone: "success", title: "Auto-merge enabled", detail: nil,
                detailHTML: "Will \(method.verb) when all requirements are met.\(enabledBy)")
            if canDisable { html += actions(button(.disableAutoMerge, "Disable auto-merge", style: "btn-block", content: content)) }
        case .noPermission:
            html = "<div class=\"mb-row muted small\">Only people with write access can merge.</div>"
        case .conflicts:
            html = actions(button(.resolveConflicts, "Resolve conflicts on GitHub", style: "btn-link", content: content))
        case .enqueue:
            html = actions(button(.enqueue, "Merge when ready", icon: .gitMergeQueue, style: "btn-primary btn-block", content: content))
        case .merge:
            html = actions(split(.merge, content.method.buttonTitle, status: status, content: content))
        case .enableAutoMerge:
            html = actions(
                split(.enableAutoMerge, "Enable auto-merge (\(content.method.shortName))", status: status, content: content)
                    + "<div class=\"muted small\">Merges when all requirements are met.</div>")
        case .blocked:
            html = actions(
                "<button type=\"button\" class=\"btn btn-block\" disabled>Merging is blocked</button>"
                    + "<div class=\"muted small\">\(escape(blockedReason(status, checks: content.checks)))</div>")
        }
        if box.canBypass {
            html += actions(button(.bypassMerge, "Bypass rules and merge now", style: "btn-danger btn-block", content: content))
        }
        return html
    }

    private static func queueDetail(_ entry: MergeStatus.QueueEntry?) -> String? {
        guard let entry else { return nil }
        var parts = [entry.totalCount.map { "Position \(entry.position) of \($0)" } ?? "Position \(entry.position)"]
        if let seconds = entry.estimatedSecondsToMerge {
            parts.append(seconds < 60 ? "less than a minute" : "about \((seconds + 59) / 60) min")
        }
        let state =
            switch entry.state {
            case .queued: "Waiting in the queue"
            case .awaitingChecks: "Waiting for checks"
            case .mergeable: "Ready to merge"
            case .unmergeable: "Cannot merge"
            case .locked: "Merging"
            }
        return parts.joined(separator: " · ") + "\n" + state
    }

    private static func blockedReason(_ status: MergeStatus, checks: [Check]) -> String {
        if status.reviewDecision == .changesRequested { return "A reviewer requested changes." }
        if status.reviewDecision == .reviewRequired { return "An approving review is required." }
        if checks.contains(where: { $0.isRequired && ($0.state == .failure || $0.state == .cancelled) }) {
            return "A required check failed."
        }
        if checks.contains(where: { $0.isRequired && $0.state == .pending }) { return "Required checks are still running." }
        if status.mergeStateStatus == .behind { return "The branch must be up to date with the base branch." }
        return "Branch rules block the merge."
    }

    // MARK: Checks

    /// Opens by default while a check fails or runs, unless `expanded` is false.
    static func checks(_ checks: [Check], expanded: Bool = true) -> String {
        guard let summary = SummaryTimeline.checksSummary(checks) else { return "" }
        let (tone, icon): (String, Octicon) =
            switch summary.tone {
            case .success: ("success", .checkCircleFill)
            case .failure: ("failure", .xCircleFill)
            case .pending: ("pending", .dotFill)
            }
        let rows = SummaryTimeline.sortedChecks(checks).map { check in
            let (stateTone, stateIcon): (String, Octicon) =
                switch check.state {
                case .success: ("success", .checkCircleFill)
                case .failure: ("failure", .xCircleFill)
                case .cancelled: ("muted", .stop)
                case .pending: ("pending", .dotFill)
                case .skipped: ("muted", .skipFill)
                case .neutral: ("muted", .squareFill)
                }
            let app =
                check.avatarURL.map { url in
                    "<img class=\"app-avatar\" src=\"\(escape(AvatarScheme.url(for: url)))\" width=\"20\" height=\"20\" loading=\"lazy\" alt=\"\">"
                } ?? ""
            let required = check.isRequired ? #"<span class="label">Required</span>"# : ""
            let details = check.url.map { "<a class=\"details\" href=\"\(escape($0.absoluteString))\">Details</a>" } ?? ""
            let name = escape(SummaryTimeline.displayName(check))
            let description = escape(SummaryTimeline.checkDescription(check))
            return """
                <div class="check-row"><span class="state \(stateTone)">\(stateIcon.svg())</span>\(app)
                <div class="check-text" title="\(name) — \(description)"><strong>\(name)</strong>
                <span class="muted">\(description)</span></div>
                <span class="grow"></span>\(required)\(details)</div>
                """
        }
        let open = expanded && summary.tone != .success ? " open" : ""
        return """
            <details class="checks mb-part"\(open)><summary class="mb-row" title="Show or hide all checks">
            <span class="mb-icon \(tone)">\(icon.svg())</span>
            <div class="mb-text"><div class="mb-title">\(summary.title)</div><div class="muted small">\(escape(summary.subtitle))</div></div>
            \(Octicon.chevronDown.svg(className: "chevron"))
            </summary><div class="check-list">\(rows.joined())</div></details>
            """
    }

    // MARK: Pieces

    private static func row(_ icon: Octicon, tone: String, title: String, detail: String?, detailHTML: String? = nil) -> String {
        let detail = detailHTML ?? detail.map { escape($0).replacingOccurrences(of: "\n", with: "<br>") }
        return """
            <div class="mb-row"><span class="mb-icon \(tone)">\(icon.svg())</span>
            <div class="mb-text"><div class="mb-title">\(escape(title))</div>\(detail.map { "<div class=\"muted small\">\($0)</div>" } ?? "")</div></div>
            """
    }

    private static func part(_ html: String) -> String {
        "<div class=\"mb-part\">\(html)</div>"
    }

    private static func actions(_ html: String) -> String {
        "<div class=\"mb-actions\">\(html)</div>"
    }

    private static func button(
        _ action: SidebarAction, _ title: String, icon: Octicon? = nil, style: String = "", content: SidebarContent
    ) -> String {
        let label = content.running == action
            ? "<span class=\"spinner\"></span>\(escape(action.progressTitle))"
            : (icon?.svg() ?? "") + escape(title)
        let tooltip = action.shortcut.map { "\(title) (\($0.symbols))" } ?? title
        let disabled = content.running == nil && content.sidebarState.actions.contains(action) ? "" : " disabled"
        return "<button type=\"button\" class=\"btn \(style)\" data-action=\"\(action.rawValue)\" "
            + "title=\"\(escape(tooltip))\"\(disabled)>\(label)</button>"
    }

    /// The main button runs `action` with the selected method; the caret opens the native method menu.
    private static func split(_ action: SidebarAction, _ title: String, status: MergeStatus, content: SidebarContent) -> String {
        let main = button(action, title, style: "btn-primary split-main", content: content)
        guard status.allowedMethods.count > 1 else { return "<div class=\"split\">\(main)</div>" }
        let disabled = content.running == nil && content.sidebarState.actions.contains(.chooseMethod) ? "" : " disabled"
        return "<div class=\"split\">\(main)<button type=\"button\" class=\"btn btn-primary split-caret\" data-action=\"chooseMethod\" "
            + "title=\"Choose the merge method\" aria-label=\"Choose the merge method\"\(disabled)>\(Octicon.chevronDown.svg())</button></div>"
    }
}
