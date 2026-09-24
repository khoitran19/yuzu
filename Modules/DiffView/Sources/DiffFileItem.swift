import DiffEngine
import PRModels

public struct DiffFileItem: Sendable {
    public enum Content: Sendable {
        case loading
        case diff(FileDiff)
        case binary
        /// Renamed or copied without changes, or an empty file.
        case unchanged
        /// GitHub omitted the patch; the full diff loads on request.
        case tooLarge
        case failed(String)
    }

    public var file: ChangedFile
    public var content: Content
    public var highlights: SideHighlights?
    /// Threads that GitHub can place on this diff (`line != nil`).
    public var threads: [ReviewThread]
    /// Unchanged lines may follow the last hunk.
    public var tailExpandable: Bool

    public init(
        file: ChangedFile, content: Content, highlights: SideHighlights? = nil, threads: [ReviewThread] = [],
        tailExpandable: Bool? = nil
    ) {
        self.file = file
        self.content = content
        self.highlights = highlights
        self.threads = threads
        self.tailExpandable = tailExpandable ?? (file.status == .modified || file.status == .renamed || file.status == .changed)
    }

    public var isExpandable: Bool {
        file.status != .added && file.status != .removed
    }
}

public struct SideHighlights: Sendable {
    public let left: [[HighlightSpan]]
    public let right: [[HighlightSpan]]

    public init(left: [[HighlightSpan]], right: [[HighlightSpan]]) {
        self.left = left
        self.right = right
    }
}
