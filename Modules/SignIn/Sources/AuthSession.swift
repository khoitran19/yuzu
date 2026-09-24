import Foundation
import GitHubKit
import Observation
import os
import PRModels

@Observable
public final class AuthSession {
    public enum State: Equatable {
        /// Validating a saved token or requesting a device code.
        case loading
        case signedOut
        case awaitingCode(DeviceCode)
        case signedIn(token: String, viewer: Actor)
        case failed(String)
    }

    public private(set) var state: State = .loading

    private let dependencies: Dependencies
    @ObservationIgnored private var task: Task<Void, Never>?
    @ObservationIgnored private var generation = 0
    @ObservationIgnored private var lastAction = Action.bootstrap

    public convenience init() {
        self.init(dependencies: .live)
    }

    init(dependencies: Dependencies) {
        self.dependencies = dependencies
    }

    public func bootstrap() async {
        lastAction = .bootstrap
        let generation = restart()
        state = .loading
        if let token = dependencies.environmentToken, !token.isEmpty {
            await validate(token, fromKeychain: false, generation: generation)
            return
        }
        let stored: String?
        do {
            stored = try dependencies.tokenStore.load()
        } catch {
            state = .failed(error.localizedDescription)
            return
        }
        guard let stored else {
            state = .signedOut
            return
        }
        await validate(stored, fromKeychain: true, generation: generation)
    }

    public func signIn() {
        lastAction = .signIn
        let generation = restart()
        guard !dependencies.clientID.isEmpty else {
            state = .failed(Self.missingClientIDMessage)
            return
        }
        state = .loading
        let authenticator = dependencies.makeAuthenticator(dependencies.clientID)
        task = Task {
            do {
                let code = try await authenticator.start()
                guard generation == self.generation else { return }
                state = .awaitingCode(code)
                let token = try await authenticator.waitForToken(code)
                guard generation == self.generation else { return }
                state = .loading
                do {
                    try dependencies.tokenStore.save(token)
                } catch {
                    Self.log.error("Cannot save the GitHub token: \(error.localizedDescription, privacy: .public)")
                }
                let viewer = try await dependencies.viewer(token)
                guard generation == self.generation else { return }
                state = .signedIn(token: token, viewer: viewer)
            } catch {
                guard generation == self.generation, !(error is CancellationError) else { return }
                state = .failed(error.localizedDescription)
            }
        }
    }

    public func cancel() {
        restart()
        state = .signedOut
    }

    public func retry() {
        switch lastAction {
        case .bootstrap: Task { await bootstrap() }
        case .signIn: signIn()
        }
    }

    public func signOut() {
        restart()
        do {
            try dependencies.tokenStore.delete()
        } catch {
            Self.log.error("Cannot delete the GitHub token: \(error.localizedDescription, privacy: .public)")
        }
        state = .signedOut
    }

    @discardableResult
    private func restart() -> Int {
        task?.cancel()
        task = nil
        generation += 1
        return generation
    }

    private func validate(_ token: String, fromKeychain: Bool, generation: Int) async {
        do {
            let viewer = try await dependencies.viewer(token)
            guard generation == self.generation else { return }
            state = .signedIn(token: token, viewer: viewer)
        } catch GitHubError.unauthorized {
            guard generation == self.generation else { return }
            if fromKeychain {
                signOut()
            } else {
                state = .failed("GitHub rejected the token in YUZU_GITHUB_TOKEN.")
            }
        } catch {
            guard generation == self.generation else { return }
            state = .failed(error.localizedDescription)
        }
    }

    private static let log = Logger(subsystem: "dev.khoitran.yuzu", category: "SignIn")

    static var missingClientIDMessage: String {
        #if DEBUG
            "This build has no GitHub client ID. Build with GITHUB_CLIENT_ID, or launch with YUZU_GITHUB_TOKEN."
        #else
            "This build has no GitHub client ID."
        #endif
    }

    private enum Action { case bootstrap, signIn }
}

extension AuthSession {
    struct Dependencies {
        var clientID: String
        var environmentToken: String?
        var tokenStore: any TokenStoring
        var viewer: @Sendable (String) async throws -> Actor
        var makeAuthenticator: (String) -> DeviceFlowAuthenticator

        static var live: Dependencies {
            Dependencies(
                clientID: (Bundle.main.object(forInfoDictionaryKey: "GitHubClientID") as? String ?? "")
                    .trimmingCharacters(in: .whitespacesAndNewlines),
                environmentToken: debugEnvironmentToken,
                tokenStore: TokenStore(),
                viewer: { try await GitHubClient(token: $0).viewer() },
                makeAuthenticator: { DeviceFlowAuthenticator(clientID: $0) }
            )
        }

        private static var debugEnvironmentToken: String? {
            #if DEBUG
                ProcessInfo.processInfo.environment["YUZU_GITHUB_TOKEN"]
            #else
                nil
            #endif
        }
    }
}

protocol TokenStoring {
    func load() throws -> String?
    func save(_ token: String) throws
    func delete() throws
}

extension TokenStore: TokenStoring {}
