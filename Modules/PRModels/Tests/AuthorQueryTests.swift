import PRModels
import Testing

struct AuthorQueryTests {
    @Test func parsesALogin() {
        #expect(AuthorQuery(string: " @rik\n")?.login == "rik")
        #expect(AuthorQuery(string: "@octo-cat42")?.login == "octo-cat42")
        #expect(AuthorQuery(string: "@me")?.login == "@me")
    }

    @Test(arguments: ["rik", "@", "@-rik", "@rik bob", "@rik:is:open", "@\(String(repeating: "a", count: 40))", "#12"])
    func rejectsOtherText(_ input: String) {
        #expect(AuthorQuery(string: input) == nil)
    }
}
