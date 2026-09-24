import Foundation
import PRModels
import Testing

struct PRLinkTests {
    private let ref = PRRef(owner: "isoapp", repo: "district", number: 6663)

    @Test(arguments: [
        ("https://github.com/isoapp/district/pull/6663", false),
        ("https://github.com/isoapp/district/pull/6663#issuecomment-1", false),
        ("https://github.com/isoapp/district/pull/6663/commits", false),
        ("https://github.com/isoapp/district/pull/6663/files", true),
        ("https://github.com/isoapp/district/pull/6663/files#diff-abc", true),
        ("https://github.com/isoapp/district/pull/6663/changes", true),
        ("http://www.github.com/isoapp/district/pull/6663", false),
    ])
    func parsesPullRequestLinks(_ link: String, showsFiles: Bool) throws {
        let url = try #require(URL(string: link))
        let parsed = try #require(PRLink(url: url))
        #expect(parsed.ref == ref)
        #expect(parsed.showsFiles == showsFiles)
    }

    @Test(arguments: [
        "https://github.com/isoapp/district/issues/6663",
        "https://github.com/isoapp/district",
        "https://github.com/isoapp",
        "https://example.com/isoapp/district/pull/6663",
        "mailto:isoapp/district#6663",
        "isoapp/district#6663",
    ])
    func rejectsOtherLinks(_ link: String) throws {
        #expect(PRLink(url: try #require(URL(string: link))) == nil)
    }
}
