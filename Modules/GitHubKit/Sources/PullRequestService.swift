import Foundation
import PRModels

public protocol PullRequestService: Sendable {
    func snapshot(of ref: PRRef) async throws -> PullRequestSnapshot
    /// One request for all paths; GitHub applies each path independently.
    func setViewed(_ viewed: Bool, paths: [String], pullRequestID: String) async throws
    /// Returns `nil` when the file does not exist at `oid` or is binary.
    func fileContents(of ref: PRRef, oid: String, path: String) async throws -> String?
}

extension GitHubClient: PullRequestService {
    public func snapshot(of ref: PRRef) async throws -> PullRequestSnapshot {
        async let detail = pullRequestDetail(ref)
        async let viewedStates = viewedStates(ref)
        async let threads = reviewThreads(ref)
        let pullRequest = try await detail
        let files = try await changedFiles(ref, count: pullRequest.changedFiles)
        let viewed = try await viewedStates
        return PullRequestSnapshot(
            pullRequest: pullRequest,
            files: files.map { file in
                var file = file
                file.viewedState = viewed[file.path] ?? .unviewed
                return file
            },
            threads: try await threads
        )
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
        _ = try await graphQL("mutation(\(declarations)) {\n\(selections)\n}", variables: variables, as: IgnoredPayload.self)
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

    private func changedFiles(_ ref: PRRef, count: Int) async throws -> [ChangedFile] {
        let pageSize = 100
        let pages = max(1, (min(count, 3_000) + pageSize - 1) / pageSize)
        return try await withThrowingTaskGroup(of: (Int, [RESTFile]).self) { group in
            for page in 1...pages {
                group.addTask {
                    let data = try await rest(
                        path: "/repos/\(ref.owner)/\(ref.repo)/pulls/\(ref.number)/files",
                        query: [URLQueryItem(name: "per_page", value: "\(pageSize)"), URLQueryItem(name: "page", value: "\(page)")]
                    )
                    return (page, try JSONDecoder().decode([RESTFile].self, from: data))
                }
            }
            var byPage: [Int: [RESTFile]] = [:]
            for try await (page, files) in group { byPage[page] = files }
            return (1...pages).flatMap { byPage[$0] ?? [] }.map(\.model)
        }
    }

    private func viewedStates(_ ref: PRRef) async throws -> [String: ViewedState] {
        var states: [String: ViewedState] = [:]
        var cursor: String?
        repeat {
            var variables = ref.variables
            variables["cursor"] = cursor.map(JSONValue.string) ?? .null
            let response = try await graphQL(Queries.viewedStates, variables: variables, as: RepositoryPayload<FilesNode>.self)
            guard let files = response.repository?.pullRequest?.files else { break }
            for node in files.nodes { states[node.path] = ViewedState(rawValue: node.viewerViewedState) ?? .unviewed }
            cursor = files.pageInfo.hasNextPage ? files.pageInfo.endCursor : nil
        } while cursor != nil
        return states
    }

    private func reviewThreads(_ ref: PRRef) async throws -> [ReviewThread] {
        var threads: [ReviewThread] = []
        var cursor: String?
        repeat {
            var variables = ref.variables
            variables["cursor"] = cursor.map(JSONValue.string) ?? .null
            let response = try await graphQL(Queries.threads, variables: variables, as: RepositoryPayload<ThreadsNode>.self)
            guard let page = response.repository?.pullRequest?.reviewThreads else { break }
            threads += page.nodes.map(\.model)
            cursor = page.pageInfo.hasNextPage ? page.pageInfo.endCursor : nil
        } while cursor != nil
        return threads
    }
}

private enum Queries {
    static let detail = """
    query($owner: String!, $name: String!, $number: Int!) {
      repository(owner: $owner, name: $name) {
        pullRequest(number: $number) {
          id title state isDraft bodyHTML createdAt
          author { login avatarUrl }
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
              comments(first: 100) { nodes { id bodyText createdAt author { login avatarUrl } } }
            }
          }
        }
      }
    }
    """
}

private extension PRRef {
    var variables: [String: JSONValue] {
        ["owner": .string(owner), "name": .string(repo), "number": .int(number)]
    }
}

private struct IgnoredPayload: Decodable {}

private struct RepositoryPayload<Node: Decodable>: Decodable {
    struct Repository: Decodable { let pullRequest: Node? }
    let repository: Repository?
}

private struct AuthorNode: Decodable {
    let login: String
    let avatarUrl: String?
    var actor: Actor { Actor(login: login, avatarURL: avatarUrl.flatMap(URL.init(string:))) }
}

private struct PageInfo: Decodable {
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

    let files: Files
}

private struct ThreadsNode: Decodable {
    struct Threads: Decodable {
        let pageInfo: PageInfo
        let nodes: [Thread]
    }

    struct Thread: Decodable {
        struct Comments: Decodable { let nodes: [Comment] }
        struct Comment: Decodable {
            let id: String
            let bodyText: String
            let createdAt: Date
            let author: AuthorNode?
        }

        let id: String
        let path: String
        let line: Int?
        let startLine: Int?
        let diffSide: String
        let isResolved: Bool
        let isOutdated: Bool
        let comments: Comments

        var model: ReviewThread {
            ReviewThread(
                id: id, path: path, line: line, startLine: startLine,
                side: DiffSide(rawValue: diffSide) ?? .right,
                isResolved: isResolved, isOutdated: isOutdated,
                comments: comments.nodes.map {
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
