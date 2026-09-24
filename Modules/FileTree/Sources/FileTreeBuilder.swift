import Foundation
import PRModels

nonisolated public struct FileTreeEntry: Sendable, Hashable {
    public var path: String
    public var status: ChangedFile.Status
    public var isViewed: Bool

    public init(path: String, status: ChangedFile.Status, isViewed: Bool) {
        self.path = path
        self.status = status
        self.isViewed = isViewed
    }

    public init(_ file: ChangedFile) {
        self.init(path: file.path, status: file.status, isViewed: file.viewedState == .viewed)
    }
}

nonisolated public final class FileTreeNode {
    public enum Kind: Equatable {
        case directory
        case file(ChangedFile.Status)
    }

    /// Display name. A compacted directory chain has a name such as `apps/platform/messaging-gateway`.
    public let name: String
    public let path: String
    public let kind: Kind
    public internal(set) var isViewed: Bool
    public let children: [FileTreeNode]
    public private(set) unowned var parent: FileTreeNode?

    init(name: String, path: String, kind: Kind, isViewed: Bool = false, children: [FileTreeNode] = []) {
        self.name = name
        self.path = path
        self.kind = kind
        self.isViewed = isViewed
        self.children = children
        for child in children { child.parent = self }
    }

    public var isDirectory: Bool { kind == .directory }
}

nonisolated public struct FileTree {
    public let roots: [FileTreeNode]
    /// Depth-first display order. The diff pane shows files in this order.
    public let orderedFilePaths: [String]
    /// Depth-first order, parents before children.
    public let directories: [FileTreeNode]
    public let filesByPath: [String: FileTreeNode]

    public static var empty: FileTree { FileTree(roots: [], orderedFilePaths: [], directories: [], filesByPath: [:]) }
}

nonisolated public enum FileTreeBuilder {
    public static func build(_ entries: [FileTreeEntry]) -> FileTree {
        let root = Trie()
        var directoryCache: [Substring: Trie] = [:]
        for entry in entries {
            let path = entry.path
            guard let slash = path.utf8.lastIndex(of: UInt8(ascii: "/")) else {
                root.files.append((path, entry))
                continue
            }
            let directory = path[..<slash]
            let trie: Trie
            if let cached = directoryCache[directory] {
                trie = cached
            } else {
                trie = directory.split(separator: "/").reduce(root) { parent, component in
                    if let next = parent.directories[component] { return next }
                    let next = Trie()
                    parent.directories[component] = next
                    return next
                }
                directoryCache[directory] = trie
            }
            trie.files.append((String(path[path.utf8.index(after: slash)...]), entry))
        }

        let roots = children(of: root, parentPath: "")
        var ordered: [String] = []
        var directories: [FileTreeNode] = []
        var filesByPath: [String: FileTreeNode] = [:]
        ordered.reserveCapacity(entries.count)
        filesByPath.reserveCapacity(entries.count)
        func visit(_ nodes: [FileTreeNode]) {
            for node in nodes {
                if node.isDirectory {
                    directories.append(node)
                    visit(node.children)
                } else {
                    ordered.append(node.path)
                    filesByPath[node.path] = node
                }
            }
        }
        visit(roots)
        return FileTree(roots: roots, orderedFilePaths: ordered, directories: directories, filesByPath: filesByPath)
    }

    /// Case-insensitive substring match over the full path.
    public static func filter(_ entries: [FileTreeEntry], query: String) -> [FileTreeEntry] {
        let query = query.trimmingCharacters(in: .whitespaces)
        guard !query.isEmpty else { return entries }
        return entries.filter { $0.path.range(of: query, options: [.caseInsensitive, .literal]) != nil }
    }

    /// ASCII case-insensitive, so `_` sorts before letters, as on GitHub. Ties fall back to byte order.
    static func precedes(_ lhs: String, _ rhs: String) -> Bool {
        var left = lhs.utf8.makeIterator()
        var right = rhs.utf8.makeIterator()
        while true {
            switch (left.next(), right.next()) {
            case (nil, nil): return lhs.utf8.lexicographicallyPrecedes(rhs.utf8)
            case (nil, _): return true
            case (_, nil): return false
            case let (a?, b?):
                let foldedA = a &- 65 < 26 ? a | 0x20 : a
                let foldedB = b &- 65 < 26 ? b | 0x20 : b
                if foldedA != foldedB { return foldedA < foldedB }
            }
        }
    }

    private static func children(of trie: Trie, parentPath: String) -> [FileTreeNode] {
        var directories: [FileTreeNode] = []
        directories.reserveCapacity(trie.directories.count)
        for (component, child) in trie.directories {
            var name = String(component)
            var path = parentPath.isEmpty ? name : "\(parentPath)/\(name)"
            var current = child
            while current.files.isEmpty, current.directories.count == 1, let only = current.directories.first {
                name += "/\(only.key)"
                path += "/\(only.key)"
                current = only.value
            }
            let node = FileTreeNode(
                name: name, path: path, kind: .directory,
                children: children(of: current, parentPath: path)
            )
            directories.append(node)
        }
        directories.sort { precedes($0.name, $1.name) }

        let files = trie.files
            .sorted { precedes($0.name, $1.name) }
            .map { FileTreeNode(name: $0.name, path: $0.entry.path, kind: .file($0.entry.status), isViewed: $0.entry.isViewed) }
        return directories + files
    }
}

nonisolated private final class Trie {
    var directories: [Substring: Trie] = [:]
    var files: [(name: String, entry: FileTreeEntry)] = []
}
