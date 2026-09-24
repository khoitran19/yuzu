import Foundation
import PRModels

/// Builds large, deterministic pull requests for performance and UI tests.
public enum SyntheticPullRequest {
    public static func ref(fileCount: Int, changedLines: Int, seed: UInt64) -> PRRef {
        PRRef(owner: "prviewer-fixtures", repo: "synthetic-\(fileCount)-\(changedLines)", number: Int(clamping: max(seed, 1)))
    }

    /// `changedLines` is the exact sum of additions and deletions over all files.
    public static func make(fileCount: Int, changedLines: Int, seed: UInt64) -> Fixture {
        precondition(fileCount >= 10, "A synthetic pull request needs at least 10 files.")
        precondition(changedLines >= fileCount * 4, "A synthetic pull request needs at least 4 changed lines per file.")
        var rng = SeededGenerator(seed: seed)
        let baseOid = rng.hex(length: 40)
        let headOid = rng.hex(length: 40)
        var paths = PathFactory()
        var plans = makePlans(fileCount: fileCount, changedLines: changedLines, paths: &paths, rng: &rng)

        var files: [ChangedFile] = []
        var hunks: [String: [PatchWriter.Hunk]] = [:]
        var contents: [FixtureContent] = []
        var shortfall = 0
        for index in plans.indices {
            switch (plans[index].kind, plans[index].status) {
            case (.fill, _):
                plans[index].budget = changedLines - files.reduce(0) { $0 + $1.additions + $1.deletions }
            case (.text, .renamed):
                let capped = min(plans[index].budget, 12)
                shortfall += plans[index].budget - capped
                plans[index].budget = capped
            case (.text, _):
                plans[index].budget += shortfall
                shortfall = 0
            default:
                break
            }
            let plan = plans[index]
            let texts = makeTexts(plan, rng: &rng)
            let result = PatchWriter.make(old: texts.base, new: texts.head)
            if plan.kind == .text || plan.kind == .large {
                shortfall += plan.budget - result.additions - result.deletions
            }
            let hasPatch = plan.kind != .binary && plan.kind != .large && !result.patch.isEmpty
            files.append(ChangedFile(
                path: plan.path, previousPath: plan.previousPath, status: plan.status,
                additions: result.additions, deletions: result.deletions,
                patch: hasPatch ? result.patch : nil,
                viewedState: viewedState(for: plan.status, rng: &rng)
            ))
            if hasPatch { hunks[plan.path] = result.hunks }
            if let base = texts.base { contents.append(FixtureContent(oid: baseOid, path: plan.previousPath ?? plan.path, text: base)) }
            if let head = texts.head { contents.append(FixtureContent(oid: headOid, path: plan.path, text: head)) }
        }
        files.sort { $0.path < $1.path }

        let createdAt = Date(timeIntervalSince1970: 1_788_000_000 + Double(rng.int(0...86_400)))
        let threads = makeThreads(files: files, hunks: hunks, fileCount: fileCount, createdAt: createdAt, rng: &rng)
        let additions = files.reduce(0) { $0 + $1.additions }
        let deletions = files.reduce(0) { $0 + $1.deletions }
        let pullRequest = PullRequest(
            nodeID: "PR_synthetic_\(fileCount)_\(changedLines)_\(seed)",
            ref: ref(fileCount: fileCount, changedLines: changedLines, seed: seed),
            title: "Synthetic: \(fileCount) files, \(changedLines) changed lines (seed \(seed))",
            state: .open, isDraft: false,
            author: Actor(login: rng.pick(authors), avatarURL: nil),
            bodyHTML: """
            <p>Synthetic pull request for performance tests. \(Words.emoji.joined())</p>
            <ul><li>\(fileCount) files</li><li>\(additions) additions and \(deletions) deletions</li>\
            <li>\(threads.count) review threads</li></ul>
            <p>\(SyntheticText.paragraph(rng: &rng))</p>
            """,
            baseRefName: "main", headRefName: "synthetic/seed-\(seed)",
            baseOid: baseOid, headOid: headOid,
            additions: additions, deletions: deletions, changedFiles: files.count,
            commitCount: rng.int(3...40), createdAt: createdAt
        )
        let conversation = makeConversation(files: files, threads: threads, createdAt: createdAt, seed: seed)
        return Fixture(
            snapshot: PullRequestSnapshot(pullRequest: pullRequest, files: files, threads: threads, conversation: conversation),
            contents: contents
        )
    }

    // MARK: Plans

    private struct FilePlan {
        enum Kind: Equatable { case text, binary, large, pureRename, fill }
        enum NewlineMode { case both, missingInBase, missingInHead, missingInBoth }

        let kind: Kind
        let status: ChangedFile.Status
        let path: String
        let previousPath: String?
        let style: TextStyle
        var budget: Int
        let newline: NewlineMode
    }

    private static func makePlans(
        fileCount: Int, changedLines: Int, paths: inout PathFactory, rng: inout SeededGenerator
    ) -> [FilePlan] {
        let binaryCount = max(2, fileCount / 60)
        let largeCount = max(1, fileCount / 100)
        let renameCount = max(1, fileCount / 100)
        var kinds: [FilePlan.Kind] = Array(repeating: .binary, count: binaryCount)
            + Array(repeating: .large, count: largeCount)
            + Array(repeating: .pureRename, count: renameCount)
        kinds += Array(repeating: .text, count: fileCount - kinds.count - 1)
        kinds.shuffle(using: &rng)
        kinds.append(.fill)

        let weights = kinds.map { kind -> Double in
            switch kind {
            case .text: 1 + pow(Double.random(in: 0..<1, using: &rng), 3) * 12
            case .large: 30
            case .binary, .pureRename, .fill: 0
            }
        }
        let planned = Double(changedLines) * 0.98
        let weightSum = weights.reduce(0, +)

        var largeIndex = 0
        return zip(kinds, weights).map { kind, weight in
            let budget = max(1, Int(planned * weight / weightSum))
            switch kind {
            case .binary:
                return FilePlan(
                    kind: kind, status: rng.chance(0.5) ? .added : .modified, path: paths.binary(rng: &rng),
                    previousPath: nil, style: TextStyle(language: .json, flavor: .source, indent: ""),
                    budget: 0, newline: .both
                )
            case .large:
                defer { largeIndex += 1 }
                let (path, style) = paths.large(largeIndex)
                return FilePlan(kind: kind, status: .modified, path: path, previousPath: nil, style: style, budget: budget, newline: .both)
            case .pureRename:
                let (path, style) = paths.text(rng: &rng)
                return FilePlan(
                    kind: kind, status: .renamed, path: path, previousPath: paths.renamedFrom(path, rng: &rng),
                    style: style, budget: 0, newline: .both
                )
            case .fill:
                let style = TextStyle(language: .typescript, flavor: .source, indent: "  ")
                return FilePlan(
                    kind: kind, status: .added, path: paths.unique("apps/platform/gateway/src/generated/routeTree.gen.ts"),
                    previousPath: nil, style: style, budget: 0, newline: .both
                )
            case .text:
                let (path, style) = paths.text(rng: &rng)
                let roll = Double.random(in: 0..<1, using: &rng)
                let status: ChangedFile.Status = roll < 0.62 ? .modified : roll < 0.82 ? .added : roll < 0.91 ? .removed : .renamed
                let newline: FilePlan.NewlineMode = !rng.chance(0.06) ? .both
                    : rng.pick([.missingInBase, .missingInHead, .missingInBoth])
                return FilePlan(
                    kind: kind, status: status, path: path,
                    previousPath: status == .renamed ? paths.renamedFrom(path, rng: &rng) : nil,
                    style: style, budget: budget, newline: newline
                )
            }
        }
    }

    // MARK: Contents

    private static func makeTexts(_ plan: FilePlan, rng: inout SeededGenerator) -> (base: String?, head: String?) {
        switch plan.kind {
        case .binary:
            return (nil, nil)
        case .pureRename:
            let text = join(SyntheticText.document(plan.style, count: rng.int(20...120), rng: &rng), newline: true)
            return (text, text)
        case .fill:
            return (nil, join(SyntheticText.document(plan.style, count: plan.budget, rng: &rng), newline: true))
        case .text, .large:
            let baseNewline = plan.newline == .both || plan.newline == .missingInHead
            let headNewline = plan.newline == .both || plan.newline == .missingInBase
            switch plan.status {
            case .added:
                return (nil, join(SyntheticText.document(plan.style, count: plan.budget, rng: &rng), newline: headNewline))
            case .removed:
                return (join(SyntheticText.document(plan.style, count: plan.budget, rng: &rng), newline: baseNewline), nil)
            default:
                let (base, head) = edit(plan, rng: &rng)
                return (join(base, newline: baseNewline), join(head, newline: headNewline))
            }
        }
    }

    /// Splits the budget into change regions separated by unchanged runs.
    private static func edit(_ plan: FilePlan, rng: inout SeededGenerator) -> (base: [String], head: [String]) {
        let isLarge = plan.kind == .large
        let regionCount = min(plan.budget, max(1, min(isLarge ? 24 : 8, plan.budget / 15 + rng.int(0...2))))
        var shares = Array(repeating: 1, count: regionCount)
        for _ in 0..<(plan.budget - regionCount) { shares[rng.int(0...(regionCount - 1))] += 1 }

        let regions = shares.map { share -> (deletions: Int, additions: Int) in
            let deletions = Int((Double(share) * Double.random(in: 0...0.7, using: &rng)).rounded())
            return (deletions, share - deletions)
        }
        let gaps = (0...regionCount).map { index -> Int in
            if index == 0 { return rng.chance(0.15) ? 0 : rng.int(1...40) }
            if index == regionCount { return plan.newline == .both ? rng.int(1...40) : rng.int(1...2) }
            return isLarge ? rng.int(10...120) : rng.int(2...60)
        }
        let baseLines = SyntheticText.document(
            plan.style, count: gaps.reduce(0, +) + regions.reduce(0) { $0 + $1.deletions }, rng: &rng
        )
        var base = baseLines[...]
        var head: [String] = []
        for (index, region) in regions.enumerated() {
            head += base.prefix(gaps[index])
            base = base.dropFirst(gaps[index])
            let removed = base.prefix(region.deletions)
            base = base.dropFirst(region.deletions)
            let mutated = removed.prefix(region.additions).map { SyntheticText.mutate($0, rng: &rng) }
            head += mutated + SyntheticText.fresh(plan.style, count: region.additions - mutated.count, rng: &rng)
        }
        head += base
        return (baseLines, head)
    }

    private static func join(_ lines: [String], newline: Bool) -> String {
        lines.joined(separator: "\n") + (newline && !lines.isEmpty ? "\n" : "")
    }

    private static func viewedState(for status: ChangedFile.Status, rng: inout SeededGenerator) -> ViewedState {
        let roll = Double.random(in: 0..<1, using: &rng)
        if roll < 0.25 { return .viewed }
        if roll < 0.33, status == .modified || status == .renamed { return .dismissed }
        return .unviewed
    }

    // MARK: Threads

    private static func makeThreads(
        files: [ChangedFile], hunks: [String: [PatchWriter.Hunk]], fileCount: Int, createdAt: Date,
        rng: inout SeededGenerator
    ) -> [ReviewThread] {
        let commentable = files.filter { hunks[$0.path] != nil }
        let textFiles = files.filter { $0.patch != nil || $0.additions + $0.deletions > 0 }
        var threads: [ReviewThread] = []
        var commentIndex = 0
        var time = createdAt

        func comments(_ count: Int, rng: inout SeededGenerator) -> [ReviewComment] {
            (0..<count).map { _ in
                commentIndex += 1
                time += Double(rng.int(60...7_200))
                return ReviewComment(
                    id: "PRRC_synthetic_\(commentIndex)", author: Actor(login: rng.pick(authors), avatarURL: nil),
                    bodyText: commentBody(rng: &rng), createdAt: time
                )
            }
        }

        for index in 0..<max(4, fileCount / 4) {
            let file = rng.pick(commentable)
            let fileHunks = hunks[file.path]!
            let preferred: DiffSide = file.status == .added ? .right : file.status == .removed ? .left : rng.chance(0.7) ? .right : .left
            let side = fileHunks.contains { (preferred == .right ? $0.newCount : $0.oldCount) > 0 } ? preferred
                : preferred == .right ? .left : .right
            let hunk = rng.pick(fileHunks.filter { (side == .right ? $0.newCount : $0.oldCount) > 0 })
            let (start, count) = side == .right ? (hunk.newStart, hunk.newCount) : (hunk.oldStart, hunk.oldCount)
            let line = start + rng.int(0...(count - 1))
            let startLine = line > start && rng.chance(0.25) ? line - rng.int(1...min(6, line - start)) : nil
            threads.append(ReviewThread(
                id: "PRRT_synthetic_\(index + 1)", path: file.path, line: line, startLine: startLine, side: side,
                isResolved: rng.chance(0.35), isOutdated: false,
                comments: comments(rng.chance(0.2) ? rng.int(4...7) : rng.int(1...3), rng: &rng)
            ))
        }
        for index in 0..<max(2, fileCount / 30) {
            let file = rng.pick(textFiles)
            threads.append(ReviewThread(
                id: "PRRT_synthetic_outdated_\(index + 1)", path: file.path, line: nil, startLine: nil,
                side: file.status == .removed ? .left : .right,
                isResolved: rng.chance(0.5), isOutdated: true, comments: comments(rng.int(1...3), rng: &rng)
            ))
        }
        return threads
    }

    // MARK: Conversation

    /// Uses its own generator, so the files and threads stay the same as before the conversation existed.
    private static func makeConversation(files: [ChangedFile], threads: [ReviewThread], createdAt: Date, seed: UInt64) -> Conversation {
        var rng = SeededGenerator(seed: seed &+ 0x5EED)
        var time = createdAt
        func next() -> Date {
            time += Double(rng.int(600...14_400))
            return time
        }
        func author(_ login: String, bot: Bool = false, association: String = "MEMBER") -> Author {
            Author(actor: Actor(login: login, avatarURL: nil), isBot: bot, association: association)
        }
        func html(_ markdown: String) -> String {
            "<p>" + markdown.replacingOccurrences(of: "&", with: "&amp;").replacingOccurrences(of: "<", with: "&lt;")
                .replacingOccurrences(of: "\n\n", with: "</p><p>") + "</p>"
        }

        var items: [TimelineItem] = [
            .comment(IssueComment(
                id: "IC_synthetic_1", author: author("vercel", bot: true, association: "NONE"),
                bodyHTML: "<p><strong>The latest updates on your projects.</strong></p><table><thead><tr><th>Name</th><th>Status</th>"
                    + "<th>Updated (UTC)</th></tr></thead><tbody><tr><td><strong>storefront</strong></td><td>✅ Ready</td>"
                    + "<td>Sep 24, 2026 9:12am</td></tr></tbody></table>",
                createdAt: next(), url: nil, minimizedReason: nil
            )),
            .comment(IssueComment(
                id: "IC_synthetic_2", author: author(rng.pick(authors)), bodyHTML: html(commentBody(rng: &rng)),
                createdAt: next(), url: nil, minimizedReason: nil
            )),
        ]

        let placed = threads.filter { !$0.isOutdated && !$0.comments.isEmpty }.prefix(3)
        var roots: [InlineComment] = []
        var replies: [InlineComment] = []
        for thread in placed {
            let hunk = files.first { $0.path == thread.path }?.patch?.split(separator: "\n").prefix(8).joined(separator: "\n") ?? ""
            for (index, comment) in thread.comments.enumerated() {
                let inline = InlineComment(
                    id: comment.id, author: comment.author.map { author($0.login) }, bodyHTML: html(comment.bodyText),
                    createdAt: comment.createdAt, path: thread.path, diffHunk: hunk,
                    replyToID: index == 0 ? nil : thread.comments[0].id, isOutdated: false
                )
                if index == 0 { roots.append(inline) } else { replies.append(inline) }
            }
        }
        items.append(.review(Review(
            id: "PRR_synthetic_1", author: author(rng.pick(authors)), state: .commented,
            bodyHTML: html("A few notes on the \(rng.pick(Words.nouns)) flow."), createdAt: next(), url: nil, comments: roots
        )))
        items.append(.review(Review(
            id: "PRR_synthetic_2", author: author(rng.pick(authors)), state: .commented, bodyHTML: "", createdAt: next(),
            url: nil, comments: replies
        )))
        items.append(.review(Review(
            id: "PRR_synthetic_3", author: author(rng.pick(authors)), state: .changesRequested,
            bodyHTML: html(commentBody(rng: &rng)), createdAt: next(), url: nil, comments: []
        )))
        items.append(.comment(IssueComment(
            id: "IC_synthetic_3", author: author(rng.pick(authors), association: "CONTRIBUTOR"),
            bodyHTML: html("Old status note."), createdAt: next(), url: nil, minimizedReason: "OUTDATED"
        )))
        items.append(.review(Review(
            id: "PRR_synthetic_4", author: author(rng.pick(authors)), state: .approved, bodyHTML: "", createdAt: next(),
            url: nil, comments: []
        )))

        let started = time
        func check(_ name: String, workflow: String?, _ state: Check.State, seconds: Int, required: Bool = false) -> Check {
            Check(
                name: name, workflow: workflow, event: workflow == nil ? nil : "pull_request", state: state, summary: nil,
                url: nil, avatarURL: nil, isRequired: required, startedAt: started,
                completedAt: state == .pending ? nil : started + Double(seconds)
            )
        }
        let checks = [
            check("typecheck", workflow: "Checks", .success, seconds: 184, required: true),
            check("lint", workflow: "Checks", .success, seconds: 71, required: true),
            check("unit tests", workflow: "Checks", .failure, seconds: 412, required: true),
            check("e2e", workflow: "Checks", .pending, seconds: 0),
            check("deploy preview", workflow: "Preview", .skipped, seconds: 0),
            Check(
                name: "Vercel – storefront", workflow: nil, event: nil, state: .success, summary: "Deployment has completed",
                url: nil, avatarURL: nil, isRequired: false, startedAt: nil, completedAt: nil
            ),
        ]
        return Conversation(items: items, checks: checks)
    }

    private static func commentBody(rng: inout SeededGenerator) -> String {
        let noun = rng.pick(Words.nouns)
        let verb = rng.pick(Words.verbs)
        if rng.chance(0.3) {
            return """
            I traced this through `\(verb)\(noun.capitalizedFirst)` and the \(noun) can reach this branch while it is still \(rng.pick(Words.statuses)). \(SyntheticText.paragraph(rng: &rng))

            Steps to reproduce:
            1. Create a \(noun) with two \(rng.pick(Words.nouns))s.
            2. \(verb.capitalizedFirst) it while the \(rng.pick(Words.nouns)) webhook retries.
            3. Open the \(noun) page. The total is wrong \(rng.pick(Words.emoji))

            ```ts
            const \(noun) = await \(verb)\(noun.capitalizedFirst)(id, { attempt: \(rng.int(2...5)) })
            expect(\(noun).status).toBe('\(rng.pick(Words.statuses))')
            ```

            \(SyntheticText.paragraph(rng: &rng))
            """
        }
        return rng.pick([
            "nit: rename `\(noun)` to `\(rng.pick(Words.nouns))\(rng.pick(Words.suffixes))` so the intent is clear.",
            "Does this still hold when the \(noun) is \(rng.pick(Words.statuses))?",
            "LGTM \(rng.pick(Words.emoji))",
            "This runs once per \(noun). Can we batch it?",
            "Why not reuse `\(verb)\(noun.capitalizedFirst)` from core utils?",
            "\(rng.pick(Words.cjk))。这里需要处理空值的情况。",
            "Should this be behind a feature flag? 🤔",
            "Done in the next commit.",
        ])
    }

    private static let authors = ["octocat", "rik", "marvin", "emmy", "khoi-iso", "hubot"]
}

private struct PathFactory {
    private var used = Set<String>()

    mutating func unique(_ path: String) -> String {
        var candidate = path
        var counter = 2
        while used.contains(candidate) {
            let url = path as NSString
            let name = (url.lastPathComponent as NSString)
            let stem = name.deletingPathExtension.components(separatedBy: ".").first ?? ""
            let suffix = String(name.lastPathComponent.dropFirst(stem.count))
            candidate = url.deletingLastPathComponent + "/\(stem)\(counter)\(suffix)"
            counter += 1
        }
        used.insert(candidate)
        return candidate
    }

    mutating func text(rng: inout SeededGenerator) -> (String, TextStyle) {
        let noun = rng.pick(Words.nouns)
        let verb = rng.pick(Words.verbs)
        let roll = Double.random(in: 0..<1, using: &rng)
        let language: Language = roll < 0.6 ? .typescript : roll < 0.72 ? .swift : roll < 0.79 ? .sql
            : roll < 0.87 ? .markdown : roll < 0.93 ? .json : .yaml
        switch language {
        case .typescript:
            let directory = rng.pick([
                "apps/platform/gateway/src/\(rng.pick(["routes", "handlers", "middleware", "lib", "workflows"]))",
                "apps/platform/gateway/src/routes/\(noun)s",
                "packages/commerce/\(rng.pick(["checkout", "pricing", "inventory", "refunds"]))/src",
                "packages/core/\(rng.pick(["utils", "ids", "money"]))/src",
                "services/assistant/src/\(rng.pick(["tools", "prompts", "memory"]))",
            ])
            let indent = rng.chance(0.2) ? "\t" : "  "
            if rng.chance(0.3) {
                return (unique("\(directory)/__tests__/\(verb)\(noun.capitalizedFirst).spec.ts"),
                        TextStyle(language: .typescript, flavor: .test, indent: indent))
            }
            let name = rng.chance(0.25) ? "\(noun.capitalizedFirst)\(rng.pick(Words.suffixes)).tsx" : "\(verb)\(noun.capitalizedFirst).ts"
            return (unique("\(directory)/\(name)"), TextStyle(language: .typescript, flavor: .source, indent: indent))
        case .swift:
            let module = rng.pick(["Checkout", "Livestream", "Chat", "Wallet"])
            if rng.chance(0.3) {
                return (unique("ios/Modules/\(module)/Tests/\(noun.capitalizedFirst)Tests.swift"),
                        TextStyle(language: .swift, flavor: .test, indent: "    "))
            }
            return (unique("ios/Modules/\(module)/Sources/\(noun.capitalizedFirst)\(rng.pick(Words.suffixes)).swift"),
                    TextStyle(language: .swift, flavor: .source, indent: "    "))
        case .sql:
            let path = rng.chance(0.7)
                ? "packages/db/schema/db/migrations/202609\(String(format: "%02d%06d", rng.int(1...30), rng.int(0...235_959)))_\(verb)_\(noun)s.sql"
                : "packages/db/queries/\(noun)s.sql"
            return (unique(path), TextStyle(language: .sql, flavor: .source, indent: rng.chance(0.5) ? "\t" : "  "))
        case .markdown:
            let path = rng.chance(0.7)
                ? "docs/\(rng.pick(["architecture", "runbooks", "guides"]))/\(noun)-\(rng.pick(Words.topics)).md"
                : "packages/commerce/\(rng.pick(["checkout", "pricing", "inventory", "refunds"]))/README.md"
            return (unique(path), TextStyle(language: .markdown, flavor: .source, indent: ""))
        case .json:
            let path = rng.pick([
                "packages/commerce/\(rng.pick(["checkout", "pricing", "inventory", "refunds"]))/package.json",
                "config/\(noun)s.json",
                "apps/platform/gateway/src/i18n/\(rng.pick(["en", "ja", "zh-CN", "ko", "fr"])).json",
            ])
            return (unique(path), TextStyle(language: .json, flavor: .source, indent: "  "))
        case .yaml:
            let path = rng.chance(0.6) ? ".github/workflows/\(noun)-\(verb).yml" : "infra/\(rng.pick(["staging", "production"]))/\(noun).yaml"
            return (unique(path), TextStyle(language: .yaml, flavor: .source, indent: "  "))
        }
    }

    mutating func renamedFrom(_ path: String, rng: inout SeededGenerator) -> String {
        let url = path as NSString
        if rng.chance(0.5) {
            return unique(url.deletingLastPathComponent + "/legacy/" + url.lastPathComponent)
        }
        let name = url.lastPathComponent
        let stem = name.components(separatedBy: ".").first ?? name
        return unique(url.deletingLastPathComponent + "/" + rng.pick(Words.verbs) + stem.capitalizedFirst + name.dropFirst(stem.count))
    }

    mutating func binary(rng: inout SeededGenerator) -> String {
        let noun = rng.pick(Words.nouns)
        return unique(rng.pick([
            "apps/platform/gateway/src/assets/\(noun)-hero.png",
            "docs/images/\(noun)-flow.png",
            "packages/core/icons/src/fonts/\(noun)-icons.woff2",
        ]))
    }

    mutating func large(_ index: Int) -> (String, TextStyle) {
        let options: [(String, TextStyle)] = [
            ("packages/db/schema/schema.sql", TextStyle(language: .sql, flavor: .source, indent: "\t")),
            ("packages/graphql/src/graphql-env.d.ts", TextStyle(language: .typescript, flavor: .source, indent: "  ")),
            ("config/fixtures/catalog.json", TextStyle(language: .json, flavor: .source, indent: "  ")),
        ]
        let (path, style) = options[index % options.count]
        return (unique(path), style)
    }
}
