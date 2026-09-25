import Foundation
import PRModels
import Testing
@testable import GitHubKit

struct GitHubClientTests {
    private let token = "token-\(UUID().uuidString)"
    private let ref = PRRef(owner: "octo", repo: "app", number: 7)

    @Test func setViewedReportsOnlyFailedAliases() async throws {
        let session = StubURLProtocol.session(token: token) { _ in
            """
            {"data": {"m0": {"clientMutationId": null}, "m1": null, "m2": {"clientMutationId": null}},
             "errors": [{"type": "NOT_FOUND", "path": ["m1"], "message": "No file at b.swift"}]}
            """
        }
        let client = GitHubClient(token: token, session: session)
        await #expect(throws: GitHubError.partialFailure(paths: ["b.swift"])) {
            try await client.setViewed(true, paths: ["a.swift", "b.swift", "c.swift"], pullRequestID: "PR_1")
        }
    }

    @Test func setViewedKeepsErrorsWithoutAliasPaths() async throws {
        let session = StubURLProtocol.session(token: token) { _ in
            """
            {"data": null, "errors": [{"type": "NOT_FOUND", "path": ["m0"], "message": "No file"},
                                      {"message": "Something went wrong"}]}
            """
        }
        let client = GitHubClient(token: token, session: session)
        await #expect(throws: GitHubError.notFound) {
            try await client.setViewed(true, paths: ["a.swift", "b.swift"], pullRequestID: "PR_1")
        }
    }

    @Test func mergeBaseReadsCompareResponse() async throws {
        let session = StubURLProtocol.session(token: token) { _ in
            """
            {"status": "diverged", "ahead_by": 3, "behind_by": 5, "total_commits": 3,
             "base_commit": {"sha": "b4se"}, "merge_base_commit": {"sha": "m3rge"}, "commits": []}
            """
        }
        let client = GitHubClient(token: token, session: session)
        #expect(try await client.mergeBaseOid(of: ref, base: "b4se", head: "h3ad") == "m3rge")
        let url = try #require(StubURLProtocol.requests(token: token).first?.url)
        #expect(url.path == "/repos/octo/app/compare/b4se...h3ad")
        let query = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems ?? []
        #expect(query.contains(URLQueryItem(name: "page", value: "2")))
    }

    @Test func reviewThreadsFetchesRemainingCommentPages() async throws {
        let session = StubURLProtocol.session(token: token) { request in
            let body = try JSONDecoder().decode(GraphQLBody.self, from: request.body)
            if body.query.contains("reviewThreads") {
                return """
                {"data": {"repository": {"pullRequest": {"reviewThreads": {
                  "pageInfo": {"hasNextPage": false, "endCursor": null},
                  "nodes": [\(thread("T1", comments: ["c1", "c2"], next: "k1")), \(thread("T2", comments: ["d1"], next: nil))]
                }}}}}
                """
            }
            guard body.variables["id"] == "T1" else { throw URLError(.badURL) }
            return switch body.variables["cursor"] {
            case "k1": #"{"data": {"node": {"comments": \#(comments(["c3"], next: "k2"))}}}"#
            case "k2": #"{"data": {"node": {"comments": \#(comments(["c4"], next: nil))}}}"#
            default: throw URLError(.badURL)
            }
        }
        let threads = try await GitHubClient(token: token, session: session).reviewThreads(ref)
        #expect(threads.map(\.id) == ["T1", "T2"])
        #expect(threads.map { $0.comments.map(\.id) } == [["c1", "c2", "c3", "c4"], ["d1"]])
        #expect(StubURLProtocol.requests(token: token).count == 3)
    }

    @Test func reviewThreadsReadPendingStateAndPermissions() async throws {
        let session = StubURLProtocol.session(token: token) { _ in
            let nodes = [commentJSON("c1", state: "SUBMITTED", review: "PRR_1"), commentJSON("c2", state: "PENDING", review: "PRR_2")]
            return #"{"data": {"repository": {"pullRequest": {"reviewThreads": {"pageInfo": {"hasNextPage": false, "endCursor": null}, "nodes": [\#(threadJSON("T1", comments: nodes))]}}}}}"#
        }
        let threads = try await GitHubClient(token: token, session: session).reviewThreads(ref)
        #expect(threads.first?.comments == [comment("c1", pending: false, review: "PRR_1"), comment("c2", pending: true, review: "PRR_2")])
        let body = try JSONDecoder().decode(GraphQLBody.self, from: try #require(StubURLProtocol.requests(token: token).first).body)
        #expect(body.query.contains("body bodyText state createdAt viewerCanUpdate viewerCanDelete"))
        #expect(body.query.contains("pullRequestReview { id }"))
    }

    @Test func filesArriveWhenTheDetailRequestFails() async throws {
        let session = StubURLProtocol.session(token: token) { request in
            let body = String(decoding: request.body, as: UTF8.self)
            if request.url.path().hasSuffix("/files") {
                return #"[{"filename":"a.ts","status":"modified","additions":1,"deletions":0,"patch":"@@ -1 +1 @@\n-a\n+b"}]"#
            }
            if body.contains("viewerViewedState") {
                return #"{"data":{"repository":{"pullRequest":{"id":"PR_1","files":{"pageInfo":{"hasNextPage":false,"endCursor":null},"nodes":[{"path":"a.ts","viewerViewedState":"VIEWED"}]}}}}}"#
            }
            if body.contains("reviewThreads") {
                return #"{"data":{"repository":{"pullRequest":{"reviewThreads":{"pageInfo":{"hasNextPage":false,"endCursor":null},"nodes":[]}}}}}"#
            }
            return #"{"errors":[{"message":"boom","type":"INTERNAL"}]}"#
        }
        let client = GitHubClient(token: token, session: session)
        var received: [PullRequestPart] = []
        do {
            for try await part in client.parts(of: PRRef(owner: "o", repo: "r", number: 1)) { received.append(part) }
            Issue.record("The detail error must end the stream")
        } catch {}
        let files = received.compactMap { part -> (String, [ChangedFile])? in
            if case let .files(id, files) = part { (id, files) } else { nil }
        }
        #expect(files.first?.0 == "PR_1")
        #expect(files.first?.1.map(\.viewedState) == [.viewed])
    }

    @Test func conversationKeepsCommentsAndReviewsAndPagesChecks() async throws {
        let session = StubURLProtocol.session(token: token) { request in
            let body = try JSONDecoder().decode(GraphQLBody.self, from: request.body)
            if body.query.contains("timelineItems") {
                return #"""
                {"data":{"repository":{"pullRequest":{"timelineItems":{"pageInfo":{"hasNextPage":false,"endCursor":null},"nodes":[
                  {"__typename":"IssueComment","id":"IC1","bodyHTML":"<p>hi</p>","createdAt":"2026-09-01T00:00:00Z","url":"https://github.com/c",
                   "isMinimized":true,"minimizedReason":"outdated","authorAssociation":"MEMBER",
                   "author":{"__typename":"Bot","login":"vercel","avatarUrl":"https://avatars.githubusercontent.com/in/8329?s=80"}},
                  {"__typename":"PullRequestReview","id":"R1","state":"PENDING","bodyHTML":"","createdAt":"2026-09-01T00:00:00Z",
                   "submittedAt":null,"url":null,"authorAssociation":"MEMBER","author":null,"comments":{"nodes":[]}},
                  {"__typename":"PullRequestReview","id":"R2","state":"APPROVED","bodyHTML":"","createdAt":"2026-09-01T00:00:00Z",
                   "submittedAt":"2026-09-02T00:00:00Z","url":null,"authorAssociation":"MEMBER","author":null,"comments":{"nodes":[
                     {"id":"C2","bodyHTML":"<p>r</p>","createdAt":"2026-09-02T00:00:00Z","path":"a.ts","diffHunk":"@@ -1 +1 @@","outdated":false,
                      "authorAssociation":"MEMBER","replyTo":{"id":"C1"},"author":null}]}}
                ]}}}}}
                """#
            }
            let context = body.variables["cursor"] == nil
                ? #"{"__typename":"CheckRun","name":"lint","status":"COMPLETED","conclusion":"TIMED_OUT","detailsUrl":null,"startedAt":null,"completedAt":null,"isRequired":true,"checkSuite":{"app":null,"workflowRun":{"event":"pull_request","workflow":{"name":"Checks"}}}}"#
                : #"{"__typename":"StatusContext","context":"vercel","state":"PENDING","description":"Building","targetUrl":null,"avatarUrl":null,"isRequired":false}"#
            let next = body.variables["cursor"] == nil ? #"true,"endCursor":"k1""# : #"false,"endCursor":null"#
            return #"{"data":{"repository":{"pullRequest":{"commits":{"nodes":[{"commit":{"statusCheckRollup":{"contexts":{"pageInfo":{"hasNextPage":\#(next)},"nodes":[\#(context)]}}}}]}}}}}"#
        }
        let conversation = try await GitHubClient(token: token, session: session).conversation(of: ref)

        guard conversation.items.count == 2, case let .comment(comment) = conversation.items[0],
              case let .review(review) = conversation.items[1]
        else { Issue.record("Expected a comment and the submitted review, got \(conversation.items)"); return }
        #expect(comment.author?.isBot == true)
        #expect(comment.minimizedReason == "outdated")
        #expect(review.state == .approved)
        #expect(review.createdAt == Date(timeIntervalSince1970: 1_788_307_200))
        #expect(review.comments.first?.replyToID == "C1")
        #expect(conversation.checks.map(\.name) == ["lint", "vercel"])
        #expect(conversation.checks.map(\.state) == [.failure, .pending])
        #expect(conversation.checks.first?.workflow == "Checks")
    }

    @Test func openPullRequestsDecodesDraftsGhostsAndMissingChecks() async throws {
        let session = StubURLProtocol.session(token: token) { _ in
            #"""
            {"data":{"search":{"issueCount":130,"pageInfo":{"hasNextPage":false,"endCursor":null},"nodes":[
              {"number":12,"title":"Ready","isDraft":false,"updatedAt":"2026-09-01T00:00:00Z","totalCommentsCount":3,
               "reviewDecision":"APPROVED","repository":{"name":"app","owner":{"login":"octo"}},
               "author":{"login":"rik","avatarUrl":"https://avatars.githubusercontent.com/u/1?s=80"},
               "commits":{"nodes":[{"commit":{"statusCheckRollup":{"state":"ERROR"}}}]}},
              {},
              {"number":9,"title":"Draft","isDraft":true,"updatedAt":"2026-09-02T00:00:00Z","totalCommentsCount":null,
               "reviewDecision":null,"repository":{"name":"app","owner":{"login":"octo"}},"author":null,
               "commits":{"nodes":[{"commit":{"statusCheckRollup":null}}]}}
            ]}}}
            """#
        }
        let list = try await GitHubClient(token: token, session: session)
            .openPullRequests(in: RepoRef(owner: "octo", name: "app"), scope: .others)
        #expect(list.totalCount == 130)
        #expect(
            list.pullRequests.map(\.ref) == [PRRef(owner: "octo", repo: "app", number: 12), PRRef(owner: "octo", repo: "app", number: 9)])
        let (ready, draft) = (list.pullRequests[0], list.pullRequests[1])
        #expect(ready.checks == .failure)
        #expect(ready.reviewDecision == .approved)
        #expect(ready.commentCount == 3)
        #expect(ready.author?.avatarURL?.host() == "avatars.githubusercontent.com")
        #expect(draft.isDraft)
        #expect(draft.author == nil)
        #expect(draft.checks == nil)
        #expect(draft.reviewDecision == nil)
        #expect(draft.commentCount == 0)
        let body = try JSONDecoder().decode(GraphQLBody.self, from: try #require(StubURLProtocol.requests(token: token).first).body)
        #expect(body.variables["query"] == "repo:octo/app is:pr is:open -author:@me sort:updated-desc")
    }

    @Test func authorQuerySearchesOneLogin() async throws {
        let session = StubURLProtocol.session(token: token) { _ in
            #"{"data":{"search":{"issueCount":0,"pageInfo":{"hasNextPage":false,"endCursor":null},"nodes":[]}}}"#
        }
        let author = try #require(AuthorQuery(string: "@rik"))
        _ = try await GitHubClient(token: token, session: session)
            .openPullRequests(in: RepoRef(owner: "octo", name: "app"), author: author)
        let body = try JSONDecoder().decode(GraphQLBody.self, from: try #require(StubURLProtocol.requests(token: token).first).body)
        #expect(body.variables["query"] == "repo:octo/app is:pr is:open author:rik sort:updated-desc")
    }

    @Test func openPullRequestsStopsAtOneHundred() async throws {
        let session = StubURLProtocol.session(token: token) { request in
            let body = try JSONDecoder().decode(GraphQLBody.self, from: request.body)
            let page = body.variables["cursor"] == nil ? 0 : 1
            let nodes = (0..<50).map { index in
                #"{"number":\#(page * 50 + index + 1),"title":"t","isDraft":false,"updatedAt":"2026-09-01T00:00:00Z","totalCommentsCount":0,"reviewDecision":null,"repository":{"name":"app","owner":{"login":"octo"}},"author":null,"commits":{"nodes":[]}}"#
            }
            return
                #"{"data":{"search":{"issueCount":400,"pageInfo":{"hasNextPage":true,"endCursor":"k\#(page + 1)"},"nodes":[\#(nodes.joined(separator: ","))]}}}"#
        }
        let list = try await GitHubClient(token: token, session: session)
            .openPullRequests(in: RepoRef(owner: "octo", name: "app"), scope: .mine)
        #expect(list.pullRequests.count == 100)
        #expect(Set(list.pullRequests.map(\.ref.number)).count == 100)
        let requests = try StubURLProtocol.requests(token: token).map { try JSONDecoder().decode(GraphQLBody.self, from: $0.body) }
        #expect(requests.map { $0.variables["cursor"] } == [nil, "k1"])
        #expect(requests.first?.variables["query"]?.contains(" author:@me ") == true)
    }

    @Test func statusReadsMergeFieldsFromTheFirstPageOnly() async throws {
        let session = StubURLProtocol.session(token: token) { request in
            let body = try JSONDecoder().decode(GraphQLBody.self, from: request.body)
            let first = body.variables["first"] == "true"
            let context =
                #"{"__typename":"StatusContext","context":"ci\#(first ? 1 : 2)","state":"SUCCESS","description":null,"targetUrl":null,"avatarUrl":null,"isRequired":true}"#
            let next = first ? #"true,"endCursor":"k1""# : #"false,"endCursor":null"#
            let commits =
                #""commits":{"nodes":[{"commit":{"statusCheckRollup":{"contexts":{"pageInfo":{"hasNextPage":\#(next)},"nodes":[\#(context)]}}}}]}"#
            guard first else { return #"{"data":{"repository":{"pullRequest":{\#(commits)}}}}"# }
            return #"""
                {"data":{"repository":{"viewerPermission":"MAINTAIN","mergeCommitAllowed":false,"squashMergeAllowed":true,"rebaseMergeAllowed":true,
                  "viewerDefaultMergeMethod":"REBASE","autoMergeAllowed":true,"pullRequest":{
                  "state":"OPEN","isDraft":false,"headRefOid":"h3ad","mergeable":"MERGEABLE","mergeStateStatus":"HAS_HOOKS","reviewDecision":"REVIEW_REQUIRED",
                  "viewerDidAuthor":true,"viewerCanUpdate":true,"viewerCanMergeAsAdmin":false,"viewerCanEnableAutoMerge":true,"viewerCanDisableAutoMerge":false,
                  "viewerLatestReview":{"state":"COMMENTED"},"isMergeQueueEnabled":true,
                  "mergeQueueEntry":{"position":2,"state":"AWAITING_CHECKS","estimatedTimeToMerge":300,"enqueuedAt":"2026-09-01T00:00:00Z"},
                  "mergeQueue":{"url":"https://github.com/octo/app/queue/main","entries":{"totalCount":4}},
                  "autoMergeRequest":{"mergeMethod":"SQUASH","enabledBy":{"login":"rik"}},\#(commits)}}}}
                """#
        }
        let status = try await GitHubClient(token: token, session: session).status(of: ref)
        #expect(status.checks.map(\.name) == ["ci1", "ci2"])
        let merge = try #require(status.merge)
        #expect(merge.headOid == "h3ad")
        #expect(merge.mergeStateStatus == .hasHooks)
        #expect(merge.reviewDecision == .reviewRequired)
        #expect(merge.viewerCanMerge && merge.viewerDidAuthor && !merge.viewerCanMergeAsAdmin)
        #expect(merge.viewerReviewState == .commented)
        #expect(merge.allowedMethods == [.squash, .rebase])
        #expect(merge.defaultMethod == .rebase)
        #expect(
            merge.queueEntry
                == MergeStatus.QueueEntry(
                    position: 2, totalCount: 4, state: .awaitingChecks, estimatedSecondsToMerge: 300,
                    enqueuedAt: Date(timeIntervalSince1970: 1_788_220_800)
                ))
        #expect(merge.mergeQueueURL?.absoluteString == "https://github.com/octo/app/queue/main")
        #expect(merge.autoMerge == MergeStatus.AutoMerge(method: .squash, enabledBy: "rik"))
        let requests = try StubURLProtocol.requests(token: token).map { try JSONDecoder().decode(GraphQLBody.self, from: $0.body) }
        #expect(requests.map { $0.variables["first"] } == ["true", "false"])
        #expect(requests.first?.query.contains("@include(if: $first)") == true)
    }

    @Test func statusWithReadPermissionCannotMerge() async throws {
        let session = StubURLProtocol.session(token: token) { _ in
            #"""
            {"data":{"repository":{"viewerPermission":"TRIAGE","mergeCommitAllowed":true,"squashMergeAllowed":false,"rebaseMergeAllowed":false,
              "viewerDefaultMergeMethod":"MERGE","autoMergeAllowed":false,"pullRequest":{
              "state":"MERGED","isDraft":false,"headRefOid":"h","mergeable":"UNKNOWN","mergeStateStatus":"SOMETHING_NEW","reviewDecision":null,
              "viewerDidAuthor":false,"viewerCanUpdate":false,"viewerCanMergeAsAdmin":false,"viewerCanEnableAutoMerge":false,
              "viewerCanDisableAutoMerge":false,"viewerLatestReview":null,"isMergeQueueEnabled":false,"mergeQueueEntry":null,"mergeQueue":null,
              "autoMergeRequest":null,"commits":{"nodes":[{"commit":{"statusCheckRollup":null}}]}}}}}
            """#
        }
        let merge = try #require(try await GitHubClient(token: token, session: session).status(of: ref).merge)
        #expect(!merge.viewerCanMerge)
        #expect(merge.state == .merged)
        #expect(merge.mergeable == .unknown)
        #expect(merge.mergeStateStatus == .unknown)
        #expect(merge.queueEntry == nil && merge.autoMerge == nil)
    }

    @Test(arguments: [
        (PullRequestAction.review(.approve, body: ""), "addPullRequestReview", ["pullRequestId": "PR_1", "event": "APPROVE"]),
        (
            .review(.requestChanges, body: "Fix it"), "addPullRequestReview",
            ["pullRequestId": "PR_1", "event": "REQUEST_CHANGES", "body": "Fix it"]
        ),
        (
            .merge(.squash, headOid: "h3ad", title: "Title (#7)", body: nil), "mergePullRequest",
            ["pullRequestId": "PR_1", "mergeMethod": "SQUASH", "expectedHeadOid": "h3ad", "commitHeadline": "Title (#7)"]
        ),
        (
            .merge(.rebase, headOid: "h3ad", title: nil, body: nil), "mergePullRequest",
            ["pullRequestId": "PR_1", "mergeMethod": "REBASE", "expectedHeadOid": "h3ad"]
        ),
        (
            .enableAutoMerge(.merge, headOid: "h3ad"), "enablePullRequestAutoMerge",
            ["pullRequestId": "PR_1", "mergeMethod": "MERGE", "expectedHeadOid": "h3ad"]
        ),
        (.disableAutoMerge, "disablePullRequestAutoMerge", ["pullRequestId": "PR_1"]),
        (.enqueue(headOid: "h3ad"), "enqueuePullRequest", ["pullRequestId": "PR_1", "expectedHeadOid": "h3ad"]),
        (.dequeue, "dequeuePullRequest", ["id": "PR_1"]),
        (.markReadyForReview, "markPullRequestReadyForReview", ["pullRequestId": "PR_1"]),
        (.convertToDraft, "convertPullRequestToDraft", ["pullRequestId": "PR_1"]),
    ])
    func actionSendsOneMutationWithOnlyTheGivenInputs(action: PullRequestAction, field: String, variables: [String: String]) async throws {
        let session = StubURLProtocol.session(token: token) { _ in #"{"data":{"\#(field)":{"clientMutationId":null}}}"# }
        try await GitHubClient(token: token, session: session).perform(action, pullRequestID: "PR_1")
        let requests = try StubURLProtocol.requests(token: token).map { try JSONDecoder().decode(GraphQLBody.self, from: $0.body) }
        let body = try #require(requests.first)
        #expect(requests.count == 1)
        #expect(body.query.hasPrefix("mutation("))
        #expect(body.query.contains("\(field)(input: {"))
        #expect(body.variables == variables)
        for name in variables.keys { #expect(body.query.contains("\(name): $\(name)")) }
    }

    @Test func rejectedActionThrowsGitHubsMessage() async throws {
        let session = StubURLProtocol.session(token: token) { _ in
            #"{"data":{"mergePullRequest":null},"errors":[{"type":"UNPROCESSABLE","path":["mergePullRequest"],"message":"Base branch was modified. Review and try the merge again."}]}"#
        }
        await #expect(throws: GitHubError.rejected("Base branch was modified. Review and try the merge again.")) {
            try await GitHubClient(token: token, session: session)
                .perform(.merge(.merge, headOid: "h", title: nil, body: nil), pullRequestID: "PR_1")
        }
        #expect(GitHubError.rejected("Nope.").localizedDescription == "Nope.")
    }

    @Test func singleCommentPostsOneCommentReviewAndReturnsItsThread() async throws {
        let session = StubURLProtocol.session(token: token) { _ in
            let threads = [
                threadJSON("T_new", comments: [commentJSON("c1", state: "SUBMITTED", review: "PRR_new")]),
                threadJSON("T_other", comments: [commentJSON("c2", state: "SUBMITTED", review: "PRR_other")]),
            ]
            return #"{"data": {"addPullRequestReview": {"pullRequestReview": {"id": "PRR_new", "pullRequest": {"reviewThreads": {"nodes": [\#(threads.joined(separator: ", "))]}}}}}}"#
        }
        let target = CommentTarget(path: "a.swift", side: .right, line: 12)
        let result = try await GitHubClient(token: token, session: session)
            .comment(.addThread(target, body: "Nit", review: nil), pullRequestID: "PR_1")
        #expect(result == .thread(thread("T_new", comments: [comment("c1", pending: false, review: "PRR_new")])))
        let requests = try StubURLProtocol.requests(token: token).map { try JSONDecoder().decode(GraphQLBody.self, from: $0.body) }
        let body = try #require(requests.first)
        #expect(requests.count == 1)
        #expect(body.query.contains(
            "addPullRequestReview(input: {pullRequestId: $pullRequestId, event: $event, threads: [{body: $body, path: $path, line: $line, side: $side}]})"
        ))
        #expect(body.variables == ["pullRequestId": "PR_1", "event": "COMMENT", "body": "Nit", "path": "a.swift", "line": "12", "side": "RIGHT"])
    }

    @Test(arguments: [
        (
            CommentAction.addThread(CommentTarget(path: "a.swift", side: .left, line: 9, startLine: 7), body: "Nit", review: "PRR_2"),
            "addPullRequestReviewThread",
            [
                "pullRequestReviewId": "PRR_2", "body": "Nit", "path": "a.swift", "line": "9", "side": "LEFT",
                "startLine": "7", "startSide": "LEFT",
            ],
            #"{"thread": \#(threadJSON("T_new", comments: [commentJSON("c1", state: "PENDING", review: "PRR_2")]))}"#,
            CommentResult.thread(thread("T_new", comments: [comment("c1", pending: true, review: "PRR_2")]))
        ),
        (
            .startReview(commitOid: "h3ad"), "addPullRequestReview", ["pullRequestId": "PR_1", "commitOID": "h3ad"],
            #"{"pullRequestReview": {"id": "PRR_2"}}"#, .review(id: "PRR_2")
        ),
        (
            .reply(thread: "T1", body: "Done", review: nil), "addPullRequestReviewThreadReply",
            ["pullRequestReviewThreadId": "T1", "body": "Done"],
            #"{"comment": \#(commentJSON("c3", state: "SUBMITTED", review: "PRR_3"))}"#, .comment(comment("c3", pending: false, review: "PRR_3"))
        ),
        (
            .reply(thread: "T1", body: "Done", review: "PRR_2"), "addPullRequestReviewThreadReply",
            ["pullRequestReviewThreadId": "T1", "body": "Done", "pullRequestReviewId": "PRR_2"],
            #"{"comment": \#(commentJSON("c3", state: "PENDING", review: "PRR_2"))}"#, .comment(comment("c3", pending: true, review: "PRR_2"))
        ),
        (
            .edit(comment: "c1", body: "**text**"), "updatePullRequestReviewComment",
            ["pullRequestReviewCommentId": "c1", "body": "**text**"],
            #"{"pullRequestReviewComment": \#(commentJSON("c1", state: "SUBMITTED", review: "PRR_1"))}"#,
            .comment(comment("c1", pending: false, review: "PRR_1"))
        ),
        (.delete(comment: "c1"), "deletePullRequestReviewComment", ["id": "c1"], #"{"clientMutationId": null}"#, .done),
        (
            .submitReview(review: "PRR_2", event: .requestChanges, body: "Fix it"), "submitPullRequestReview",
            ["pullRequestReviewId": "PRR_2", "event": "REQUEST_CHANGES", "body": "Fix it"], #"{"clientMutationId": null}"#, .done
        ),
        (
            .submitReview(review: "PRR_2", event: .comment, body: ""), "submitPullRequestReview",
            ["pullRequestReviewId": "PRR_2", "event": "COMMENT"], #"{"clientMutationId": null}"#, .done
        ),
        (.discardReview(review: "PRR_2"), "deletePullRequestReview", ["pullRequestReviewId": "PRR_2"], #"{"clientMutationId": null}"#, .done),
    ])
    func commentActionSendsOneMutationAndDecodesItsPayload(
        action: CommentAction, field: String, variables: [String: String], payload: String, expected: CommentResult
    ) async throws {
        let session = StubURLProtocol.session(token: token) { _ in #"{"data":{"\#(field)":\#(payload)}}"# }
        let result = try await GitHubClient(token: token, session: session).comment(action, pullRequestID: "PR_1")
        #expect(result == expected)
        let requests = try StubURLProtocol.requests(token: token).map { try JSONDecoder().decode(GraphQLBody.self, from: $0.body) }
        let body = try #require(requests.first)
        #expect(requests.count == 1)
        #expect(body.query.hasPrefix("mutation("))
        #expect(body.query.contains("\(field)(input: {"))
        #expect(body.variables == variables)
        for name in variables.keys { #expect(body.query.contains("\(name): $\(name)")) }
    }

    @Test func startReviewReturnsThePendingReviewThatAlreadyExists() async throws {
        let session = StubURLProtocol.session(token: token) { request in
            let body = try JSONDecoder().decode(GraphQLBody.self, from: request.body)
            if body.query.hasPrefix("mutation(") {
                return #"{"data":{"addPullRequestReview":null},"errors":[{"type":"UNPROCESSABLE","message":"User can only have one pending review per pull request"}]}"#
            }
            return #"{"data":{"node":{"reviews":{"nodes":[{"id":"PRR_web"}]}}}}"#
        }
        let result = try await GitHubClient(token: token, session: session).comment(.startReview(commitOid: "h3ad"), pullRequestID: "PR_1")
        #expect(result == .review(id: "PRR_web"))
        let requests = try StubURLProtocol.requests(token: token).map { try JSONDecoder().decode(GraphQLBody.self, from: $0.body) }
        #expect(requests.count == 2)
        #expect(requests.last?.query.contains("reviews(states: [PENDING], first: 1)") == true)
        #expect(requests.last?.variables == ["id": "PR_1"])
    }

    @Test func refusedCommentThrowsGitHubsMessage() async throws {
        let message = "User can only have one pending review per pull request"
        let session = StubURLProtocol.session(token: token) { request in
            let body = try JSONDecoder().decode(GraphQLBody.self, from: request.body)
            if body.query.hasPrefix("mutation(") {
                return #"{"data":{"addPullRequestReview":null},"errors":[{"type":"UNPROCESSABLE","message":"\#(message)"}]}"#
            }
            return #"{"data":{"node":{"reviews":{"nodes":[]}}}}"#
        }
        let client = GitHubClient(token: token, session: session)
        await #expect(throws: GitHubError.rejected(message)) {
            try await client.comment(.addThread(CommentTarget(path: "a.swift", side: .right, line: 1), body: "x", review: nil), pullRequestID: "PR_1")
        }
        await #expect(throws: GitHubError.rejected(message)) {
            try await client.comment(.startReview(commitOid: "h3ad"), pullRequestID: "PR_1")
        }
    }

    @Test(arguments: [
        (#"<https://api.github.com/x?per_page=100&page=2>; rel="next", <https://api.github.com/x?per_page=100&page=7>; rel="last""#, 7),
        (#"<https://api.github.com/x?page=1>; rel="prev", <https://api.github.com/x?page=1>; rel="first""#, nil),
        ("", nil),
    ])
    func readsLastPageFromLinkHeader(link: String, expected: Int?) {
        #expect(GitHubClient.lastPage(link: link) == expected)
    }
}

private struct GraphQLBody: Decodable {
    let query: String
    let variables: [String: String]

    enum CodingKeys: CodingKey { case query, variables }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        query = try container.decode(String.self, forKey: .query)
        let raw = try container.decode([String: Scalar].self, forKey: .variables)
        variables = raw.compactMapValues(\.string)
    }

    private struct Scalar: Decodable {
        let string: String?

        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            if container.decodeNil() {
                string = nil
            } else if let value = try? container.decode(String.self) {
                string = value
            } else if let value = try? container.decode(Bool.self) {
                string = String(value)
            } else {
                string = String(try container.decode(Int.self))
            }
        }
    }
}

private func thread(_ id: String, comments ids: [String], next: String?) -> String {
    """
    {"id": "\(id)", "path": "a.swift", "line": 3, "startLine": null, "diffSide": "RIGHT",
     "isResolved": false, "isOutdated": false, "comments": \(comments(ids, next: next))}
    """
}

private func comments(_ ids: [String], next: String?) -> String {
    let nodes = ids.map { commentJSON($0, state: "SUBMITTED", review: "PRR_1") }
    let cursor = next.map { "\"\($0)\"" } ?? "null"
    return #"{"pageInfo": {"hasNextPage": \#(next != nil), "endCursor": \#(cursor)}, "nodes": [\#(nodes.joined(separator: ", "))]}"#
}

private func commentJSON(_ id: String, state: String, review: String) -> String {
    """
    {"id": "\(id)", "body": "**text**", "bodyText": "text", "state": "\(state)", "createdAt": "2026-09-01T00:00:00Z",
     "viewerCanUpdate": true, "viewerCanDelete": false, "author": {"login": "octo", "avatarUrl": null},
     "pullRequestReview": {"id": "\(review)"}}
    """
}

private func threadJSON(_ id: String, comments: [String]) -> String {
    """
    {"id": "\(id)", "path": "a.swift", "line": 9, "startLine": 7, "diffSide": "LEFT", "isResolved": false, "isOutdated": false,
     "comments": {"pageInfo": {"hasNextPage": false, "endCursor": null}, "nodes": [\(comments.joined(separator: ", "))]}}
    """
}

private func comment(_ id: String, pending: Bool, review: String) -> ReviewComment {
    ReviewComment(
        id: id, author: Actor(login: "octo", avatarURL: nil), bodyText: "text", body: "**text**",
        createdAt: Date(timeIntervalSince1970: 1_788_220_800), isPending: pending, viewerCanUpdate: true, viewerCanDelete: false,
        reviewID: review
    )
}

private func thread(_ id: String, comments: [ReviewComment]) -> ReviewThread {
    ReviewThread(id: id, path: "a.swift", line: 9, startLine: 7, side: .left, isResolved: false, isOutdated: false, comments: comments)
}
