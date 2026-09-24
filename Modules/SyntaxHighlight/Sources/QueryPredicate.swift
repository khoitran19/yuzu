import Foundation
import TreeSitter

/// Text predicates of a highlight query. `is-not?`, `set!`, and unknown predicates always allow the match.
enum QueryPredicate {
    case equals(capture: UInt32, value: [UInt16], negated: Bool)
    case capturesEqual(UInt32, UInt32, negated: Bool)
    case matches(capture: UInt32, pattern: PatternMatcher, negated: Bool)
    case anyOf(capture: UInt32, values: Set<String>, negated: Bool)

    static func parse(query: OpaquePointer, pattern: UInt32) throws -> [QueryPredicate] {
        var stepCount: UInt32 = 0
        guard let steps = ts_query_predicates_for_pattern(query, pattern, &stepCount), stepCount > 0 else { return [] }
        var predicates: [QueryPredicate] = []
        var arguments: [TSQueryPredicateStep] = []
        for step in UnsafeBufferPointer(start: steps, count: Int(stepCount)) {
            guard step.type == TSQueryPredicateStepTypeDone else {
                arguments.append(step)
                continue
            }
            if let predicate = try predicate(from: arguments, query: query) { predicates.append(predicate) }
            arguments.removeAll(keepingCapacity: true)
        }
        return predicates
    }

    private static func predicate(from steps: [TSQueryPredicateStep], query: OpaquePointer) throws -> QueryPredicate? {
        guard let name = steps.first, name.type == TSQueryPredicateStepTypeString,
              let subject = steps.dropFirst().first, subject.type == TSQueryPredicateStepTypeCapture
        else { return nil }
        let arguments = steps.dropFirst(2)
        let strings = arguments.filter { $0.type == TSQueryPredicateStepTypeString }.map { string(for: $0, in: query) }
        let predicateName = string(for: name, in: query)
        let negated = predicateName.hasPrefix("not-")
        switch predicateName {
        case "eq?", "not-eq?":
            guard let argument = arguments.first, arguments.count == 1 else { return nil }
            if argument.type == TSQueryPredicateStepTypeCapture {
                return .capturesEqual(subject.value_id, argument.value_id, negated: negated)
            }
            return .equals(capture: subject.value_id, value: Array(strings[0].utf16), negated: negated)
        case "match?", "not-match?":
            guard let pattern = strings.first, strings.count == 1 else { return nil }
            return .matches(capture: subject.value_id, pattern: try PatternMatcher(pattern), negated: negated)
        case "any-of?", "not-any-of?":
            return .anyOf(capture: subject.value_id, values: Set(strings), negated: negated)
        default:
            return nil
        }
    }

    private static func string(for step: TSQueryPredicateStep, in query: OpaquePointer) -> String {
        var length: UInt32 = 0
        return String(cString: ts_query_string_value_for_id(query, step.value_id, &length))
    }

    func allows(_ match: TSQueryMatch, text: inout PredicateText) -> Bool {
        switch self {
        case let .equals(capture, value, negated):
            guard let range = match.range(of: capture) else { return true }
            return text.equals(range, value) != negated
        case let .capturesEqual(first, second, negated):
            guard let firstRange = match.range(of: first), let secondRange = match.range(of: second) else { return true }
            return text.equals(firstRange, secondRange) != negated
        case let .matches(capture, pattern, negated):
            guard let range = match.range(of: capture) else { return true }
            return pattern.matches(range, in: &text) != negated
        case let .anyOf(capture, values, negated):
            guard let range = match.range(of: capture) else { return true }
            return values.contains(text.string(range)) != negated
        }
    }
}

/// A `#match?` regular expression with a check of the first character that skips most regex calls.
struct PatternMatcher {
    private let regex: NSRegularExpression
    private let firstCharacters: [Bool]?
    private let firstCharacterDecides: Bool

    init(_ pattern: String) throws {
        regex = try NSRegularExpression(pattern: pattern)
        let prefix = AnchoredPrefix(pattern)
        firstCharacters = prefix?.characters
        firstCharacterDecides = prefix?.isWholePattern ?? false
    }

    func matches(_ range: NSRange, in text: inout PredicateText) -> Bool {
        if let firstCharacters {
            guard range.length > 0 else { return false }
            let unit = text.units[range.location]
            guard unit < 128, firstCharacters[Int(unit)] else { return false }
            if firstCharacterDecides { return true }
        }
        return regex.firstMatch(in: text.string, range: range) != nil
    }
}

/// The ASCII characters that can start a match of a pattern with the form `^[class]…`, `^(word|word)…`, or `^c…`.
private struct AnchoredPrefix {
    var characters = [Bool](repeating: false, count: 128)
    var isWholePattern = false

    init?(_ pattern: String) {
        let scalars = Array(pattern.unicodeScalars)
        guard scalars.first == "^", scalars.count > 1 else { return nil }
        var index = 1
        switch scalars[index] {
        case "[":
            guard let close = scalars[(index + 1)...].firstIndex(of: "]"), close > index + 1,
                  markClass(scalars[(index + 1)..<close]) else { return nil }
            index = close + 1
        case "(":
            guard let close = scalars[(index + 1)...].firstIndex(of: ")"),
                  !scalars[(index + 1)..<close].contains(where: { $0 == "(" || $0 == "\\" }) else { return nil }
            for word in scalars[(index + 1)..<close].split(separator: "|", omittingEmptySubsequences: false) {
                guard let first = word.first, Self.isLiteral(first) else { return nil }
                characters[Int(first.value)] = true
            }
            index = close + 1
        case let scalar where Self.isLiteral(scalar):
            characters[Int(scalar.value)] = true
            index += 1
        default:
            return nil
        }
        if index < scalars.count, ["?", "*", "{"].contains(scalars[index]) { return nil }
        guard !scalars[index...].contains("|") else { return nil }
        isWholePattern = index == scalars.count
    }

    private mutating func markClass(_ body: ArraySlice<Unicode.Scalar>) -> Bool {
        var index = body.startIndex
        while index < body.endIndex {
            let scalar = body[index]
            if scalar == "\\" {
                guard index + 1 < body.endIndex, body[index + 1] == "d" else { return false }
                mark("0", "9")
                index += 2
            } else if index + 2 < body.endIndex, body[index + 1] == "-" {
                guard scalar.isASCII, body[index + 2].isASCII, scalar != "^" else { return false }
                mark(scalar, body[index + 2])
                index += 3
            } else {
                guard scalar.isASCII, scalar != "^", scalar != "[" else { return false }
                mark(scalar, scalar)
                index += 1
            }
        }
        return true
    }

    private mutating func mark(_ lower: Unicode.Scalar, _ upper: Unicode.Scalar) {
        guard lower.value <= upper.value else { return }
        for value in lower.value...upper.value { characters[Int(value)] = true }
    }

    private static func isLiteral(_ scalar: Unicode.Scalar) -> Bool {
        scalar.isASCII && !"\\^$.|?*+()[]{}".unicodeScalars.contains(scalar)
    }
}

/// The parsed text, as UTF-16 code units. It creates the string only when a regex runs.
struct PredicateText {
    let units: UnsafeBufferPointer<UInt16>
    private var cachedString: String?

    init(units: UnsafeBufferPointer<UInt16>) {
        self.units = units
    }

    var string: String {
        mutating get {
            if let cachedString { return cachedString }
            let created = units.baseAddress.map { NSString(characters: $0, length: units.count) as String } ?? ""
            cachedString = created
            return created
        }
    }

    func string(_ range: NSRange) -> String {
        String(decoding: slice(range), as: UTF16.self)
    }

    func equals(_ range: NSRange, _ value: [UInt16]) -> Bool {
        range.length == value.count && slice(range).elementsEqual(value)
    }

    func equals(_ first: NSRange, _ second: NSRange) -> Bool {
        first.length == second.length && slice(first).elementsEqual(slice(second))
    }

    private func slice(_ range: NSRange) -> Slice<UnsafeBufferPointer<UInt16>> {
        units[range.location..<(range.location + range.length)]
    }
}

private extension TSQueryMatch {
    func range(of captureID: UInt32) -> NSRange? {
        for capture in UnsafeBufferPointer(start: captures, count: Int(capture_count)) where capture.index == captureID {
            let start = Int(ts_node_start_byte(capture.node) / 2)
            return NSRange(location: start, length: Int(ts_node_end_byte(capture.node) / 2) - start)
        }
        return nil
    }
}
