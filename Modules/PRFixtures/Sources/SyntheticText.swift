enum Language: CaseIterable {
    case typescript, swift, sql, markdown, json, yaml
}

struct TextStyle {
    enum Flavor { case source, test }

    let language: Language
    let flavor: Flavor
    let indent: String
}

/// Plausible source text for each language, built from random templates.
enum SyntheticText {
    static func document(_ style: TextStyle, count: Int, rng: inout SeededGenerator) -> [String] {
        guard count > 0 else { return [] }
        let footer = count > 2 ? footer(style) : []
        var lines = header(style, rng: &rng)
        while lines.count < count - footer.count {
            lines += block(style, rng: &rng)
        }
        return Array(lines.prefix(count - footer.count)) + footer
    }

    static func fresh(_ style: TextStyle, count: Int, rng: inout SeededGenerator) -> [String] {
        var lines: [String] = []
        while lines.count < count {
            lines += block(style, rng: &rng)
        }
        return Array(lines.prefix(count))
    }

    /// Changes one word or number, so the word diff has something to show.
    static func mutate(_ line: String, rng: inout SeededGenerator) -> String {
        let characters = Array(line)
        var tokens: [Range<Int>] = []
        var start: Int?
        for (index, character) in characters.enumerated() {
            let isWord = character.isLetter || character.isNumber || character == "_"
            if isWord, start == nil { start = index }
            if !isWord, let begin = start {
                if index - begin >= 3 { tokens.append(begin..<index) }
                start = nil
            }
        }
        if let begin = start, characters.count - begin >= 3 { tokens.append(begin..<characters.count) }
        guard !tokens.isEmpty else { return line + (line.isEmpty ? "" : " ") + rng.pick(Words.emoji) }
        let token = rng.pick(tokens)
        let word = String(characters[token])
        var replacement = Int(word).map { String($0 + rng.int(1...9)) } ?? rng.pick(Words.nouns + Words.verbs)
        if replacement == word { replacement += "s" }
        if word.first?.isUppercase == true { replacement = replacement.capitalizedFirst }
        return String(characters[..<token.lowerBound]) + replacement + String(characters[token.upperBound...])
    }

    // MARK: Structure

    private static func header(_ style: TextStyle, rng: inout SeededGenerator) -> [String] {
        switch style.language {
        case .typescript:
            var imports = style.flavor == .test
                ? ["import { describe, expect, it } from 'vitest'"]
                : ["import { logger } from '@district-core/logger'", "import { match } from 'ts-pattern'"]
            for _ in 0..<rng.int(1...3) {
                let noun = rng.pick(Words.nouns)
                imports.append("import { \(noun.capitalizedFirst)Service } from '#@/\(noun)/\(noun)Service.ts'")
            }
            return imports + ["", "const log = logger('\(rng.pick(Words.nouns))', '\(rng.pick(Words.verbs))')", ""]
        case .swift:
            return style.flavor == .test ? ["import Foundation", "import Testing", ""] : ["import Foundation", "import OSLog", ""]
        case .sql:
            return ["-- migrate:up", ""]
        case .markdown:
            return ["# \(rng.pick(Words.nouns).capitalizedFirst) \(rng.pick(Words.topics))", "", paragraph(rng: &rng), ""]
        case .json:
            return ["{"]
        case .yaml:
            return ["name: \(rng.pick(Words.nouns).capitalizedFirst) checks", "on:", "  pull_request:", "  push:", "    branches: [main]", "jobs:"]
        }
    }

    private static func footer(_ style: TextStyle) -> [String] {
        style.language == .json ? ["}"] : []
    }

    private static func block(_ style: TextStyle, rng: inout SeededGenerator) -> [String] {
        switch (style.language, style.flavor) {
        case (.typescript, .source):
            let choice = rng.int(0...9)
            switch choice {
            case 0...3: return tsFunction(style.indent, rng: &rng)
            case 4...5: return tsInterface(style.indent, rng: &rng)
            case 6: return tsLabels(style.indent, rng: &rng)
            case 7: return tsLongType(rng: &rng)
            default: return tsMatch(style.indent, rng: &rng)
            }
        case (.typescript, .test): return tsSpec(style.indent, rng: &rng)
        case (.swift, .source): return rng.chance(0.4) ? swiftStruct(style.indent, rng: &rng) : swiftFunction(style.indent, rng: &rng)
        case (.swift, .test): return swiftTest(style.indent, rng: &rng)
        case (.sql, _):
            let choice = rng.int(0...2)
            return choice == 0 ? sqlTable(style.indent, rng: &rng) : choice == 1 ? sqlIndex(rng: &rng) : sqlQuery(style.indent, rng: &rng)
        case (.markdown, _): return markdown(rng: &rng)
        case (.json, _): return json(rng: &rng)
        case (.yaml, _): return yaml(rng: &rng)
        }
    }

    // MARK: TypeScript

    private static func tsFunction(_ i: String, rng: inout SeededGenerator) -> [String] {
        let verb = rng.pick(Words.verbs)
        let noun = rng.pick(Words.nouns)
        let other = rng.pick(Words.nouns)
        let type = noun.capitalizedFirst
        let status = rng.pick(Words.statuses)
        var lines = [
            "export async function \(verb)\(type)\(other.capitalizedFirst)(\(noun)Id: \(type)Id, options: \(type)Options = {}): Promise<\(type)Result> {",
            "\(i)const \(noun) = await db.\(noun)s.findFirst({ where: { id: \(noun)Id, status: '\(status)' } })",
            "\(i)if (!\(noun)) {",
            "\(i)\(i)throw new NotFoundError(`\(type) ${\(noun)Id} does not exist`)",
            "\(i)}",
        ]
        let middle = [
            "\(i)const total = \(noun).items.reduce((sum, item) => sum + item.price * item.quantity, 0)",
            "\(i)log.info('\(verb) \(noun)', { \(noun)Id, attempt: options.attempt ?? \(rng.int(1...3)) })",
            "\(i)const \(other)s = await load\(other.capitalizedFirst)s(\(noun).\(other)Ids)",
            "\(i)const expiresAt = Temporal.Now.instant().add({ minutes: \(rng.int(5...90)) })",
            "\(i)if (options.dryRun) return { id: \(noun).id, status: 'skipped' }",
            "\(i)await queue.enqueue('\(noun).\(verb)', { \(noun)Id, at: Temporal.Now.instant().toString() })",
            "\(i)const label = `\(rng.pick(Words.cjk)) \(rng.pick(Words.emoji)) ${\(noun).title}`",
            "\(i)for (const \(other) of \(noun).\(other)s) {",
            "\(i)\(i)await \(rng.pick(Words.verbs))\(other.capitalizedFirst)(\(other).id, { reason: '\(rng.pick(Words.statuses))' })",
            "\(i)}",
        ]
        let start = rng.int(0...(middle.count - 4))
        lines += middle[start..<(start + rng.int(2...4))]
        lines += ["\(i)return { id: \(noun).id, status: '\(status)' }", "}", ""]
        return lines
    }

    private static func tsInterface(_ i: String, rng: inout SeededGenerator) -> [String] {
        let name = rng.pick(Words.nouns).capitalizedFirst + rng.pick(Words.suffixes)
        var lines = ["export interface \(name) {"]
        for field in Words.fields.shuffled(using: &rng).prefix(rng.int(2...6)) {
            lines.append("\(i)readonly \(field)\(rng.chance(0.3) ? "?" : ""): \(rng.pick(Words.tsTypes))")
        }
        return lines + ["}", ""]
    }

    private static func tsLabels(_ i: String, rng: inout SeededGenerator) -> [String] {
        var lines = ["export const \(rng.pick(Words.nouns).uppercased())_STATUS_LABELS = {"]
        for status in Words.statuses.shuffled(using: &rng).prefix(rng.int(2...5)) {
            lines.append("\(i)\(status): '\(rng.pick(Words.cjk)) \(rng.pick(Words.emoji))',")
        }
        return lines + ["} as const", ""]
    }

    private static func tsLongType(rng: inout SeededGenerator) -> [String] {
        let noun = rng.pick(Words.nouns)
        let members = (0..<rng.int(18...30)).map { _ in "'\(noun).\(rng.pick(Words.verbs)).\(rng.pick(Words.statuses))'" }
        return ["export type \(noun.capitalizedFirst)Event = " + members.joined(separator: " | "), ""]
    }

    private static func tsMatch(_ i: String, rng: inout SeededGenerator) -> [String] {
        let noun = rng.pick(Words.nouns)
        var lines = ["function \(noun)Tone(status: \(noun.capitalizedFirst)Status) {", "\(i)return match(status)"]
        for status in Words.statuses.shuffled(using: &rng).prefix(rng.int(2...4)) {
            lines.append("\(i)\(i).with('\(status)', () => '\(rng.pick(Words.tones))')")
        }
        return lines + ["\(i)\(i).otherwise(() => 'neutral')", "}", ""]
    }

    private static func tsSpec(_ i: String, rng: inout SeededGenerator) -> [String] {
        let verb = rng.pick(Words.verbs)
        let noun = rng.pick(Words.nouns)
        var lines = ["describe('\(verb)\(noun.capitalizedFirst)', () => {"]
        for _ in 0..<rng.int(1...3) {
            let status = rng.pick(Words.statuses)
            lines += [
                "\(i)it('returns \(status) when the \(noun) is \(rng.pick(Words.statuses))', async () => {",
                "\(i)\(i)const \(noun) = await seed\(noun.capitalizedFirst)({ status: '\(status)', quantity: \(rng.int(1...20)) })",
                "\(i)\(i)const result = await \(verb)\(noun.capitalizedFirst)(\(noun).id)",
                "\(i)\(i)expect(result.status).toBe('\(status)')",
                "\(i)})",
                "",
            ]
        }
        lines.removeLast()
        return lines + ["})", ""]
    }

    // MARK: Swift

    private static func swiftStruct(_ i: String, rng: inout SeededGenerator) -> [String] {
        let name = rng.pick(Words.nouns).capitalizedFirst + rng.pick(Words.suffixes)
        var lines = ["struct \(name): Sendable, Equatable {"]
        for field in Words.fields.shuffled(using: &rng).prefix(rng.int(2...5)) {
            lines.append("\(i)\(rng.chance(0.5) ? "let" : "var") \(field): \(rng.pick(Words.swiftTypes))")
        }
        return lines + ["}", ""]
    }

    private static func swiftFunction(_ i: String, rng: inout SeededGenerator) -> [String] {
        let verb = rng.pick(Words.verbs)
        let noun = rng.pick(Words.nouns)
        let type = noun.capitalizedFirst
        return [
            "func \(verb)\(type)(_ \(noun): \(type), in context: Context) async throws -> \(type)Result {",
            "\(i)guard let owner = context.owner(of: \(noun).id) else { throw \(type)Error.missingOwner }",
            "\(i)let items = try await context.load(\(noun).itemIDs)",
            "\(i)let total = items.reduce(Decimal.zero) { $0 + $1.price * Decimal($1.quantity) }",
            "\(i)logger.info(\"\(verb) \(noun) \\(\(noun).id, privacy: .public) total=\\(total) \(rng.pick(Words.emoji))\")",
            "\(i)return \(type)Result(id: \(noun).id, owner: owner, total: total, status: .\(rng.pick(Words.statuses)))",
            "}",
            "",
        ]
    }

    private static func swiftTest(_ i: String, rng: inout SeededGenerator) -> [String] {
        let verb = rng.pick(Words.verbs)
        let noun = rng.pick(Words.nouns)
        return [
            "@Test func \(verb)s\(noun.capitalizedFirst)() async throws {",
            "\(i)let \(noun) = try #require(Fixtures.\(noun)(status: .\(rng.pick(Words.statuses))))",
            "\(i)let result = try await \(verb)\(noun.capitalizedFirst)(\(noun), in: .preview)",
            "\(i)#expect(result.total == \(rng.int(1...500)))",
            "}",
            "",
        ]
    }

    // MARK: SQL

    private static func sqlTable(_ i: String, rng: inout SeededGenerator) -> [String] {
        let noun = rng.pick(Words.nouns)
        let other = rng.pick(Words.nouns)
        return [
            "CREATE TABLE IF NOT EXISTS \(noun)_\(other)s (",
            "\(i)id uuid PRIMARY KEY DEFAULT gen_random_uuid(),",
            "\(i)\(noun)_id uuid NOT NULL REFERENCES \(noun)s (id) ON DELETE CASCADE,",
            "\(i)status text NOT NULL DEFAULT '\(rng.pick(Words.statuses))',",
            "\(i)amount numeric(12, \(rng.int(2...4))) NOT NULL,",
            "\(i)created_at timestamptz NOT NULL DEFAULT now()",
            ");",
            "",
        ]
    }

    private static func sqlIndex(rng: inout SeededGenerator) -> [String] {
        let noun = rng.pick(Words.nouns)
        let field = rng.pick(["status", "created_at", "owner_id", "marketplace_id"])
        return ["CREATE INDEX IF NOT EXISTS \(noun)s_\(field)_idx ON \(noun)s (\(field));", ""]
    }

    private static func sqlQuery(_ i: String, rng: inout SeededGenerator) -> [String] {
        let noun = rng.pick(Words.nouns)
        let other = rng.pick(Words.nouns)
        return [
            "SELECT o.id, o.status, sum(i.amount) AS total",
            "FROM \(noun)s o",
            "\(i)JOIN \(other)s i ON i.\(noun)_id = o.id",
            "WHERE o.status = '\(rng.pick(Words.statuses))' AND o.created_at > now() - interval '\(rng.int(1...90)) days'",
            "GROUP BY o.id, o.status;",
            "",
        ]
    }

    // MARK: Markdown

    private static func markdown(rng: inout SeededGenerator) -> [String] {
        var lines = ["## \(rng.pick(Words.verbs).capitalizedFirst) the \(rng.pick(Words.nouns)) \(rng.pick(Words.topics))", ""]
        switch rng.int(0...3) {
        case 0:
            lines += [paragraph(rng: &rng), ""]
        case 1:
            for _ in 0..<rng.int(2...5) { lines.append("- \(sentence(rng: &rng))") }
            lines.append("")
        case 2:
            lines += ["```ts"] + tsFunction("  ", rng: &rng).dropLast() + ["```", ""]
        default:
            lines += ["| Field | Type | Notes |", "| --- | --- | --- |"]
            for field in Words.fields.shuffled(using: &rng).prefix(rng.int(2...5)) {
                lines.append("| `\(field)` | `\(rng.pick(Words.tsTypes))` | \(sentence(rng: &rng)) |")
            }
            lines.append("")
        }
        return lines
    }

    static func paragraph(rng: inout SeededGenerator) -> String {
        (0..<rng.int(3...8)).map { _ in sentence(rng: &rng) }.joined(separator: " ")
    }

    static func sentence(rng: inout SeededGenerator) -> String {
        switch rng.int(0...4) {
        case 0: "The \(rng.pick(Words.nouns)) service \(rng.pick(Words.verbs))s each \(rng.pick(Words.nouns)) before the \(rng.pick(Words.nouns)) webhook runs."
        case 1: "A \(rng.pick(Words.statuses)) \(rng.pick(Words.nouns)) cannot change to \(rng.pick(Words.statuses)) until the \(rng.pick(Words.nouns)) is \(rng.pick(Words.statuses))."
        case 2: "Buyers in Japan see \(rng.pick(Words.cjk)) \(rng.pick(Words.emoji)) while the \(rng.pick(Words.nouns)) is \(rng.pick(Words.statuses))."
        case 3: "Set `\(rng.pick(Words.fields))` to limit how many \(rng.pick(Words.nouns))s each worker \(rng.pick(Words.verbs))s in one batch."
        default: "\(rng.pick(Words.emoji)) The \(rng.pick(Words.verbs)) step retries \(rng.int(2...5)) times, then marks the \(rng.pick(Words.nouns)) as \(rng.pick(Words.statuses))."
        }
    }

    // MARK: JSON and YAML

    private static func json(rng: inout SeededGenerator) -> [String] {
        let noun = rng.pick(Words.nouns)
        switch rng.int(0...2) {
        case 0:
            var lines = ["  \"\(noun)\": {"]
            for field in Words.fields.shuffled(using: &rng).prefix(rng.int(2...5)) {
                lines.append("    \"\(field)\": \"\(rng.pick(Words.statuses))-\(rng.int(1...999))\",")
            }
            return lines + ["    \"enabled\": \(rng.chance(0.5))", "  },"]
        case 1:
            return (0..<rng.int(2...4)).map { _ in
                "  \"\(noun).\(rng.pick(Words.verbs)).\(rng.pick(Words.statuses))\": \"\(rng.pick(Words.cjk)) \(rng.pick(Words.emoji))\","
            }
        default:
            return ["  \"\(noun)Description\": \"\(paragraph(rng: &rng))\","]
        }
    }

    private static func yaml(rng: inout SeededGenerator) -> [String] {
        let verb = rng.pick(Words.verbs)
        let noun = rng.pick(Words.nouns)
        return [
            "  \(verb)-\(noun):",
            "    runs-on: ubuntu-latest",
            "    timeout-minutes: \(rng.int(5...45))",
            "    steps:",
            "      - uses: actions/checkout@v5",
            "      - name: \(verb.capitalizedFirst) \(noun)s \(rng.pick(Words.emoji))",
            "        run: pnpm moon run \(noun):\(verb) -- --reporter=dot --shard=\(rng.int(1...4))/4",
        ]
    }
}

enum Words {
    static let nouns = [
        "order", "checkout", "payment", "invoice", "listing", "seller", "buyer", "shipment", "refund", "cart",
        "offer", "message", "stream", "session", "token", "account", "inventory", "product", "variant", "price",
        "discount", "review", "thread", "notification", "webhook", "channel", "label", "payout", "wallet", "coupon",
    ]
    static let verbs = [
        "load", "create", "update", "resolve", "fetch", "sync", "apply", "validate", "parse", "render", "compute",
        "archive", "publish", "cancel", "retry", "schedule", "merge", "prune", "refresh", "reconcile",
    ]
    static let statuses = ["pending", "active", "shipped", "delivered", "cancelled", "refunded", "failed", "archived"]
    static let fields = [
        "id", "status", "createdAt", "updatedAt", "amount", "currency", "quantity", "ownerId", "marketplaceId",
        "metadata", "expiresAt", "attempt", "reason", "title", "slug",
    ]
    static let suffixes = ["Summary", "Options", "Result", "Input", "Record", "Snapshot", "Event", "Row"]
    static let topics = ["lifecycle", "retries", "migration", "rollout", "limits", "overview"]
    static let tones = ["positive", "warning", "critical", "info"]
    static let tsTypes = ["string", "number", "boolean", "Temporal.Instant", "readonly string[]", "Money", "Record<string, unknown>"]
    static let swiftTypes = ["String", "Int", "Bool", "Date", "Decimal", "[String]", "URL?"]
    static let cjk = ["注文を確認しています", "正在处理您的订单", "주문을 처리하는 중입니다", "配送状況を更新しました", "退款已完成", "결제가 실패했습니다"]
    static let emoji = ["🚚", "✅", "💳", "🛒", "📦", "🔥", "⚠️", "🎉", "👀", "🧾"]
}

extension String {
    var capitalizedFirst: String { prefix(1).uppercased() + dropFirst() }
}
