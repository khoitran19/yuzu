import Foundation
import GitHubKit
import Synchronization
import Testing

struct DeviceFlowTests {
    private let clientID = "client-\(UUID().uuidString)"
    private let code = DeviceCode(
        deviceCode: "device-123", userCode: "ABCD-1234",
        verificationURI: URL(string: "https://github.com/login/device")!, expiresIn: 900, interval: 5
    )

    @Test func startRequestsRepoScopeAndParsesCode() async throws {
        let session = StubURLProtocol.session(clientID: clientID, responses: [
            "/login/device/code": [.init(status: 200, json: """
            {"device_code":"device-123","user_code":"ABCD-1234","verification_uri":"https://github.com/login/device","expires_in":900,"interval":5}
            """)],
        ])
        let result = try await DeviceFlowAuthenticator(clientID: clientID, session: session).start()

        #expect(result == code)
        let request = try #require(StubURLProtocol.requests(clientID: clientID).first)
        #expect(request.form["scope"] == "repo")
        #expect(request.headers["Accept"] == "application/json")
    }

    @Test func startSurfacesGitHubError() async {
        let session = StubURLProtocol.session(clientID: clientID, responses: [
            "/login/device/code": [.init(status: 200, json: #"{"error":"device_flow_disabled","error_description":"Device flow is off."}"#)],
        ])
        await #expect(throws: DeviceFlowError.github(code: "device_flow_disabled", description: "Device flow is off.")) {
            try await DeviceFlowAuthenticator(clientID: clientID, session: session).start()
        }
    }

    @Test func pollsThroughPendingAndSlowDownUntilToken() async throws {
        let sleeps = Mutex<[Duration]>([])
        let session = tokenSession(
            #"{"error":"authorization_pending"}"#,
            #"{"error":"slow_down","interval":10}"#,
            #"{"error":"authorization_pending"}"#,
            #"{"access_token":"gho_token","token_type":"bearer","scope":"repo"}"#
        )
        let authenticator = DeviceFlowAuthenticator(clientID: clientID, session: session) { duration in
            sleeps.withLock { $0.append(duration) }
        }

        let token = try await authenticator.waitForToken(code)

        #expect(token == "gho_token")
        #expect(sleeps.withLock { $0 } == [.seconds(5), .seconds(5), .seconds(10), .seconds(10)])
        let requests = StubURLProtocol.requests(clientID: clientID)
        #expect(requests.count == 4)
        #expect(requests.allSatisfy {
            $0.form["grant_type"] == "urn:ietf:params:oauth:grant-type:device_code" && $0.form["device_code"] == "device-123"
        })
    }

    @Test func throwsExpiredWhenGitHubExpiresTheCode() async {
        let authenticator = DeviceFlowAuthenticator(clientID: clientID, session: tokenSession(#"{"error":"expired_token"}"#)) { _ in }
        await #expect(throws: DeviceFlowError.expired) { try await authenticator.waitForToken(code) }
    }

    @Test func throwsExpiredAfterExpiryWithoutExtraRequests() async {
        let shortCode = DeviceCode(deviceCode: "d", userCode: "u", verificationURI: code.verificationURI, expiresIn: 10, interval: 5)
        let authenticator = DeviceFlowAuthenticator(clientID: clientID, session: tokenSession(#"{"error":"authorization_pending"}"#)) { _ in }
        await #expect(throws: DeviceFlowError.expired) { try await authenticator.waitForToken(shortCode) }
        #expect(StubURLProtocol.requests(clientID: clientID).count == 2)
    }

    @Test func throwsAccessDeniedWhenUserRejects() async {
        let authenticator = DeviceFlowAuthenticator(clientID: clientID, session: tokenSession(#"{"error":"access_denied"}"#)) { _ in }
        await #expect(throws: DeviceFlowError.accessDenied) { try await authenticator.waitForToken(code) }
    }

    @Test func surfacesOtherErrors() async {
        let json = #"{"error":"incorrect_client_credentials","error_description":"Bad client."}"#
        let authenticator = DeviceFlowAuthenticator(clientID: clientID, session: tokenSession(json)) { _ in }
        await #expect(throws: DeviceFlowError.github(code: "incorrect_client_credentials", description: "Bad client.")) {
            try await authenticator.waitForToken(code)
        }
    }

    @Test func stopsPollingWhenTaskIsCanceled() async {
        let (started, startedContinuation) = AsyncStream<Void>.makeStream()
        let authenticator = DeviceFlowAuthenticator(
            clientID: clientID, session: tokenSession(#"{"error":"authorization_pending"}"#)
        ) { _ in
            startedContinuation.yield()
            try await Task.sleep(for: .seconds(3_600))
        }
        let task = Task { try await authenticator.waitForToken(code) }
        for await _ in started { break }
        task.cancel()

        await #expect(throws: CancellationError.self) { try await task.value }
        #expect(StubURLProtocol.requests(clientID: clientID).isEmpty)
    }

    private func tokenSession(_ responses: String...) -> URLSession {
        StubURLProtocol.session(clientID: clientID, responses: [
            "/login/oauth/access_token": responses.map { .init(status: 200, json: $0) },
        ])
    }
}
