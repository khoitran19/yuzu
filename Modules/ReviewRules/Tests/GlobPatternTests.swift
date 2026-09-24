import ReviewRules
import Testing

struct GlobPatternTests {
    @Test(arguments: [
        ("*.spec.ts", "apps/gateway/src/linq.spec.ts", true),
        ("*.spec.ts", "apps/gateway/src/linq.ts", false),
        ("__tests__", "apps/gateway/src/__tests__/sweep.spec.ts", true),
        ("__tests__", "apps/gateway/src/tests/sweep.spec.ts", false),
        ("apps/*/src", "apps/gateway/src/linq.ts", true),
        ("apps/*/src", "packages/apps/gateway/src/linq.ts", false),
        ("**/migrations/*.sql", "packages/db/schema/migrations/001.sql", true),
        ("**/migrations/*.sql", "packages/db/schema/migrations/nested/001.sql", false),
        ("docs/**", "docs/platform/assistant/imessage.md", true),
        ("/docs", "packages/docs/readme.md", false),
        ("pnpm-lock.yaml", "pnpm-lock.yaml", true),
        ("schema?.sql", "db/schema1.sql", true),
        ("snapshots/", "snapshots", false),
        ("snapshots/", "a/snapshots/one.snap", true),
    ])
    func matchesFiles(pattern: String, path: String, expected: Bool) throws {
        let glob = try #require(GlobPattern(pattern))
        #expect(glob.matches(path: path) == expected)
    }

    @Test func directoryOnlyPatternMatchesDirectories() throws {
        let glob = try #require(GlobPattern("snapshots/"))
        #expect(glob.matches(path: "a/snapshots", isDirectory: true))
    }

    @Test(arguments: ["", "   ", "# comment", "/"])
    func skipsBlankAndCommentLines(_ pattern: String) {
        #expect(GlobPattern(pattern) == nil)
    }

    @Test func dotIsLiteral() throws {
        let glob = try #require(GlobPattern("a.ts"))
        #expect(!glob.matches(path: "abts"))
    }
}
