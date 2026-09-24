import Foundation

public enum LineKind: UInt8, Sendable {
    case context, addition, deletion
}

public struct DiffCell: Sendable, Equatable {
    public let number: Int
    public let kind: LineKind
    public let text: String
    /// Index into `FileDiff.leftLines` or `FileDiff.rightLines`.
    public let lineIndex: Int
    /// UTF-16 ranges that changed against the paired line on the other side.
    public var changedRanges: [NSRange]
}

public struct DiffRow: Sendable, Equatable {
    public var left: DiffCell?
    public var right: DiffCell?
}

public struct DiffHunk: Sendable, Equatable {
    public let oldStart: Int
    public let oldCount: Int
    public let newStart: Int
    public let newCount: Int
    /// Text after the second `@@`, for example the enclosing function signature.
    public let section: String
    public let rows: [DiffRow]

    public var headerText: String {
        let range = "@@ -\(oldStart),\(oldCount) +\(newStart),\(newCount) @@"
        return section.isEmpty ? range : "\(range) \(section)"
    }
}

public struct FileDiff: Sendable, Equatable {
    public let hunks: [DiffHunk]
    /// Old-side lines in diff order; highlighters read these.
    public let leftLines: [String]
    /// New-side lines in diff order; highlighters read these.
    public let rightLines: [String]

    public var rowCount: Int { hunks.reduce(0) { $0 + $1.rows.count } }
}
