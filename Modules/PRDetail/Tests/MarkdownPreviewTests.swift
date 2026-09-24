import DiffEngine
import Foundation
@testable import PRDetail
import PRFixtures
import ReviewRules
import Testing

struct MarkdownHTMLTests {
    private let context = MarkdownHTML.Context(owner: "o", repo: "r", oid: "abc", path: "docs/guide/readme.md")

    private func render(_ source: String, changes: MarkdownChanges? = nil) -> MarkdownHTML.Rendered {
        MarkdownHTML.render(source: source, changes: changes, context: context, highlighter: nil)
    }

    @Test func changesComeFromAddedLinesAndRemovalPoints() {
        let diff = FileDiffBuilder.build(patch: "@@ -1,4 +1,3 @@\n a\n-b\n+B\n c\n-d\n")
        let changes = MarkdownChanges(diff: diff)
        #expect(changes.added == IndexSet(integer: 2))
        #expect(changes.removedBefore == IndexSet(integer: 4))
    }

    @Test func marksOnlyBlocksWithChangedLines() {
        let source = "# Title\n\nIntro text.\n\n- one\n- two\n\nLast.\n"
        let rendered = render(source, changes: MarkdownChanges(added: [6], removedBefore: [8]))
        #expect(rendered.changedBlocks == 2)
        #expect(rendered.body.contains(#"<p data-start="6" data-end="6" data-add>two</p>"#))
        #expect(rendered.body.contains(#"<p data-start="8" data-end="8" data-del>Last.</p>"#))
        #expect(rendered.body.contains(#"<p data-start="3" data-end="3">Intro text.</p>"#))
    }

    @Test func removalAfterTheLastBlockGetsAnEndMarker() {
        let rendered = render("Only.\n", changes: MarkdownChanges(removedBefore: [3]))
        #expect(rendered.body.contains(#"class="end-marker" data-start="3" data-end="3" data-del"#))
        #expect(rendered.changedBlocks == 1)
    }

    @Test func htmlBlocksGetAMarkerBeforeThem() {
        let rendered = render("<details>\n<summary>More</summary>\n</details>\n", changes: MarkdownChanges(added: [2]))
        #expect(rendered.body.hasPrefix(#"<div class="html-marker" data-start="1" data-end="3" data-add></div><details>"#))
        #expect(rendered.changedBlocks == 1)
    }

    @Test func onlyTheNonceStylesheetApplies() throws {
        let document = MarkdownHTML.document(render("<style>p { display: none }</style>\n"))
        let nonce = try #require(document.firstMatch(of: /style-src 'nonce-([^']+)'/)?.output.1)
        #expect(document.contains("<style nonce=\"\(nonce)\">"))
        #expect(!document.contains("unsafe-inline"))
    }

    @Test func escapesTextAndCode() {
        let rendered = render("a & b\n\n```\n<b>\n```\n")
        #expect(rendered.body.contains("a &amp; b"))
        #expect(rendered.body.contains("<code>&lt;b&gt;</code>"))
    }

    @Test func resolvesRelativeLinksAndImagesAtTheCommit() {
        let body = render("[x](other.md) ![i](img/a.png) [r](/README.md) [a](#intro) [w](https://example.com)").body
        #expect(body.contains(#"href="https://github.com/o/r/blob/abc/docs/guide/other.md""#))
        #expect(body.contains(#"src="https://raw.githubusercontent.com/o/r/abc/docs/guide/img/a.png""#))
        #expect(body.contains(#"href="https://github.com/o/r/blob/abc/README.md""#))
        #expect(body.contains(##"href="#intro""##))
        #expect(body.contains(#"href="https://example.com""#))
    }

    @Test func mapsLinksAtTheCommitToRepositoryPaths() throws {
        let blob = try #require(URL(string: "https://github.com/o/r/blob/abc/docs/my%20guide.md#setup"))
        let raw = try #require(URL(string: "https://raw.githubusercontent.com/o/r/abc/README.md"))
        let other = try #require(URL(string: "https://github.com/o/r/blob/def/README.md"))
        #expect(context.repositoryPath(of: blob) == "docs/my guide.md")
        #expect(context.repositoryPath(of: raw) == "README.md")
        #expect(context.repositoryPath(of: other) == nil)
    }

    @Test func headingsGetUniqueGitHubAnchors() {
        let body = render("## Hello, World!\n\n## Hello, World!\n").body
        #expect(body.contains(#"<h2 id="hello-world""#))
        #expect(body.contains(#"<h2 id="hello-world-1""#))
    }

    @Test func rendersAlertsWithoutTheMarker() {
        let body = render("> [!WARNING]\n> Careful here.\n").body
        #expect(body.contains("markdown-alert markdown-alert-warning"))
        #expect(body.contains("Careful here."))
        #expect(!body.contains("[!WARNING]"))
    }

    @Test func frontMatterIsATableAndKeepsSourceLines() {
        let rendered = render("---\ntitle: Guide\n---\n# Heading\n", changes: MarkdownChanges(added: [4]))
        #expect(rendered.body.contains(#"<table class="front-matter" data-start="1" data-end="3">"#))
        #expect(rendered.body.contains("<th>title</th>"))
        #expect(rendered.body.contains(#"data-start="4" data-end="4" data-add"#))
    }

    @Test func tightAndTaskLists() {
        let body = render("- [x] done\n- [ ] todo\n").body
        #expect(body.contains(#"<ul class="tight contains-task-list">"#))
        #expect(body.contains(#"<input type="checkbox" disabled checked>"#))
    }
}

@MainActor
struct MarkdownPreviewModelTests {
    @Test func previewRendersTheHeadFileWithChangeMarkers() async throws {
        let (model, controller) = try await loadedModel()
        let path = "docs/runbooks/order-lifecycle.md"
        controller.togglePreview(path)
        #expect(controller.previewPath == path)
        let page = try await waitForPage(controller)
        #expect(page.path == path)
        #expect(page.changedBlocks > 0)
        #expect(page.html.contains("data-add"))
        #expect(model.hasMarkdownFiles)

        controller.togglePreview(path)
        #expect(controller.previewPath == nil)
    }

    @Test func previewOfANewFileHasNoMarkers() async throws {
        let (_, controller) = try await loadedModel()
        controller.togglePreview("docs/runbooks/payment-overview.md")
        let page = try await waitForPage(controller)
        #expect(page.status == "New file")
        #expect(page.changedBlocks == 0)
    }

    @Test func toggleOnAFileThatIsNotMarkdownClosesThePreview() async throws {
        let (_, controller) = try await loadedModel()
        controller.togglePreview("src/not-markdown.ts")
        #expect(controller.previewPath == nil)
        controller.togglePreview("docs/runbooks/order-lifecycle.md")
        controller.togglePreview("src/not-markdown.ts")
        #expect(controller.previewPath == nil)
    }

    private func loadedModel() async throws -> (PRDetailModel, FilesChangedViewController) {
        let directory = URL(filePath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
            .appending(path: "Fixtures/synthetic-50")
        let service = FixturePullRequestService(directory: directory)
        let model = PRDetailModel(ref: try await service.pullRequestRef(), service: service, highlighter: nil, rules: ReviewRules())
        await model.load()
        return (model, model.filesController)
    }

    private func waitForPage(_ controller: FilesChangedViewController) async throws -> MarkdownPreviewPage {
        for _ in 0..<200 {
            if let page = controller.preview.page { return page }
            try await Task.sleep(for: .milliseconds(10))
        }
        throw CancellationError()
    }
}
