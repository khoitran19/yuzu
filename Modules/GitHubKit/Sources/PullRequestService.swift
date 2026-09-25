import Foundation
import PRModels

/// One piece of a pull request, delivered as soon as its requests finish.
public enum PullRequestPart: Sendable {
    /// Files with the viewer's Viewed state, and the pull request node ID that Viewed mutations need.
    case files(pullRequestID: String, files: [ChangedFile])
    case detail(PullRequest)
    case threads([ReviewThread])
    case conversation(Conversation)
}

public protocol PullRequestService: Sendable {
    func snapshot(of ref: PRRef) async throws -> PullRequestSnapshot
    /// Yields each part once, in the order the parts arrive.
    func parts(of ref: PRRef) -> AsyncThrowingStream<PullRequestPart, Error>
    /// One request for all paths. Throws `GitHubError.partialFailure` with only the paths GitHub did not update.
    func setViewed(_ viewed: Bool, paths: [String], pullRequestID: String) async throws
    /// Returns `nil` when the file does not exist at `oid` or is binary.
    func fileContents(of ref: PRRef, oid: String, path: String) async throws -> String?
    /// The commit that the pull request diff compares `head` against.
    func mergeBaseOid(of ref: PRRef, base: String, head: String) async throws -> String
    /// The current checks of the head commit and the merge box state.
    func status(of ref: PRRef) async throws -> PullRequestStatus
    /// The comment and review timeline, the checks, and the merge box state.
    func conversation(of ref: PRRef) async throws -> Conversation
    /// Throws `GitHubError.rejected` with GitHub's message when GitHub refuses the action.
    func perform(_ action: PullRequestAction, pullRequestID: String) async throws
    /// Up to 100 open pull requests of `repo`, most recently updated first.
    func openPullRequests(in repo: RepoRef, scope: PullRequestListScope) async throws -> PullRequestList
    /// Up to 100 open pull requests of `repo` by one author, most recently updated first.
    func openPullRequests(in repo: RepoRef, author: AuthorQuery) async throws -> PullRequestList
}

extension PullRequestService {
    /// Services that serve a fixed snapshot return its checks and merge box state.
    public func status(of ref: PRRef) async throws -> PullRequestStatus {
        let conversation = try await snapshot(of: ref).conversation
        return PullRequestStatus(checks: conversation?.checks ?? [], merge: conversation?.merge)
    }

    public func conversation(of ref: PRRef) async throws -> Conversation {
        try await snapshot(of: ref).conversation ?? Conversation(items: [], checks: [])
    }

    /// Services without progressive loading deliver every part after one snapshot.
    public func parts(of ref: PRRef) -> AsyncThrowingStream<PullRequestPart, Error> {
        AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    let snapshot = try await snapshot(of: ref)
                    continuation.yield(.files(pullRequestID: snapshot.pullRequest.nodeID, files: snapshot.files))
                    continuation.yield(.detail(snapshot.pullRequest))
                    continuation.yield(.threads(snapshot.threads))
                    if let conversation = snapshot.conversation { continuation.yield(.conversation(conversation)) }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }
}

extension GitHubClient: PullRequestService {
    public func snapshot(of ref: PRRef) async throws -> PullRequestSnapshot {
        var files: [ChangedFile]?
        var detail: PullRequest?
        var threads: [ReviewThread]?
        var conversation: Conversation?
        for try await part in parts(of: ref) {
            switch part {
            case let .files(_, value): files = value
            case let .detail(value): detail = value
            case let .threads(value): threads = value
            case let .conversation(value): conversation = value
            }
        }
        guard let files, let detail, let threads, let conversation else { throw GitHubError.malformedResponse }
        return PullRequestSnapshot(pullRequest: detail, files: files, threads: threads, conversation: conversation)
    }

    /// Files, details, threads, and the conversation load in parallel; files do not wait for the details request.
    public func parts(of ref: PRRef) -> AsyncThrowingStream<PullRequestPart, Error> {
        AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    try await withThrowingTaskGroup(of: Void.self) { group in
                        group.addTask {
                            async let files = changedFiles(ref)
                            async let viewed = viewedStates(ref)
                            let (id, states) = try await viewed
                            continuation.yield(.files(pullRequestID: id, files: try await files.map { file in
                                var file = file
                                file.viewedState = states[file.path] ?? .unviewed
                                return file
                            }))
                        }
                        group.addTask { continuation.yield(.detail(try await pullRequestDetail(ref))) }
                        group.addTask { continuation.yield(.threads(try await reviewThreads(ref))) }
                        group.addTask { continuation.yield(.conversation(try await conversation(of: ref))) }
                        try await group.waitForAll()
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    public func setViewed(_ viewed: Bool, paths: [String], pullRequestID: String) async throws {
        guard !paths.isEmpty else { return }
        let field = viewed ? "markFileAsViewed" : "unmarkFileAsViewed"
        let declarations = (["$pr: ID!"] + paths.indices.map { "$p\($0): String!" }).joined(separator: ", ")
        let selections = paths.indices
            .map { "m\($0): \(field)(input: {pullRequestId: $pr, path: $p\($0)}) { clientMutationId }" }
            .joined(separator: "\n")
        var variables: [String: JSONValue] = ["pr": .string(pullRequestID)]
        for (index, path) in paths.enumerated() { variables["p\(index)"] = .string(path) }
        let envelope = try await graphQLEnvelope(
            "mutation(\(declarations)) {\n\(selections)\n}", variables: variables, as: IgnoredPayload.self
        )
        guard !envelope.errors.isEmpty else { return }
        let failed = envelope.errors.map { $0.aliasIndex(below: paths.count) }
        guard failed.allSatisfy({ $0 != nil }) else { throw Self.error(for: envelope.errors) }
        throw GitHubError.partialFailure(paths: Set(failed.compactMap(\.self)).sorted().map { paths[$0] })
    }

    public func mergeBaseOid(of ref: PRRef, base: String, head: String) async throws -> String {
        let data = try await rest(
            path: "/repos/\(ref.owner)/\(ref.repo)/compare/\(base)...\(head)",
            // Pages after the first omit the file list; every page has `merge_base_commit`.
            query: [URLQueryItem(name: "per_page", value: "1"), URLQueryItem(name: "page", value: "2")]
        )
        return try JSONDecoder().decode(ComparePayload.self, from: data).merge_base_commit.sha
    }

    public func fileContents(of ref: PRRef, oid: String, path: String) async throws -> String? {
        do {
            let data = try await rest(
                path: "/repos/\(ref.owner)/\(ref.repo)/contents/\(path)",
                query: [URLQueryItem(name: "ref", value: oid)],
                accept: "application/vnd.github.raw+json"
            )
            return String(data: data, encoding: .utf8)
        } catch GitHubError.notFound {
            return nil
        }
    }

    // MARK: Loading

    private func pullRequestDetail(_ ref: PRRef) async throws -> PullRequest {
        let response = try await graphQL(Queries.detail, variables: ref.variables, as: RepositoryPayload<DetailNode>.self)
        guard let node = response.repository?.pullRequest else { throw GitHubError.notFound }
        return PullRequest(
            nodeID: node.id, ref: ref, title: node.title,
            state: PullRequest.State(rawValue: node.state) ?? .open, isDraft: node.isDraft,
            author: node.author?.actor, bodyHTML: node.bodyHTML,
            baseRefName: node.baseRefName, headRefName: node.headRefName,
            baseOid: node.baseRefOid, headOid: node.headRefOid,
            additions: node.additions, deletions: node.deletions, changedFiles: node.changedFiles,
            commitCount: node.commits.totalCount, createdAt: node.createdAt
        )
    }

    /// Page 1 starts at once; its `Link` header gives the last page, and the other pages load in parallel.
    private func changedFiles(_ ref: PRRef) async throws -> [ChangedFile] {
        let pageSize = 100
        let path = "/repos/\(ref.owner)/\(ref.repo)/pulls/\(ref.number)/files"
        let first = try await restResponse(
            path: path, query: [URLQueryItem(name: "per_page", value: "\(pageSize)"), URLQueryItem(name: "page", value: "1")]
        )
        let firstFiles = try JSONDecoder().decode([RESTFile].self, from: first.data)
        let pages = min(30, Self.lastPage(link: first.response.value(forHTTPHeaderField: "Link")) ?? 1)
        guard pages > 1 else { return firstFiles.map(\.model) }
        return try await withThrowingTaskGroup(of: (Int, [RESTFile]).self) { group in
            for page in 2...pages {
                group.addTask {
                    let data = try await rest(
                        path: "/repos/\(ref.owner)/\(ref.repo)/pulls/\(ref.number)/files",
                        query: [URLQueryItem(name: "per_page", value: "\(pageSize)"), URLQueryItem(name: "page", value: "\(page)")]
                    )
                    return (page, try JSONDecoder().decode([RESTFile].self, from: data))
                }
            }
            var byPage: [Int: [RESTFile]] = [1: firstFiles]
            for try await (page, files) in group { byPage[page] = files }
            return (1...pages).flatMap { byPage[$0] ?? [] }.map(\.model)
        }
    }

    static func lastPage(link: String?) -> Int? {
        guard let link else { return nil }
        for part in link.split(separator: ",") where part.contains("rel=\"last\"") {
            guard let start = part.firstIndex(of: "<"), let end = part.firstIndex(of: ">"),
                  let components = URLComponents(string: String(part[part.index(after: start)..<end])),
                  let page = components.queryItems?.first(where: { $0.name == "page" })?.value
            else { continue }
            return Int(page)
        }
        return nil
    }

    /// Returns the pull request node ID with the states, so Viewed mutations do not wait for the details request.
    private func viewedStates(_ ref: PRRef) async throws -> (id: String, states: [String: ViewedState]) {
        var states: [String: ViewedState] = [:]
        var id: String?
        var cursor: String?
        repeat {
            var variables = ref.variables
            variables["cursor"] = cursor.map(JSONValue.string) ?? .null
            let response = try await graphQL(Queries.viewedStates, variables: variables, as: RepositoryPayload<FilesNode>.self)
            guard let pullRequest = response.repository?.pullRequest else { throw GitHubError.notFound }
            id = pullRequest.id
            for node in pullRequest.files.nodes { states[node.path] = ViewedState(rawValue: node.viewerViewedState) ?? .unviewed }
            cursor = pullRequest.files.pageInfo.hasNextPage ? pullRequest.files.pageInfo.endCursor : nil
        } while cursor != nil
        guard let id else { throw GitHubError.malformedResponse }
        return (id, states)
    }

    func reviewThreads(_ ref: PRRef) async throws -> [ReviewThread] {
        var threads: [ThreadsNode.Thread] = []
        var cursor: String?
        repeat {
            var variables = ref.variables
            variables["cursor"] = cursor.map(JSONValue.string) ?? .null
            let response = try await graphQL(Queries.threads, variables: variables, as: RepositoryPayload<ThreadsNode>.self)
            guard let page = response.repository?.pullRequest?.reviewThreads else { break }
            threads += page.nodes
            cursor = page.pageInfo.hasNextPage ? page.pageInfo.endCursor : nil
        } while cursor != nil

        let remaining = try await withThrowingTaskGroup(of: (Int, [ThreadsNode.Comment]).self) { group in
            for (index, thread) in threads.enumerated() where thread.comments.pageInfo.hasNextPage {
                group.addTask { (index, try await remainingComments(threadID: thread.id, after: thread.comments.pageInfo.endCursor)) }
            }
            var remaining: [Int: [ThreadsNode.Comment]] = [:]
            for try await (index, comments) in group { remaining[index] = comments }
            return remaining
        }
        return threads.enumerated().map { index, thread in thread.model(comments: thread.comments.nodes + (remaining[index] ?? [])) }
    }

    private func remainingComments(threadID: String, after start: String?) async throws -> [ThreadsNode.Comment] {
        var comments: [ThreadsNode.Comment] = []
        var cursor = start
        while let after = cursor {
            let variables: [String: JSONValue] = ["id": .string(threadID), "cursor": .string(after)]
            let response = try await graphQL(Queries.threadComments, variables: variables, as: ThreadCommentsPayload.self)
            guard let page = response.node?.comments else { throw GitHubError.malformedResponse }
            comments += page.nodes
            cursor = page.pageInfo.hasNextPage ? page.pageInfo.endCursor : nil
        }
        return comments
    }
}

private enum Queries {
    static let detail = """
    query($owner: String!, $name: String!, $number: Int!) {
      repository(owner: $owner, name: $name) {
        pullRequest(number: $number) {
          id title state isDraft bodyHTML createdAt
          author { login avatarUrl(size: 80) }
          baseRefName headRefName baseRefOid headRefOid
          additions deletions changedFiles
          commits { totalCount }
        }
      }
    }
    """

    static let viewedStates = """
    query($owner: String!, $name: String!, $number: Int!, $cursor: String) {
      repository(owner: $owner, name: $name) {
        pullRequest(number: $number) {
          id
          files(first: 100, after: $cursor) {
            pageInfo { hasNextPage endCursor }
            nodes { path viewerViewedState }
          }
        }
      }
    }
    """

    static let threads = """
    query($owner: String!, $name: String!, $number: Int!, $cursor: String) {
      repository(owner: $owner, name: $name) {
        pullRequest(number: $number) {
          reviewThreads(first: 100, after: $cursor) {
            pageInfo { hasNextPage endCursor }
            nodes {
              id path line startLine diffSide isResolved isOutdated
              comments(first: 100) {
                pageInfo { hasNextPage endCursor }
                nodes { id bodyText createdAt author { login avatarUrl } }
              }
            }
          }
        }
      }
    }
    """

    static let threadComments = """
    query($id: ID!, $cursor: String!) {
      node(id: $id) {
        ... on PullRequestReviewThread {
          comments(first: 100, after: $cursor) {
            pageInfo { hasNextPage endCursor }
            nodes { id bodyText createdAt author { login avatarUrl } }
          }
        }
      }
    }
    """
}

extension PRRef {
    var variables: [String: JSONValue] {
        ["owner": .string(owner), "name": .string(repo), "number": .int(number)]
    }
}

private struct IgnoredPayload: Decodable {}

private struct ComparePayload: Decodable {
    struct Commit: Decodable { let sha: String }
    let merge_base_commit: Commit
}

private struct ThreadCommentsPayload: Decodable {
    struct Node: Decodable { let comments: ThreadsNode.Comments? }
    let node: Node?
}

private extension GraphQLError {
    func aliasIndex(below count: Int) -> Int? {
        guard case let .key(alias) = path?.first, alias.hasPrefix("m"),
              let index = Int(alias.dropFirst()), (0..<count).contains(index)
        else { return nil }
        return index
    }
}

struct RepositoryPayload<Node: Decodable>: Decodable {
    struct Repository: Decodable { let pullRequest: Node? }
    let repository: Repository?
}

struct AuthorNode: Decodable {
    let login: String
    let avatarUrl: String?
    var actor: Actor { Actor(login: login, avatarURL: avatarUrl.flatMap(URL.init(string:))) }
}

struct PageInfo: Decodable {
    let hasNextPage: Bool
    let endCursor: String?
}

private struct DetailNode: Decodable {
    struct Count: Decodable { let totalCount: Int }
    let id: String
    let title: String
    let state: String
    let isDraft: Bool
    let bodyHTML: String
    let createdAt: Date
    let author: AuthorNode?
    let baseRefName: String
    let headRefName: String
    let baseRefOid: String
    let headRefOid: String
    let additions: Int
    let deletions: Int
    let changedFiles: Int
    let commits: Count
}

private struct FilesNode: Decodable {
    struct Files: Decodable {
        struct File: Decodable {
            let path: String
            let viewerViewedState: String
        }

        let pageInfo: PageInfo
        let nodes: [File]
    }

    let id: String
    let files: Files
}

private struct ThreadsNode: Decodable {
    struct Threads: Decodable {
        let pageInfo: PageInfo
        let nodes: [Thread]
    }

    struct Comments: Decodable {
        let pageInfo: PageInfo
        let nodes: [Comment]
    }

    struct Comment: Decodable {
        let id: String
        let bodyText: String
        let createdAt: Date
        let author: AuthorNode?
    }

    struct Thread: Decodable {
        let id: String
        let path: String
        let line: Int?
        let startLine: Int?
        let diffSide: String
        let isResolved: Bool
        let isOutdated: Bool
        let comments: Comments

        func model(comments: [Comment]) -> ReviewThread {
            ReviewThread(
                id: id, path: path, line: line, startLine: startLine,
                side: DiffSide(rawValue: diffSide) ?? .right,
                isResolved: isResolved, isOutdated: isOutdated,
                comments: comments.map {
                    ReviewComment(id: $0.id, author: $0.author?.actor, bodyText: $0.bodyText, createdAt: $0.createdAt)
                }
            )
        }
    }

    let reviewThreads: Threads
}

private struct RESTFile: Decodable {
    let filename: String
    let previous_filename: String?
    let status: String
    let additions: Int
    let deletions: Int
    let patch: String?

    var model: ChangedFile {
        ChangedFile(
            path: filename, previousPath: previous_filename,
            status: ChangedFile.Status(rawValue: status) ?? .modified,
            additions: additions, deletions: deletions, patch: patch, viewedState: .unviewed
        )
    }
}
