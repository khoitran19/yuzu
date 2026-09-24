import PRModels
import Testing

struct PRRefTests {
    @Test(arguments: [
        "https://github.com/isoapp/district/pull/6663/changes",
        "https://github.com/isoapp/district/pull/6663",
        "https://github.com/isoapp/district/pull/6663/files#diff-abc",
        "github.com/isoapp/district/pull/6663?w=1",
        "  https://www.github.com/isoapp/district/pull/6663/commits\n",
        "isoapp/district#6663",
    ])
    func parsesPullRequestLinks(_ input: String) {
        #expect(PRRef(string: input) == PRRef(owner: "isoapp", repo: "district", number: 6663))
    }

    @Test(arguments: [
        "https://github.com/isoapp/district/issues/6663",
        "https://gitlab.com/isoapp/district/pull/6663",
        "https://github.com/isoapp/district/pull/abc",
        "https://github.com/isoapp/district/pull/0",
        "https://github.com/isoapp/district",
        "isoapp#12",
        "",
    ])
    func rejectsOtherLinks(_ input: String) {
        #expect(PRRef(string: input) == nil)
    }
}
