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

    @Test(arguments: ["3080", " #3080\n"])
    func resolvesABareNumberInTheActiveRepository(_ input: String) {
        let graph = RepoRef(owner: "isoapp", name: "graph")
        #expect(PRRef(string: input, in: graph) == PRRef(owner: "isoapp", repo: "graph", number: 3080))
        #expect(PRRef(string: input) == nil)
    }

    @Test func aLinkWinsOverTheActiveRepository() {
        let graph = RepoRef(owner: "isoapp", name: "graph")
        #expect(PRRef(string: "isoapp/district#6663", in: graph) == PRRef(owner: "isoapp", repo: "district", number: 6663))
    }

    @Test(arguments: ["0", "#", "12a"])
    func rejectsANumberThatIsNotAPullRequest(_ input: String) {
        #expect(PRRef(string: input, in: RepoRef(owner: "isoapp", name: "graph")) == nil)
    }

    @Test func rejectsABareNumberWithNoActiveRepository() {
        #expect(PRRef(string: "3080", in: nil) == nil)
    }
}
