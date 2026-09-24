import Foundation
import GitHubKit
import PRModels
@testable import SignIn
import Testing

struct AuthSessionTests {
    private let octocat = Actor(login: "octocat", avatarURL: nil)

    @Test func bootstrapDeletesRejectedKeychainTokenAndSignsOut() async {
        let store = FakeTokenStore(token: "stale")
        let session = AuthSession(dependencies: dependencies(store: store, validTokens: ["fresh"]))

        await session.bootstrap()

        #expect(session.state == .signedOut)
        #expect(store.token == nil)
    }

    @Test func bootstrapPrefersEnvironmentTokenOverKeychain() async {
        let store = FakeTokenStore(token: "keychain")
        let session = AuthSession(dependencies: dependencies(store: store, environmentToken: "env", validTokens: ["env", "keychain"]))

        await session.bootstrap()

        #expect(session.state == .signedIn(token: "env", viewer: octocat))
        #expect(store.token == "keychain")
    }

    @Test func signInWithoutClientIDFailsWithExplanation() {
        let session = AuthSession(dependencies: dependencies(store: FakeTokenStore(), clientID: ""))

        session.signIn()

        guard case let .failed(message) = session.state else {
            Issue.record("Expected failed state, got \(session.state)")
            return
        }
        #expect(message.contains("no GitHub client ID"))
    }

    @Test func signInShowsCodeThenSavesTokenAndSignsIn() async throws {
        let clientID = "client-\(UUID().uuidString)"
        let urlSession = StubURLProtocol.session(clientID: clientID, responses: [
            "/login/device/code": [.init(status: 200, json: """
            {"device_code":"d","user_code":"WXYZ-0001","verification_uri":"https://github.com/login/device","expires_in":900,"interval":5}
            """)],
            "/login/oauth/access_token": [.init(status: 200, json: #"{"access_token":"gho_new"}"#)],
        ])
        let store = FakeTokenStore()
        let gate = AsyncStream<Void>.makeStream()
        var dependencies = dependencies(store: store, clientID: clientID, validTokens: ["gho_new"])
        dependencies.makeAuthenticator = {
            DeviceFlowAuthenticator(clientID: $0, session: urlSession) { _ in for await _ in gate.stream { break } }
        }
        let session = AuthSession(dependencies: dependencies)

        session.signIn()
        try await waitUntil { if case .awaitingCode = session.state { true } else { false } }
        guard case let .awaitingCode(code) = session.state else { return }
        #expect(code.userCode == "WXYZ-0001")

        gate.continuation.yield()
        try await waitUntil { session.state == .signedIn(token: "gho_new", viewer: octocat) }
        #expect(store.token == "gho_new")
    }

    @Test func cancelReturnsToSignedOutAndIgnoresLateResults() async throws {
        let clientID = "client-\(UUID().uuidString)"
        let urlSession = StubURLProtocol.session(clientID: clientID, responses: [
            "/login/device/code": [.init(status: 200, json: """
            {"device_code":"d","user_code":"WXYZ-0002","verification_uri":"https://github.com/login/device","expires_in":900,"interval":5}
            """)],
            "/login/oauth/access_token": [.init(status: 200, json: #"{"access_token":"gho_late"}"#)],
        ])
        var dependencies = dependencies(store: FakeTokenStore(), clientID: clientID, validTokens: ["gho_late"])
        dependencies.makeAuthenticator = {
            DeviceFlowAuthenticator(clientID: $0, session: urlSession) { _ in try await Task.sleep(for: .seconds(3_600)) }
        }
        let session = AuthSession(dependencies: dependencies)

        session.signIn()
        try await waitUntil { if case .awaitingCode = session.state { true } else { false } }
        session.cancel()
        try await Task.sleep(for: .milliseconds(50))

        #expect(session.state == .signedOut)
    }

    private func dependencies(
        store: FakeTokenStore,
        clientID: String = "client",
        environmentToken: String? = nil,
        validTokens: Set<String> = []
    ) -> AuthSession.Dependencies {
        let viewer = octocat
        return AuthSession.Dependencies(
            clientID: clientID,
            environmentToken: environmentToken,
            tokenStore: store,
            viewer: { token in
                guard validTokens.contains(token) else { throw GitHubError.unauthorized }
                return viewer
            },
            makeAuthenticator: { DeviceFlowAuthenticator(clientID: $0) }
        )
    }

    private func waitUntil(_ condition: () -> Bool) async throws {
        for _ in 0 ..< 200 {
            if condition() { return }
            try await Task.sleep(for: .milliseconds(10))
        }
        Issue.record("Condition not met in time")
    }
}

final class FakeTokenStore: TokenStoring {
    var token: String?

    init(token: String? = nil) {
        self.token = token
    }

    func load() throws -> String? { token }
    func save(_ token: String) throws { self.token = token }
    func delete() throws { token = nil }
}
