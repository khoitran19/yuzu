import Foundation
import PRModels

/// Builds the Summary page: the description, the comment and review timeline, and the Checks box, styled like GitHub.
nonisolated enum SummaryHTML {
    static let conversationElementID = "conversation"

    static func document(pullRequest: PullRequest, conversation: String, now: Date) -> String {
        let body = pullRequest.bodyHTML.isEmpty ? "<p class=\"empty\">No description provided.</p>" : pullRequest.bodyHTML
        let author = pullRequest.author
        return """
        <!doctype html>
        <html><head><meta charset="utf-8"><style>\(SummaryStyle.css)</style></head>
        <body><main class="discussion">
        <div class="tl-comment">
        \(avatar(author, size: 40, className: "tl-avatar"))
        <div class="box arrow">
        <div class="box-header">\(authorLink(author?.login))
        <span class="muted">commented \(time(pullRequest.createdAt, now: now, url: nil))</span></div>
        <div class="markdown-body">\(body)</div>
        </div></div>
        <div id="\(conversationElementID)">\(conversation)</div>
        </main></body></html>
        """
    }

    /// `nil` shows a loading row; the fragment replaces it in place when the conversation arrives.
    static func conversation(_ conversation: Conversation?, threads: [ReviewThread], pullRequestAuthor: String?, now: Date) -> String {
        guard let conversation else { return "<div class=\"loading muted\">Loading conversation…</div>" }
        var html = ""
        for entry in SummaryTimeline.entries(conversation, threads: threads) {
            switch entry {
            case let .comment(comment): html += self.comment(comment, pullRequestAuthor: pullRequestAuthor, now: now)
            case let .review(review, threads): html += self.review(review, threads: threads, pullRequestAuthor: pullRequestAuthor, now: now)
            }
        }
        html += "<div class=\"tl-end\"></div>"
        html += checks(conversation.checks)
        return html
    }

    // MARK: Timeline

    private static func comment(_ comment: IssueComment, pullRequestAuthor: String?, now: Date) -> String {
        let header = """
        \(authorLink(comment.author?.actor.login))\(botLabel(comment.author))
        <span class="muted">commented \(time(comment.createdAt, now: now, url: comment.url))</span>
        <span class="grow"></span>\(labels(comment.author, pullRequestAuthor: pullRequestAuthor))
        """
        if let reason = comment.minimizedReason {
            let text = reason == "hidden" ? "This comment has been minimized." : "This comment was marked as \(escape(reason.lowercased()))."
            return """
            <div class="tl-comment">\(avatar(comment.author?.actor, size: 40, className: "tl-avatar"))
            <details class="box arrow minimized"><summary class="box-header"><span class="muted">\(text)</span>
            <span class="grow"></span><span class="link show">Show comment</span><span class="link hide">Hide comment</span></summary>
            <div class="box-header sub">\(header)</div><div class="markdown-body">\(comment.bodyHTML)</div></details></div>
            """
        }
        return """
        <div class="tl-comment">\(avatar(comment.author?.actor, size: 40, className: "tl-avatar"))
        <div class="box arrow"><div class="box-header">\(header)</div>
        <div class="markdown-body">\(comment.bodyHTML)</div></div></div>
        """
    }

    private static func review(
        _ review: Review, threads: [SummaryTimeline.InlineThread], pullRequestAuthor: String?, now: Date
    ) -> String {
        let (tone, icon, action): (String, Octicon, String) = switch review.state {
        case .approved: ("approved", .check, "approved these changes")
        case .changesRequested: ("changes", .fileDiff, "requested changes")
        case .commented, .pending: ("", .eye, "reviewed")
        case .dismissed: ("", .eye, "reviewed")
        }
        let dismissed = review.state == .dismissed ? #" <span class="label">Dismissed</span>"# : ""
        var html = """
        <div class="tl-event"><span class="tl-badge \(tone)">\(icon.svg())</span><div class="tl-event-body">
        <div class="tl-event-line">\(avatar(review.author?.actor, size: 20, className: "inline"))
        \(authorLink(review.author?.actor.login))\(botLabel(review.author))
        <span class="muted">\(action) \(time(review.createdAt, now: now, url: review.url))</span>\(dismissed)</div>
        """
        if !review.bodyHTML.isEmpty {
            html += """
            <div class="box nested"><div class="box-header">\(avatar(review.author?.actor, size: 20, className: "inline"))
            \(authorLink(review.author?.actor.login))\(botLabel(review.author)) <span class="muted">left a comment</span>
            <span class="grow"></span>\(labels(review.author, pullRequestAuthor: pullRequestAuthor))</div>
            <div class="markdown-body">\(review.bodyHTML)</div></div>
            """
        }
        for thread in threads { html += self.thread(thread, pullRequestAuthor: pullRequestAuthor, now: now) }
        return html + "</div></div>"
    }

    private static func thread(_ thread: SummaryTimeline.InlineThread, pullRequestAuthor: String?, now: Date) -> String {
        let open = thread.isResolved || thread.isOutdated ? "" : " open"
        let outdated = thread.isOutdated ? #"<span class="label attention">Outdated</span>"# : ""
        let resolved = thread.isResolved ? #"<span class="muted resolved">"# + Octicon.check.svg() + " Resolved</span>" : ""
        var html = """
        <details class="box nested thread"\(open)><summary class="thread-header">\
        \(Octicon.chevronDown.svg(className: "chevron"))<span class="path">\(escape(thread.root.path))</span>\
        \(outdated)<span class="grow"></span>\(resolved)</summary>\(hunk(thread.root.diffHunk))<div class="thread-comments">
        """
        for comment in [thread.root] + thread.replies {
            html += """
            <div class="thread-comment">\(avatar(comment.author?.actor, size: 24, className: "inline"))<div class="tc-main">
            <div class="tc-header">\(authorLink(comment.author?.actor.login))\(botLabel(comment.author))
            <span class="muted">\(time(comment.createdAt, now: now, url: nil))</span>
            <span class="grow"></span>\(labels(comment.author, pullRequestAuthor: pullRequestAuthor))</div>
            <div class="markdown-body">\(comment.bodyHTML)</div></div></div>
            """
        }
        return html + "</div></details>"
    }

    /// The last four lines of the hunk, which end at the commented line, as GitHub shows them.
    static func hunk(_ diffHunk: String) -> String {
        var lines = diffHunk.split(separator: "\n", omittingEmptySubsequences: false)
        guard let header = lines.first, header.hasPrefix("@@") else { return "" }
        lines.removeFirst()
        let numbers = header.split(separator: " ").dropFirst().prefix(2).map { part in
            Int(part.dropFirst().split(separator: ",").first ?? "") ?? 0
        }
        var old = numbers.first ?? 0
        var new = numbers.dropFirst().first ?? 0
        var rows: [(kind: String, old: Int?, new: Int?, text: Substring)] = []
        for line in lines {
            switch line.first {
            case "+": rows.append(("add", nil, new, line)); new += 1
            case "-": rows.append(("del", old, nil, line)); old += 1
            case "\\": continue
            default: rows.append(("ctx", old, new, line)); old += 1; new += 1
            }
        }
        guard !rows.isEmpty else { return "" }
        let cells = rows.suffix(4).map { row in
            let marker = row.text.first.map(String.init) ?? " "
            let code = escape(String(row.text.dropFirst()))
            return "<tr class=\"\(row.kind)\"><td class=\"num\">\(row.old.map(String.init) ?? "")</td>"
                + "<td class=\"num\">\(row.new.map(String.init) ?? "")</td>"
                + "<td class=\"code\"><span class=\"marker\">\(escape(marker))</span>\(code)</td></tr>"
        }
        return "<table class=\"hunk\">\(cells.joined())</table>"
    }

    // MARK: Checks

    private static func checks(_ checks: [Check]) -> String {
        guard let summary = SummaryTimeline.checksSummary(checks) else { return "" }
        let (tone, icon): (String, Octicon) = switch summary.tone {
        case .success: ("success", .check)
        case .failure: ("failure", .x)
        case .pending: ("pending", .dotFill)
        }
        let rows = SummaryTimeline.sortedChecks(checks).map { check in
            let (stateTone, stateIcon): (String, Octicon) = switch check.state {
            case .success: ("success", .checkCircleFill)
            case .failure: ("failure", .xCircleFill)
            case .cancelled: ("muted", .stop)
            case .pending: ("pending", .dotFill)
            case .skipped: ("muted", .skipFill)
            case .neutral: ("muted", .squareFill)
            }
            let app = check.avatarURL.map { url in
                "<img class=\"app-avatar\" src=\"\(escape(AvatarScheme.url(for: url)))\" width=\"20\" height=\"20\" loading=\"lazy\" alt=\"\">"
            } ?? ""
            let required = check.isRequired ? #"<span class="label">Required</span>"# : ""
            let details = check.url.map { "<a class=\"details\" href=\"\(escape($0.absoluteString))\">Details</a>" } ?? ""
            return """
            <div class="check-row"><span class="state \(stateTone)">\(stateIcon.svg())</span>\(app)
            <div class="check-text"><strong>\(escape(SummaryTimeline.displayName(check)))</strong>
            <span class="muted">\(escape(SummaryTimeline.checkDescription(check)))</span></div>
            <span class="grow"></span>\(required)\(details)</div>
            """
        }
        let open = summary.tone == .success ? "" : " open"
        return """
        <section class="merge-box">
        <details class="box checks"\(open)><summary class="checks-header">
        <span class="status-circle \(tone)">\(icon.svg(size: 16))</span>
        <div><div class="checks-title">\(summary.title)</div><div class="muted">\(escape(summary.subtitle))</div></div>
        <span class="grow"></span><span class="link show">Show all checks</span><span class="link hide">Hide all checks</span>
        </summary><div class="check-list">\(rows.joined())</div></details></section>
        """
    }

    // MARK: Pieces

    private static func avatar(_ actor: Actor?, size: Int, className: String) -> String {
        let login = actor?.login ?? "ghost"
        guard let url = actor?.avatarURL else {
            let initial = escape(login.first.map { String($0).uppercased() } ?? "?")
            return "<span class=\"avatar placeholder \(className)\" style=\"width:\(size)px;height:\(size)px;font-size:\(size / 2)px\">\(initial)</span>"
        }
        return "<img class=\"avatar \(className)\" src=\"\(escape(AvatarScheme.url(for: url)))\" width=\"\(size)\" height=\"\(size)\" "
            + "loading=\"lazy\" decoding=\"async\" alt=\"@\(escape(login))\" onerror=\"this.removeAttribute('src')\">"
    }

    private static func authorLink(_ login: String?) -> String {
        let login = login ?? "ghost"
        return "<a class=\"author\" href=\"https://github.com/\(escape(login))\">\(escape(login))</a>"
    }

    private static func botLabel(_ author: Author?) -> String {
        author?.isBot == true ? " <span class=\"label bot\">bot</span>" : ""
    }

    private static func labels(_ author: Author?, pullRequestAuthor: String?) -> String {
        guard let author else { return "" }
        var labels: [String] = []
        if author.actor.login == pullRequestAuthor { labels.append("Author") }
        switch author.association {
        case "OWNER": labels.append("Owner")
        case "MEMBER": labels.append("Member")
        case "COLLABORATOR": labels.append("Collaborator")
        case "CONTRIBUTOR": labels.append("Contributor")
        case "FIRST_TIME_CONTRIBUTOR", "FIRST_TIMER": labels.append("First-time contributor")
        default: break
        }
        return labels.map { "<span class=\"label\">\($0)</span>" }.joined()
    }

    private static func time(_ date: Date, now: Date, url: URL?) -> String {
        let title = escape(date.formatted(date: .abbreviated, time: .shortened))
        let text = relative(date, now: now)
        guard let url else { return "<span title=\"\(title)\">\(text)</span>" }
        return "<a class=\"muted\" href=\"\(escape(url.absoluteString))\" title=\"\(title)\">\(text)</a>"
    }

    /// GitHub wording: "3 hours ago", "yesterday", then "on Sep 12" after 30 days.
    static func relative(_ date: Date, now: Date) -> String {
        let seconds = Int(now.timeIntervalSince(date))
        func plural(_ count: Int, _ unit: String) -> String { "\(count) \(unit)\(count == 1 ? "" : "s") ago" }
        switch seconds {
        case ..<60: return "now"
        case ..<3_600: return plural(seconds / 60, "minute")
        case ..<86_400: return plural(seconds / 3_600, "hour")
        case ..<172_800: return "yesterday"
        case ..<2_592_000: return plural(seconds / 86_400, "day")
        default:
            let calendar = Calendar.current
            let sameYear = calendar.component(.year, from: date) == calendar.component(.year, from: now)
            let format = sameYear ? Date.FormatStyle().month(.abbreviated).day() : Date.FormatStyle().month(.abbreviated).day().year()
            return "on \(date.formatted(format))"
        }
    }

    static func escape(_ text: String) -> String {
        var result = ""
        result.reserveCapacity(text.utf8.count)
        for character in text {
            switch character {
            case "&": result += "&amp;"
            case "<": result += "&lt;"
            case ">": result += "&gt;"
            case "\"": result += "&quot;"
            default: result.append(character)
            }
        }
        return result
    }
}
