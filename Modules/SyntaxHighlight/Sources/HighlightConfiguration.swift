import DiffEngine
import Foundation
import TreeSitter

struct QueryCompileError: Error, CustomStringConvertible {
    let language: HighlightLanguage
    let offset: Int
    let context: String

    var description: String { "\(language) query does not compile at offset \(offset): \(context)" }
}

// A TSQuery does not change after ts_query_new, and each call uses its own parser and cursor.
final class HighlightConfiguration: @unchecked Sendable {
    private let grammar: OpaquePointer
    private let query: OpaquePointer
    private let captureCodes: [UInt8]
    private let patternPredicates: [[QueryPredicate]]

    init(_ language: HighlightLanguage) throws {
        var source = Data()
        for name in language.queryNames {
            guard let url = Bundle.module.url(forResource: name, withExtension: "scm") else {
                throw CocoaError(.fileNoSuchFile, userInfo: [NSFilePathErrorKey: "\(name).scm"])
            }
            source.append(try Data(contentsOf: url))
            source.append(0x0A)
        }
        var errorOffset: UInt32 = 0
        var errorType = TSQueryErrorNone
        let compiled = source.withUnsafeBytes { bytes in
            ts_query_new(
                language.grammar,
                bytes.baseAddress?.assumingMemoryBound(to: CChar.self),
                UInt32(bytes.count),
                &errorOffset,
                &errorType
            )
        }
        guard let compiled else {
            let context = String(decoding: source.dropFirst(Int(errorOffset)).prefix(60), as: UTF8.self)
            throw QueryCompileError(language: language, offset: Int(errorOffset), context: context)
        }
        grammar = language.grammar
        query = compiled
        captureCodes = (0..<ts_query_capture_count(compiled)).map { id in
            var length: UInt32 = 0
            let name = String(cString: ts_query_capture_name_for_id(compiled, id, &length))
            return switch CapturePaint(captureName: name) {
            case .ignore: PaintCode.ignore
            case .plain: PaintCode.plain
            case let .token(kind): kind.rawValue
            }
        }
        patternPredicates = try (0..<ts_query_pattern_count(compiled)).map { pattern in
            try QueryPredicate.parse(query: compiled, pattern: pattern)
        }
    }

    deinit {
        ts_query_delete(query)
    }

    func highlight(lines: [String]) -> [[HighlightSpan]] {
        var units: [UInt16] = []
        var lineStarts: [Int] = []
        lineStarts.reserveCapacity(lines.count + 1)
        for line in lines {
            lineStarts.append(units.count)
            units.append(contentsOf: line.utf16)
            units.append(0x0A)
        }
        lineStarts.append(units.count)

        let paint = units.withUnsafeBufferPointer(paintUnits)
        return lines.indices.map { index in
            spans(in: paint, from: lineStarts[index], to: lineStarts[index + 1] - 1)
        }
    }

    private func paintUnits(_ units: UnsafeBufferPointer<UInt16>) -> [UInt8] {
        var paint = [UInt8](repeating: PaintCode.plain, count: units.count)
        guard let parser = ts_parser_new() else { return paint }
        defer { ts_parser_delete(parser) }
        ts_parser_set_language(parser, grammar)
        let tree = ts_parser_parse_string_encoding(
            parser,
            nil,
            UnsafeRawPointer(units.baseAddress)?.assumingMemoryBound(to: CChar.self),
            UInt32(units.count * 2),
            TSInputEncodingUTF16LE
        )
        guard let tree, let cursor = ts_query_cursor_new() else { return paint }
        defer {
            ts_query_cursor_delete(cursor)
            ts_tree_delete(tree)
        }
        ts_query_cursor_exec(cursor, query, ts_tree_root_node(tree))

        var captures: [Capture] = []
        captures.reserveCapacity(units.count / 4)
        var text = PredicateText(units: units)
        var match = TSQueryMatch()
        var captureIndex: UInt32 = 0
        while ts_query_cursor_next_capture(cursor, &match, &captureIndex) {
            let capture = match.captures[Int(captureIndex)]
            let code = captureCodes[Int(capture.index)]
            guard code != PaintCode.ignore else { continue }
            let predicates = patternPredicates[Int(match.pattern_index)]
            guard predicates.allSatisfy({ $0.allows(match, text: &text) }) else { continue }
            let start = Int32(ts_node_start_byte(capture.node) / 2)
            let end = Int32(ts_node_end_byte(capture.node) / 2)
            guard start < end else { continue }
            captures.append(Capture(start: start, end: end, order: Int32(captures.count), code: code))
        }

        // Paint outer nodes first so inner nodes win; for one node, the later pattern wins.
        captures.sort { $0.length != $1.length ? $0.length > $1.length : $0.order < $1.order }
        paint.withUnsafeMutableBufferPointer { buffer in
            for capture in captures {
                UnsafeMutableBufferPointer(rebasing: buffer[Int(capture.start)..<Int(capture.end)])
                    .update(repeating: capture.code)
            }
        }
        return paint
    }

    private func spans(in paint: [UInt8], from lineStart: Int, to lineEnd: Int) -> [HighlightSpan] {
        var spans: [HighlightSpan] = []
        var position = lineStart
        while position < lineEnd {
            let code = paint[position]
            var runEnd = position + 1
            while runEnd < lineEnd, paint[runEnd] == code { runEnd += 1 }
            if let kind = TokenKind(rawValue: code) {
                spans.append(HighlightSpan(range: NSRange(location: position - lineStart, length: runEnd - position), kind: kind))
            }
            position = runEnd
        }
        return spans
    }
}

private enum PaintCode {
    static let plain: UInt8 = 0xFF
    static let ignore: UInt8 = 0xFE
}

private struct Capture {
    let start: Int32
    let end: Int32
    let order: Int32
    let code: UInt8

    var length: Int32 { end - start }
}
