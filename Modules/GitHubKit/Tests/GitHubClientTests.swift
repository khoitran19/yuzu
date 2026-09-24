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
        let conversation = try await GitHubClient(token: token, session: session).conversation(ref)

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
    let nodes = ids.map { #"{"id": "\#($0)", "bodyText": "text", "createdAt": "2026-09-01T00:00:00Z", "author": null}"# }
    let cursor = next.map { "\"\($0)\"" } ?? "null"
    return #"{"pageInfo": {"hasNextPage": \#(next != nil), "endCursor": \#(cursor)}, "nodes": [\#(nodes.joined(separator: ", "))]}"#
}
