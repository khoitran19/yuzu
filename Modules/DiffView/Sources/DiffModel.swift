import AppKit
import DiffEngine
import PRModels

enum Metrics {
    static let lineHeight: CGFloat = 20
    static let headerHeight: CGFloat = 44
    static let hunkHeight: CGFloat = 32
    static let noticeHeight: CGFloat = 64
    static let footerHeight: CGFloat = 16
    /// Taller rows split into slices: a partial redraw of a tall layer copies its whole backing store.
    static let sliceHeight: CGFloat = 240
    static let cardInset: CGFloat = 16
    static let cornerRadius: CGFloat = 6
    static let markerWidth: CGFloat = 22
    static let codeTrailingPadding: CGFloat = 10
    static let codeFont = NSFont.monospacedSystemFont(ofSize: 12, weight: .regular)
    static let headerFont = NSFont.monospacedSystemFont(ofSize: 12, weight: .regular)
    static let uiFont = NSFont.systemFont(ofSize: 12)
    static let uiBoldFont = NSFont.systemFont(ofSize: 12, weight: .semibold)
    static let bodyFont = NSFont.systemFont(ofSize: 13)
    static let charWidth: CGFloat = ("0" as NSString).size(withAttributes: [.font: codeFont]).width
    static let codeBaseline: CGFloat = {
        let font = codeFont
        return ((lineHeight - (font.ascender - font.descender)) / 2 + font.ascender).rounded()
    }()

    static func numberWidth(maxLineNumber: Int) -> CGFloat {
        max(40, CGFloat(String(maxLineNumber).count) * charWidth + 20).rounded()
    }
}

struct RowRef: Hashable {
    enum Kind: Hashable {
        case header
        case hunk(Int)
        case line(hunk: Int, row: Int)
        case thread(Int)
        case notice
        case expandTail
        case footer
    }

    let file: Int
    let kind: Kind
    var slice = 0

    var logical: RowRef { RowRef(file: file, kind: kind) }
}

struct LineKey: Hashable {
    let hunk: Int
    let row: Int
}

/// Horizontal layout of one card at one table width.
struct CardGeometry {
    let minX: CGFloat
    let maxX: CGFloat
    let numberWidth: CGFloat

    init(width: CGFloat, numberWidth: CGFloat) {
        minX = Metrics.cardInset
        maxX = max(Metrics.cardInset * 2 + 200, width - Metrics.cardInset)
        self.numberWidth = numberWidth
    }

    var width: CGFloat { maxX - minX }
    var halfWidth: CGFloat { (width / 2).rounded(.down) }

    func sideMinX(_ side: DiffSide) -> CGFloat { side == .left ? minX : minX + halfWidth }
    func sideMaxX(_ side: DiffSide) -> CGFloat { side == .left ? minX + halfWidth : maxX }
    func codeX(_ side: DiffSide) -> CGFloat { sideMinX(side) + numberWidth + Metrics.markerWidth }
    var codeWidth: CGFloat { max(40, halfWidth - numberWidth - Metrics.markerWidth - Metrics.codeTrailingPadding) }
}

final class FileState {
    var item: DiffFileItem
    var collapsed: Bool
    private(set) var numberWidth: CGFloat = 40
    private(set) var threadsAfter: [LineKey: [Int]] = [:]
    var expandedResolvedThreads: Set<String> = []

    init(item: DiffFileItem, collapsed: Bool) {
        self.item = item
        self.collapsed = collapsed
        index()
    }

    var diff: FileDiff? {
        if case let .diff(diff) = item.content { return diff }
        return nil
    }

    func update(_ item: DiffFileItem) {
        self.item = item
        index()
    }

    private func index() {
        threadsAfter = [:]
        guard let diff else { return }
        var maxNumber = 1
        var leftRows: [Int: LineKey] = [:]
        var rightRows: [Int: LineKey] = [:]
        for (hunkIndex, hunk) in diff.hunks.enumerated() {
            for (rowIndex, row) in hunk.rows.enumerated() {
                let key = LineKey(hunk: hunkIndex, row: rowIndex)
                if let left = row.left {
                    leftRows[left.number] = key
                    maxNumber = max(maxNumber, left.number)
                }
                if let right = row.right {
                    rightRows[right.number] = key
                    maxNumber = max(maxNumber, right.number)
                }
            }
        }
        numberWidth = Metrics.numberWidth(maxLineNumber: maxNumber)
        for (threadIndex, thread) in item.threads.enumerated() {
            guard let line = thread.line else { continue }
            let key = thread.side == .left ? leftRows[line] : rightRows[line]
            if let key { threadsAfter[key, default: []].append(threadIndex) }
        }
    }

    func appendRows(file: Int, to rows: inout [RowRef]) {
        rows.append(RowRef(file: file, kind: .header))
        if !collapsed {
            if let diff {
                for (hunkIndex, hunk) in diff.hunks.enumerated() {
                    rows.append(RowRef(file: file, kind: .hunk(hunkIndex)))
                    for rowIndex in hunk.rows.indices {
                        rows.append(RowRef(file: file, kind: .line(hunk: hunkIndex, row: rowIndex)))
                        for thread in threadsAfter[LineKey(hunk: hunkIndex, row: rowIndex)] ?? [] {
                            rows.append(RowRef(file: file, kind: .thread(thread)))
                        }
                    }
                }
                if diff.hunks.isEmpty {
                    rows.append(RowRef(file: file, kind: .notice))
                } else if item.tailExpandable {
                    rows.append(RowRef(file: file, kind: .expandTail))
                }
            } else {
                rows.append(RowRef(file: file, kind: .notice))
            }
        }
        rows.append(RowRef(file: file, kind: .footer))
    }
}
