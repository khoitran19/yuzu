@testable import FileTree
import Testing

struct FileTreeBuilderTests {
    @Test func compactsSingleChildDirectoryChains() {
        let tree = FileTreeBuilder.build(entries(
            "apps/platform/messaging-gateway/src/index.ts",
            "apps/platform/messaging-gateway/src/linq.ts",
            "apps/platform/messaging-gateway/package.json"
        ))
        #expect(tree.roots.map(\.name) == ["apps/platform/messaging-gateway"])
        let gateway = tree.roots[0]
        #expect(gateway.path == "apps/platform/messaging-gateway")
        #expect(gateway.children.map(\.name) == ["src", "package.json"])
        #expect(gateway.children[0].path == "apps/platform/messaging-gateway/src")
    }

    @Test func doesNotCompactDirectoryThatHasFiles() {
        let tree = FileTreeBuilder.build(entries("a/readme.md", "a/b/c.ts"))
        #expect(tree.roots.map(\.name) == ["a"])
        #expect(tree.roots[0].children.map(\.name) == ["b", "readme.md"])
    }

    @Test func doesNotCompactDirectoryWithTwoSubdirectories() {
        let tree = FileTreeBuilder.build(entries("a/b/one.ts", "a/c/two.ts"))
        #expect(tree.roots.map(\.name) == ["a"])
        #expect(tree.roots[0].children.map(\.name) == ["b", "c"])
    }

    @Test func ordersDirectoriesBeforeFilesCaseInsensitivelyWithUnderscoreFirst() {
        let tree = FileTreeBuilder.build(entries(
            "src/zeta.ts",
            "src/Alpha.ts",
            "src/beta.ts",
            "src/approvals/a.ts",
            "src/__tests__/a.spec.ts",
            "src/Components/b.tsx",
            "src/_internal.ts"
        ))
        #expect(tree.roots[0].children.map(\.name) == [
            "__tests__", "approvals", "Components", "_internal.ts", "Alpha.ts", "beta.ts", "zeta.ts",
        ])
    }

    @Test func sortsCompactedDirectoriesByDisplayName() {
        let tree = FileTreeBuilder.build(entries("b/only/x.ts", "a.md", "apps/web/y.ts", "apps/web/z.ts"))
        #expect(tree.roots.map(\.name) == ["apps/web", "b/only", "a.md"])
    }

    @Test func orderedFilePathsFollowDepthFirstDisplayOrder() {
        let tree = FileTreeBuilder.build(entries(
            "README.md",
            "src/index.ts",
            "src/__tests__/index.spec.ts",
            "docs/guide.md",
            "src/lib/util.ts"
        ))
        #expect(tree.orderedFilePaths == [
            "docs/guide.md",
            "src/__tests__/index.spec.ts",
            "src/lib/util.ts",
            "src/index.ts",
            "README.md",
        ])
    }

    @Test func keepsStatusAndViewedStateOnFileNodes() throws {
        let tree = FileTreeBuilder.build([
            FileTreeEntry(path: "a/new.ts", status: .added, isViewed: true),
            FileTreeEntry(path: "a/old.ts", status: .removed, isViewed: false),
        ])
        let added = try #require(tree.filesByPath["a/new.ts"])
        #expect(added.kind == .file(.added))
        #expect(added.isViewed)
        #expect(added.parent?.path == "a")
        #expect(tree.filesByPath["a/old.ts"]?.kind == .file(.removed))
    }

    @Test func filterMatchesSubstringOfFullPathIgnoringCase() {
        let all = entries("apps/Gateway/src/linq.ts", "apps/web/src/page.tsx", "packages/gateway-client/index.ts")
        #expect(FileTreeBuilder.filter(all, query: "GATEWAY").map(\.path) == [
            "apps/Gateway/src/linq.ts", "packages/gateway-client/index.ts",
        ])
        #expect(FileTreeBuilder.filter(all, query: "web/src/p").map(\.path) == ["apps/web/src/page.tsx"])
        #expect(FileTreeBuilder.filter(all, query: "  ").count == 3)
        #expect(FileTreeBuilder.filter(all, query: "nothing").isEmpty)
    }

    @Test func filteredTreeCompactsAgainAroundMatches() {
        let all = entries("apps/web/src/page.tsx", "apps/web/src/layout.tsx", "apps/api/main.ts")
        let tree = FileTreeBuilder.build(FileTreeBuilder.filter(all, query: "page"))
        #expect(tree.roots.map(\.name) == ["apps/web/src"])
        #expect(tree.orderedFilePaths == ["apps/web/src/page.tsx"])
    }
}

func entries(_ paths: String...) -> [FileTreeEntry] {
    paths.map { FileTreeEntry(path: $0, status: .modified, isViewed: false) }
}
