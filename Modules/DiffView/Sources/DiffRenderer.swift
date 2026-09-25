import AppKit
import CoreText
import DiffEngine
import PRModels

enum HitTarget: Equatable {
    case toggleCollapse
    case toggleViewed
    case copyPath
    case preview
    case loadFullDiff
    case toggleThread(Int)
    case expandHunk(Int)
    case expandTail
    /// The hover "+" of a code line.
    case addComment(DiffSide)
    case reply(thread: Int)
    case commentMenu(thread: Int, comment: Int)
}

/// Measures and draws every row kind. Row views hold no state beyond their `RowRef`.
struct LineSelection: Equatable {
    let side: DiffSide
    let refs: Set<RowRef>
}

final class DiffRenderer {
    var files: [FileState] = []
    var selection: LineSelection?
    /// The code line and side under the mouse; its "+" button shows.
    var hover: (ref: RowRef, side: DiffSide)?
    /// The file that the Markdown preview shows; its header button draws as active.
    var previewPath: String?
    let cache = TextLayoutCache()
    private var symbols: [String: NSImage] = [:]

    var theme: DiffTheme { cache.theme }

    // MARK: Heights

    func height(of ref: RowRef, width: CGFloat) -> CGFloat {
        let state = files[ref.file]
        let geometry = CardGeometry(width: width, numberWidth: state.numberWidth)
        switch ref.kind {
        case .header: return Metrics.headerHeight
        case .hunk, .expandTail: return Metrics.hunkHeight
        case .notice: return Metrics.noticeHeight
        case .footer: return state.collapsed ? Metrics.footerHeight : Metrics.footerHeight + Metrics.cornerRadius
        case let .line(hunk, row):
            guard let line = state.diff?.hunks[hunk].rows[row] else { return Metrics.lineHeight }
            let left = line.left.map { cache.lineCount($0, side: .left, file: ref.file, width: geometry.codeWidth) } ?? 1
            let right = line.right.map { cache.lineCount($0, side: .right, file: ref.file, width: geometry.codeWidth) } ?? 1
            return CGFloat(max(left, right)) * Metrics.lineHeight
        case let .thread(index):
            return threadLayout(state: state, file: ref.file, index: index, geometry: geometry).rowHeight
        case let .composer(index):
            return state.composers[safe: index]?.height ?? 0
        }
    }

    private func threadLayout(state: FileState, file: Int, index: Int, geometry: CardGeometry) -> ThreadLayout {
        let thread = state.item.threads[index]
        let collapsed = thread.isResolved && !state.expandedResolvedThreads.contains(thread.id)
        let boxWidth = geometry.halfWidth - ThreadLayout.outerPadding * 2
        return cache.threadLayout(thread, file: file, index: index, width: boxWidth, collapsed: collapsed)
    }

    // MARK: Drawing

    /// The full logical row in the row view's coordinates; a slice shows one part of it.
    func contentBounds(_ ref: RowRef, rowBounds: CGRect) -> CGRect {
        guard ref.slice > 0 || rowBounds.height >= Metrics.sliceHeight else { return rowBounds }
        let fullHeight = height(of: ref.logical, width: rowBounds.width)
        return CGRect(x: rowBounds.minX, y: rowBounds.minY - CGFloat(ref.slice) * Metrics.sliceHeight, width: rowBounds.width, height: fullHeight)
    }

    func draw(_ ref: RowRef, in rowBounds: CGRect, dirty: CGRect, context: CGContext, floating: Bool) {
        let state = files[ref.file]
        let dirty = dirty.intersection(rowBounds)
        context.clip(to: dirty)
        let bounds = contentBounds(ref, rowBounds: rowBounds)
        let geometry = CardGeometry(width: bounds.width, numberWidth: state.numberWidth)
        context.setFillColor(theme.background)
        if case .line = ref.kind {
            context.fill(CGRect(x: bounds.minX, y: bounds.minY, width: geometry.minX - bounds.minX, height: bounds.height))
            context.fill(CGRect(x: geometry.maxX, y: bounds.minY, width: bounds.maxX - geometry.maxX, height: bounds.height))
        } else {
            context.fill(bounds)
        }
        switch ref.kind {
        case .header: drawHeader(state, bounds: bounds, geometry: geometry, context: context, floating: floating)
        case let .hunk(index):
            drawHunk(state.diff?.hunks[index], expandable: isExpandable(state, hunk: index), bounds: bounds, geometry: geometry, context: context)
        case .expandTail:
            drawHunk(nil, expandable: true, bounds: bounds, geometry: geometry, context: context)
        case let .line(hunk, row):
            if let line = state.diff?.hunks[hunk].rows[row] {
                let selectedSide = selection.flatMap { $0.refs.contains(ref.logical) ? $0.side : nil }
                let hoveredSide = hover.flatMap { $0.ref == ref.logical ? $0.side : nil }
                drawLine(
                    line, file: ref.file, state: state, selectedSide: selectedSide, hoveredSide: hoveredSide,
                    bounds: bounds, dirty: dirty, geometry: geometry, context: context
                )
            }
        case let .thread(index):
            drawThread(state: state, file: ref.file, index: index, bounds: bounds, dirty: dirty, geometry: geometry, context: context)
        case let .composer(index):
            if let composer = state.composers[safe: index] {
                drawComposer(composer, ref: ref, bounds: bounds, geometry: geometry, context: context)
            }
        case .notice: drawNotice(state, bounds: bounds, geometry: geometry, context: context)
        case .footer:
            if !state.collapsed { drawCardBottom(bounds: bounds, geometry: geometry, context: context) }
            return
        }
        if ref.kind != .header { drawCardSides(bounds: bounds, geometry: geometry, context: context) }
    }

    private func drawCardSides(bounds: CGRect, geometry: CardGeometry, context: CGContext) {
        context.setFillColor(theme.border)
        context.fill(CGRect(x: geometry.minX, y: bounds.minY, width: 1, height: bounds.height))
        context.fill(CGRect(x: geometry.maxX - 1, y: bounds.minY, width: 1, height: bounds.height))
    }

    private func drawCardBottom(bounds: CGRect, geometry: CardGeometry, context: CGContext) {
        let radius = Metrics.cornerRadius
        let rect = CGRect(x: geometry.minX + 0.5, y: bounds.minY - radius, width: geometry.width - 1, height: radius * 2 - 0.5)
        context.saveGState()
        context.clip(to: CGRect(x: bounds.minX, y: bounds.minY, width: bounds.width, height: radius))
        context.addPath(CGPath(roundedRect: rect, cornerWidth: radius, cornerHeight: radius, transform: nil))
        context.setStrokeColor(theme.border)
        context.setLineWidth(1)
        context.strokePath()
        context.restoreGState()
    }

    // MARK: Header

    struct HeaderLayout {
        let chevron: CGRect
        let pathOrigin: CGPoint
        let copy: CGRect
        /// `nil` for files that are not Markdown.
        let preview: CGRect?
        let viewed: CGRect
        let statsMaxX: CGFloat
    }

    func headerLayout(_ state: FileState, bounds: CGRect, geometry: CardGeometry) -> HeaderLayout {
        let midY = bounds.minY + Metrics.headerHeight / 2
        let chevron = CGRect(x: geometry.minX + 10, y: midY - 8, width: 16, height: 16)
        let pathWidth = (pathText(state) as NSString).size(withAttributes: [.font: Metrics.headerFont]).width
        let viewed = CGRect(x: geometry.maxX - 12 - 76, y: midY - 12, width: 76, height: 24)
        let preview = state.item.file.isMarkdown ? CGRect(x: viewed.minX - 8 - 28, y: midY - 12, width: 28, height: 24) : nil
        let statsMaxX = (preview ?? viewed).minX - 14
        let pathX = chevron.maxX + 8
        let copyX = min(pathX + pathWidth + 8, statsMaxX - 166)
        return HeaderLayout(
            chevron: chevron,
            pathOrigin: CGPoint(x: pathX, y: midY - 8),
            copy: CGRect(x: copyX, y: midY - 9, width: 18, height: 18),
            preview: preview,
            viewed: viewed,
            statsMaxX: statsMaxX
        )
    }

    private func pathText(_ state: FileState) -> String {
        let file = state.item.file
        if let previous = file.previousPath, previous != file.path { return "\(previous) → \(file.path)" }
        return file.path
    }

    private func drawHeader(_ state: FileState, bounds: CGRect, geometry: CardGeometry, context: CGContext, floating: Bool) {
        let radius = Metrics.cornerRadius
        let card = CGRect(x: geometry.minX + 0.5, y: bounds.minY + 0.5, width: geometry.width - 1, height: bounds.height - 1)
        let path = CGMutablePath()
        if state.collapsed {
            path.addRoundedRect(in: card, cornerWidth: radius, cornerHeight: radius)
        } else {
            path.move(to: CGPoint(x: card.minX, y: card.maxY + 0.5))
            path.addLine(to: CGPoint(x: card.minX, y: card.minY + radius))
            path.addArc(tangent1End: CGPoint(x: card.minX, y: card.minY), tangent2End: CGPoint(x: card.minX + radius, y: card.minY), radius: radius)
            path.addLine(to: CGPoint(x: card.maxX - radius, y: card.minY))
            path.addArc(tangent1End: CGPoint(x: card.maxX, y: card.minY), tangent2End: CGPoint(x: card.maxX, y: card.minY + radius), radius: radius)
            path.addLine(to: CGPoint(x: card.maxX, y: card.maxY + 0.5))
        }
        context.addPath(path)
        context.setFillColor(theme.cardHeader)
        context.fillPath()
        context.addPath(path)
        context.setStrokeColor(theme.border)
        context.setLineWidth(1)
        context.strokePath()
        if !state.collapsed {
            context.setFillColor(theme.border)
            context.fill(CGRect(x: geometry.minX, y: bounds.maxY - 1, width: geometry.width, height: 1))
        }

        let layout = headerLayout(state, bounds: bounds, geometry: geometry)
        drawSymbol(state.collapsed ? "chevron.right" : "chevron.down", in: layout.chevron, color: theme.mutedText, pointSize: 11)
        let copyLimit = layout.copy.minX - 6
        let pathAttributes: [NSAttributedString.Key: Any] = [.font: Metrics.headerFont, .foregroundColor: NSColor(cgColor: theme.text)!]
        NSAttributedString(string: pathText(state), attributes: pathAttributes).draw(
            with: CGRect(x: layout.pathOrigin.x, y: layout.pathOrigin.y, width: max(0, copyLimit - layout.pathOrigin.x), height: 16),
            options: [.usesLineFragmentOrigin, .truncatesLastVisibleLine]
        )
        drawSymbol("doc.on.doc", in: layout.copy, color: theme.mutedText, pointSize: 11)
        drawStats(state.item.file, maxX: layout.statsMaxX, midY: bounds.minY + Metrics.headerHeight / 2, context: context)
        if let preview = layout.preview {
            drawPreviewButton(active: previewPath == state.item.file.path, in: preview, context: context)
        }
        drawViewedToggle(viewed: state.item.file.viewedState == .viewed, in: layout.viewed, context: context)
    }

    private func drawPreviewButton(active: Bool, in rect: CGRect, context: CGContext) {
        let path = CGPath(roundedRect: rect.insetBy(dx: 0.5, dy: 0.5), cornerWidth: 6, cornerHeight: 6, transform: nil)
        context.addPath(path)
        context.setFillColor(active ? theme.accent.copy(alpha: 0.15)! : theme.background)
        context.fillPath()
        context.addPath(path)
        context.setStrokeColor(active ? theme.accent : theme.border)
        context.strokePath()
        drawSymbol("doc.richtext", in: rect, color: active ? theme.accent : theme.mutedText, pointSize: 12)
    }

    private func drawStats(_ file: ChangedFile, maxX: CGFloat, midY: CGFloat, context: CGContext) {
        let blockSize: CGFloat = 8
        let blocksWidth = blockSize * 5 + 4
        let blocksX = maxX - blocksWidth
        let total = file.additions + file.deletions
        let greens = total == 0 ? 0 : Int((Double(file.additions) / Double(total) * 5).rounded())
        let reds = total == 0 ? 0 : min(5 - greens, Int((Double(file.deletions) / Double(total) * 5).rounded()))
        for index in 0..<5 {
            let color = index < greens ? theme.additionStat : index < greens + reds ? theme.deletionStat : theme.neutralStat
            context.setFillColor(color)
            context.fill(CGRect(x: blocksX + CGFloat(index) * (blockSize + 1), y: midY - blockSize / 2, width: blockSize, height: blockSize))
        }
        let text = NSMutableAttributedString()
        if file.additions > 0 || file.deletions == 0 {
            text.append(NSAttributedString(string: "+\(file.additions)", attributes: [.font: Metrics.uiBoldFont, .foregroundColor: NSColor(cgColor: theme.additionStat)!]))
        }
        if file.deletions > 0 {
            text.append(NSAttributedString(string: " -\(file.deletions)", attributes: [.font: Metrics.uiBoldFont, .foregroundColor: NSColor(cgColor: theme.deletionStat)!]))
        }
        let size = text.size()
        text.draw(at: CGPoint(x: blocksX - 8 - size.width, y: midY - size.height / 2))
    }

    private func drawViewedToggle(viewed: Bool, in rect: CGRect, context: CGContext) {
        let path = CGPath(roundedRect: rect.insetBy(dx: 0.5, dy: 0.5), cornerWidth: 6, cornerHeight: 6, transform: nil)
        context.addPath(path)
        context.setFillColor(viewed ? theme.accent.copy(alpha: 0.15)! : theme.background)
        context.fillPath()
        context.addPath(path)
        context.setStrokeColor(viewed ? theme.accent : theme.border)
        context.strokePath()
        let box = CGRect(x: rect.minX + 9, y: rect.midY - 7, width: 14, height: 14)
        let boxPath = CGPath(roundedRect: box.insetBy(dx: 0.5, dy: 0.5), cornerWidth: 3, cornerHeight: 3, transform: nil)
        context.addPath(boxPath)
        context.setFillColor(viewed ? theme.accent : theme.background)
        context.fillPath()
        if viewed {
            drawSymbol("checkmark", in: box.insetBy(dx: 2, dy: 2), color: CGColor.white, pointSize: 9)
        } else {
            context.addPath(boxPath)
            context.setStrokeColor(theme.mutedText)
            context.strokePath()
        }
        let label = NSAttributedString(string: "Viewed", attributes: [.font: Metrics.uiFont, .foregroundColor: NSColor(cgColor: theme.text)!])
        label.draw(at: CGPoint(x: box.maxX + 6, y: rect.midY - label.size().height / 2))
    }

    // MARK: Hunk

    func isExpandable(_ state: FileState, hunk index: Int) -> Bool {
        guard state.item.isExpandable, let hunk = state.diff?.hunks[safe: index] else { return false }
        return index > 0 || hunk.newStart > 1
    }

    private func drawHunk(_ hunk: DiffHunk?, expandable: Bool, bounds: CGRect, geometry: CardGeometry, context: CGContext) {
        context.setFillColor(theme.hunkLine)
        context.fill(CGRect(x: geometry.minX, y: bounds.minY, width: geometry.width, height: bounds.height))
        context.setFillColor(theme.hunkGutter)
        context.fill(CGRect(x: geometry.minX, y: bounds.minY, width: geometry.numberWidth, height: bounds.height))
        if expandable {
            drawSymbol(
                hunk == nil ? "arrow.down.to.line" : "arrow.up.and.down",
                in: CGRect(x: geometry.minX + (geometry.numberWidth - 16) / 2, y: bounds.midY - 8, width: 16, height: 16),
                color: theme.accent, pointSize: 11
            )
        }
        guard let hunk else { return }
        let line = CTLineCreateWithAttributedString(NSAttributedString(
            string: hunk.headerText,
            attributes: [.font: Metrics.codeFont, NSAttributedString.Key(kCTForegroundColorAttributeName as String): theme.mutedText]
        ))
        drawLine(line, x: geometry.minX + geometry.numberWidth + 10, top: bounds.minY + (bounds.height - Metrics.lineHeight) / 2, context: context)
    }

    // MARK: Code lines

    func side(at x: CGFloat, width: CGFloat, file: Int) -> DiffSide {
        let geometry = CardGeometry(width: width, numberWidth: files[file].numberWidth)
        return x < geometry.sideMinX(.right) ? .left : .right
    }

    private func drawLine(
        _ row: DiffRow, file: Int, state: FileState, selectedSide: DiffSide?, hoveredSide: DiffSide?,
        bounds: CGRect, dirty: CGRect, geometry: CardGeometry, context: CGContext
    ) {
        for side in [DiffSide.left, .right] {
            let cell = side == .left ? row.left : row.right
            let minX = geometry.sideMinX(side)
            let sideWidth = geometry.sideMaxX(side) - minX
            guard let cell else {
                context.setFillColor(theme.emptyCell)
                context.fill(CGRect(x: minX, y: bounds.minY, width: sideWidth, height: bounds.height))
                continue
            }
            let (lineColor, numberColor, wordColor, marker): (CGColor?, CGColor?, CGColor?, String?) = switch cell.kind {
            case .context: (theme.background, nil, nil, nil)
            case .addition: (theme.additionLine, theme.additionNumber, theme.additionWord, "+")
            case .deletion: (theme.deletionLine, theme.deletionNumber, theme.deletionWord, "-")
            }
            if let numberColor {
                context.setFillColor(numberColor)
                context.fill(CGRect(x: minX, y: bounds.minY, width: geometry.numberWidth, height: bounds.height))
            }
            if let lineColor {
                let codeMinX = numberColor == nil ? minX : minX + geometry.numberWidth
                context.setFillColor(lineColor)
                context.fill(CGRect(x: codeMinX, y: bounds.minY, width: sideWidth - (codeMinX - minX), height: bounds.height))
            }
            if selectedSide == side {
                context.setFillColor(theme.accent.copy(alpha: 0.22)!)
                context.fill(CGRect(x: minX, y: bounds.minY, width: sideWidth, height: bounds.height))
            }
            let numberLine = CTLineCreateWithAttributedString(NSAttributedString(
                string: String(cell.number),
                attributes: [
                    .font: Metrics.codeFont,
                    NSAttributedString.Key(kCTForegroundColorAttributeName as String): cell.kind == .context ? theme.mutedText : theme.text,
                ]
            ))
            let numberWidth = CTLineGetTypographicBounds(numberLine, nil, nil, nil)
            drawLine(numberLine, x: minX + geometry.numberWidth - 10 - numberWidth, top: bounds.minY, context: context)
            if let marker {
                let markerLine = CTLineCreateWithAttributedString(NSAttributedString(
                    string: marker,
                    attributes: [.font: Metrics.codeFont, NSAttributedString.Key(kCTForegroundColorAttributeName as String): theme.text]
                ))
                drawLine(markerLine, x: minX + geometry.numberWidth + 8, top: bounds.minY, context: context)
            }

            let spans = side == .left ? state.item.highlights?.left[safe: cell.lineIndex] : state.item.highlights?.right[safe: cell.lineIndex]
            let layout = cache.layout(cell, side: side, file: file, spans: spans, width: geometry.codeWidth)
            let codeX = geometry.codeX(side)
            defer {
                if hoveredSide == side { drawAddCommentButton(plusRect(side, bounds: bounds, geometry: geometry), context: context) }
            }
            if let wordColor, !cell.changedRanges.isEmpty {
                context.setFillColor(wordColor)
                for (index, line) in layout.lines.enumerated() {
                    let lineRange = layout.ranges[index]
                    for changed in cell.changedRanges {
                        let start = max(changed.location, lineRange.location)
                        let end = min(NSMaxRange(changed), NSMaxRange(lineRange))
                        guard start < end else { continue }
                        let x1 = CTLineGetOffsetForStringIndex(line, start - lineRange.location, nil)
                        let x2 = CTLineGetOffsetForStringIndex(line, end - lineRange.location, nil)
                        context.fill(CGRect(x: codeX + x1, y: bounds.minY + CGFloat(index) * Metrics.lineHeight + 1, width: x2 - x1, height: Metrics.lineHeight - 2))
                    }
                }
            }
            for (index, line) in layout.lines.enumerated() {
                let top = bounds.minY + CGFloat(index) * Metrics.lineHeight
                guard top < dirty.maxY, top + Metrics.lineHeight > dirty.minY else { continue }
                drawLine(line, x: codeX, top: top, context: context)
            }
        }
        context.setFillColor(theme.border)
        context.fill(CGRect(x: geometry.sideMinX(.right), y: bounds.minY, width: 1, height: bounds.height))
    }

    /// The "+" sits on the edge between the line number and the code, like on GitHub.
    func plusRect(_ side: DiffSide, bounds: CGRect, geometry: CardGeometry) -> CGRect {
        CGRect(x: geometry.sideMinX(side) + geometry.numberWidth - 4, y: bounds.minY + 1, width: 20, height: Metrics.lineHeight - 2)
    }

    private func drawAddCommentButton(_ rect: CGRect, context: CGContext) {
        context.addPath(CGPath(roundedRect: rect, cornerWidth: 4, cornerHeight: 4, transform: nil))
        context.setFillColor(theme.accent)
        context.fillPath()
        drawSymbol("plus", in: rect, color: CGColor.white, pointSize: 10)
    }

    private func drawLine(_ line: CTLine, x: CGFloat, top: CGFloat, context: CGContext) {
        context.saveGState()
        context.textMatrix = CGAffineTransform(scaleX: 1, y: -1)
        context.textPosition = CGPoint(x: x, y: top + Metrics.codeBaseline)
        CTLineDraw(line, context)
        context.restoreGState()
    }

    // MARK: Threads

    func threadBox(state: FileState, file: Int, index: Int, bounds: CGRect, geometry: CardGeometry) -> CGRect {
        let side = state.item.threads[index].side
        let layout = threadLayout(state: state, file: file, index: index, geometry: geometry)
        return CGRect(
            x: geometry.sideMinX(side) + ThreadLayout.outerPadding,
            y: bounds.minY + ThreadLayout.outerPadding,
            width: geometry.halfWidth - ThreadLayout.outerPadding * 2,
            height: layout.boxHeight
        )
    }

    private func drawThread(state: FileState, file: Int, index: Int, bounds: CGRect, dirty: CGRect, geometry: CardGeometry, context: CGContext) {
        let thread = state.item.threads[index]
        let layout = threadLayout(state: state, file: file, index: index, geometry: geometry)
        context.setFillColor(theme.border)
        context.fill(CGRect(x: geometry.sideMinX(.right), y: bounds.minY, width: 1, height: bounds.height))
        let box = CGRect(
            x: geometry.sideMinX(thread.side) + ThreadLayout.outerPadding,
            y: bounds.minY + ThreadLayout.outerPadding,
            width: geometry.halfWidth - ThreadLayout.outerPadding * 2,
            height: layout.boxHeight
        )
        let path = CGPath(roundedRect: box.insetBy(dx: 0.5, dy: 0.5), cornerWidth: 6, cornerHeight: 6, transform: nil)
        context.addPath(path)
        context.setFillColor(theme.cardHeader)
        context.fillPath()
        context.addPath(path)
        context.setStrokeColor(theme.border)
        context.setLineWidth(1)
        context.strokePath()

        if layout.collapsed {
            drawSymbol("checkmark.circle", in: CGRect(x: box.minX + 12, y: box.midY - 8, width: 16, height: 16), color: theme.mutedText, pointSize: 12)
            drawLine(layout.summary, x: box.minX + 34, top: box.midY - Metrics.lineHeight / 2, context: context)
            return
        }
        var y = box.minY
        for (commentIndex, comment) in layout.comments.enumerated() {
            if commentIndex > 0 {
                context.setFillColor(theme.border)
                context.fill(CGRect(x: box.minX + 1, y: y, width: box.width - 2, height: 1))
            }
            y += ThreadLayout.innerPadding
            if y < dirty.maxY, y + ThreadLayout.headerHeight > dirty.minY {
                drawLine(comment.header, x: box.minX + ThreadLayout.innerPadding, top: y, context: context)
            }
            y += ThreadLayout.headerHeight + 4
            if y < dirty.maxY, y + comment.bodyHeight > dirty.minY {
                drawFrame(comment.body, x: box.minX + ThreadLayout.innerPadding, top: y, height: comment.bodyHeight + 1, dirty: dirty, context: context)
            }
            y += comment.bodyHeight + ThreadLayout.innerPadding
            if comment.hasMenu {
                drawSymbol("ellipsis", in: layout.menuRect(comment: commentIndex, box: box), color: theme.mutedText, pointSize: 12)
            }
        }
        let reply = layout.replyRect(box: box)
        context.setFillColor(theme.border)
        context.fill(CGRect(x: box.minX + 1, y: box.maxY - ThreadLayout.replyHeight, width: box.width - 2, height: 1))
        guard reply.minY < dirty.maxY, reply.maxY > dirty.minY else { return }
        let field = CGPath(roundedRect: reply.insetBy(dx: 0.5, dy: 0.5), cornerWidth: 6, cornerHeight: 6, transform: nil)
        context.addPath(field)
        context.setFillColor(theme.background)
        context.fillPath()
        context.addPath(field)
        context.setStrokeColor(theme.border)
        context.strokePath()
        drawLine(cache.replyPlaceholder, x: reply.minX + 10, top: reply.midY - Metrics.lineHeight / 2, context: context)
    }

    // MARK: Comment boxes

    func composerBox(_ ref: RowRef, composer: Composer, bounds rowBounds: CGRect) -> CGRect {
        let state = files[ref.file]
        let geometry = CardGeometry(width: rowBounds.width, numberWidth: state.numberWidth)
        return CGRect(
            x: geometry.sideMinX(composer.side) + Composer.outerPadding,
            y: rowBounds.minY + Composer.outerPadding,
            width: geometry.halfWidth - Composer.outerPadding * 2,
            height: composer.height - Composer.outerPadding * 2
        )
    }

    private func drawComposer(_ composer: Composer, ref: RowRef, bounds: CGRect, geometry: CardGeometry, context: CGContext) {
        context.setFillColor(theme.border)
        context.fill(CGRect(x: geometry.sideMinX(.right), y: bounds.minY, width: 1, height: bounds.height))
        let box = composerBox(ref, composer: composer, bounds: bounds)
        let path = CGPath(roundedRect: box.insetBy(dx: 0.5, dy: 0.5), cornerWidth: 6, cornerHeight: 6, transform: nil)
        context.addPath(path)
        context.setFillColor(theme.cardHeader)
        context.fillPath()
        let field = CGRect(
            x: box.minX + Composer.innerPadding, y: box.minY + Composer.innerPadding,
            width: box.width - Composer.innerPadding * 2, height: composer.textHeight
        )
        let fieldPath = CGPath(roundedRect: field.insetBy(dx: -0.5, dy: -0.5), cornerWidth: 6, cornerHeight: 6, transform: nil)
        context.addPath(fieldPath)
        context.setFillColor(theme.background)
        context.fillPath()
        context.addPath(fieldPath)
        context.setStrokeColor(theme.accent)
        context.setLineWidth(1)
        context.strokePath()
        context.addPath(path)
        context.setStrokeColor(theme.border)
        context.strokePath()
    }

    /// Draws only the frame's lines that intersect `dirty`.
    private func drawFrame(_ frame: CTFrame, x: CGFloat, top: CGFloat, height: CGFloat, dirty: CGRect, context: CGContext) {
        let lines = CTFrameGetLines(frame) as? [CTLine] ?? []
        var origins = [CGPoint](repeating: .zero, count: lines.count)
        CTFrameGetLineOrigins(frame, CFRange(), &origins)
        context.saveGState()
        context.textMatrix = .identity
        context.translateBy(x: x, y: top + height)
        context.scaleBy(x: 1, y: -1)
        for (line, origin) in zip(lines, origins) {
            var ascent: CGFloat = 0
            var descent: CGFloat = 0
            CTLineGetTypographicBounds(line, &ascent, &descent, nil)
            let lineTop = top + height - origin.y - ascent
            guard lineTop < dirty.maxY, lineTop + ascent + descent > dirty.minY else { continue }
            context.textPosition = origin
            CTLineDraw(line, context)
        }
        context.restoreGState()
    }

    // MARK: Notices

    private func noticeText(_ state: FileState) -> (String, Bool) {
        switch state.item.content {
        case .loading: ("Loading diff…", false)
        case .binary: ("Binary file not shown.", false)
        case .unchanged: (state.item.file.status == .renamed ? "File renamed without changes." : "Empty file.", false)
        case .tooLarge: ("Large diffs are not rendered by default. Load diff", true)
        case let .failed(message): ("Could not load the diff: \(message)", false)
        case .diff: ("No changes.", false)
        }
    }

    private func drawNotice(_ state: FileState, bounds: CGRect, geometry: CardGeometry, context: CGContext) {
        let (message, actionable) = noticeText(state)
        let text = NSMutableAttributedString(string: message, attributes: [.font: Metrics.uiFont, .foregroundColor: NSColor(cgColor: theme.mutedText)!])
        if actionable {
            let range = (message as NSString).range(of: "Load diff")
            text.addAttributes([.foregroundColor: NSColor(cgColor: theme.accent)!, .font: Metrics.uiBoldFont], range: range)
        }
        let size = text.size()
        text.draw(at: CGPoint(x: geometry.minX + (geometry.width - size.width) / 2, y: bounds.midY - size.height / 2))
    }

    // MARK: Hit testing

    func hitTest(_ ref: RowRef, point: CGPoint, bounds rowBounds: CGRect) -> HitTarget? {
        let state = files[ref.file]
        let bounds = contentBounds(ref, rowBounds: rowBounds)
        let geometry = CardGeometry(width: bounds.width, numberWidth: state.numberWidth)
        guard point.x >= geometry.minX, point.x <= geometry.maxX else { return nil }
        switch ref.kind {
        case .header:
            let layout = headerLayout(state, bounds: bounds, geometry: geometry)
            if layout.viewed.contains(point) { return .toggleViewed }
            if layout.preview?.contains(point) == true { return .preview }
            if layout.copy.insetBy(dx: -4, dy: -4).contains(point) { return .copyPath }
            return .toggleCollapse
        case .notice:
            if case .tooLarge = state.item.content { return .loadFullDiff }
            return nil
        case let .thread(index):
            let box = threadBox(state: state, file: ref.file, index: index, bounds: bounds, geometry: geometry)
            let layout = threadLayout(state: state, file: ref.file, index: index, geometry: geometry)
            if !layout.collapsed {
                for (commentIndex, comment) in layout.comments.enumerated() where comment.hasMenu {
                    if layout.menuRect(comment: commentIndex, box: box).insetBy(dx: -4, dy: -4).contains(point) {
                        return .commentMenu(thread: index, comment: commentIndex)
                    }
                }
                if layout.replyRect(box: box).contains(point) { return .reply(thread: index) }
            }
            let toggleArea = CGRect(x: box.minX, y: box.minY, width: box.width, height: ThreadLayout.collapsedHeight)
            return state.item.threads[index].isResolved && toggleArea.contains(point) ? .toggleThread(index) : nil
        case let .hunk(index):
            return isExpandable(state, hunk: index) ? .expandHunk(index) : nil
        case .expandTail:
            return .expandTail
        case let .line(hunk, row):
            guard let line = state.diff?.hunks[safe: hunk]?.rows[safe: row] else { return nil }
            for side in [DiffSide.left, .right] {
                guard let cell = side == .left ? line.left : line.right, state.canComment(side: side, from: cell.number, to: cell.number)
                else { continue }
                if plusRect(side, bounds: bounds, geometry: geometry).insetBy(dx: -2, dy: -1).contains(point) { return .addComment(side) }
            }
            return nil
        case .composer, .footer:
            return nil
        }
    }

    // MARK: Symbols

    private func drawSymbol(_ name: String, in rect: CGRect, color: CGColor, pointSize: CGFloat) {
        let key = "\(name)|\(pointSize)|\(color.components ?? [])"
        let image: NSImage
        if let cached = symbols[key] {
            image = cached
        } else {
            let configuration = NSImage.SymbolConfiguration(pointSize: pointSize, weight: .medium)
                .applying(.init(paletteColors: [NSColor(cgColor: color) ?? .labelColor]))
            guard let symbol = NSImage(systemSymbolName: name, accessibilityDescription: nil)?.withSymbolConfiguration(configuration) else { return }
            symbols[key] = symbol
            image = symbol
        }
        let size = image.size
        image.draw(
            in: CGRect(x: rect.midX - size.width / 2, y: rect.midY - size.height / 2, width: size.width, height: size.height),
            from: .zero, operation: .sourceOver, fraction: 1, respectFlipped: true, hints: nil
        )
    }
}

extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
