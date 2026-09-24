import Foundation

public struct DeviceCode: Sendable, Equatable {
    public let deviceCode: String
    public let userCode: String
    public let verificationURI: URL
    /// Seconds until GitHub rejects the device code.
    public let expiresIn: Int
    /// Minimum seconds between token requests.
    public let interval: Int

    public init(deviceCode: String, userCode: String, verificationURI: URL, expiresIn: Int, interval: Int) {
        self.deviceCode = deviceCode
        self.userCode = userCode
        self.verificationURI = verificationURI
        self.expiresIn = expiresIn
        self.interval = interval
    }
}

public enum DeviceFlowError: Error, LocalizedError, Equatable {
    case expired
    case accessDenied
    case github(code: String, description: String?)
    case http(status: Int)
    case malformedResponse

    public var errorDescription: String? {
        switch self {
        case .expired: "The sign-in code expired. Try again."
        case .accessDenied: "Sign-in was canceled on GitHub."
        case let .github(code, description): description ?? "GitHub returned \(code)."
        case let .http(status): "GitHub returned HTTP \(status)."
        case .malformedResponse: "GitHub returned a response the app cannot read."
        }
    }
}

public struct DeviceFlowAuthenticator: Sendable {
    public typealias Sleep = @Sendable (Duration) async throws -> Void

    private let clientID: String
    private let session: URLSession
    private let sleep: Sleep
    private static let codeURL = URL(string: "https://github.com/login/device/code")!
    private static let tokenURL = URL(string: "https://github.com/login/oauth/access_token")!

    public init(
        clientID: String,
        session: URLSession = .shared,
        sleep: @escaping Sleep = { try await Task.sleep(for: $0) }
    ) {
        self.clientID = clientID
        self.session = session
        self.sleep = sleep
    }

    public func start() async throws -> DeviceCode {
        let response = try await post(Self.codeURL, form: ["client_id": clientID, "scope": "repo"], as: CodeResponse.self)
        if let error = response.error { throw DeviceFlowError.github(code: error, description: response.error_description) }
        guard
            let deviceCode = response.device_code, let userCode = response.user_code,
            let uri = response.verification_uri.flatMap(URL.init(string:)),
            let expiresIn = response.expires_in, let interval = response.interval
        else { throw DeviceFlowError.malformedResponse }
        return DeviceCode(deviceCode: deviceCode, userCode: userCode, verificationURI: uri, expiresIn: expiresIn, interval: interval)
    }

    /// Polls until the user approves the code. Throws `CancellationError` when the task is canceled.
    public func waitForToken(_ code: DeviceCode) async throws -> String {
        var interval = max(code.interval, 1)
        var waited = 0
        let form = [
            "client_id": clientID,
            "device_code": code.deviceCode,
            "grant_type": "urn:ietf:params:oauth:grant-type:device_code",
        ]
        while true {
            guard waited < code.expiresIn else { throw DeviceFlowError.expired }
            try await sleep(.seconds(interval))
            waited += interval
            try Task.checkCancellation()
            let response = try await post(Self.tokenURL, form: form, as: TokenResponse.self)
            if let token = response.access_token, !token.isEmpty { return token }
            switch response.error {
            case "authorization_pending": continue
            case "slow_down": interval += 5
            case "expired_token": throw DeviceFlowError.expired
            case "access_denied": throw DeviceFlowError.accessDenied
            case let error?: throw DeviceFlowError.github(code: error, description: response.error_description)
            case nil: throw DeviceFlowError.malformedResponse
            }
        }
    }

    private func post<Response: Decodable>(_ url: URL, form: [String: String], as _: Response.Type) async throws -> Response {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        var components = URLComponents()
        components.queryItems = form.sorted { $0.key < $1.key }.map { URLQueryItem(name: $0.key, value: $0.value) }
        request.httpBody = Data((components.percentEncodedQuery ?? "").utf8)
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw DeviceFlowError.malformedResponse }
        guard (200 ..< 300).contains(http.statusCode) else {
            if http.statusCode == 400, let body = try? JSONDecoder().decode(Response.self, from: data) { return body }
            throw DeviceFlowError.http(status: http.statusCode)
        }
        do {
            return try JSONDecoder().decode(Response.self, from: data)
        } catch {
            throw DeviceFlowError.malformedResponse
        }
    }
}

private struct CodeResponse: Decodable {
    let device_code: String?
    let user_code: String?
    let verification_uri: String?
    let expires_in: Int?
    let interval: Int?
    let error: String?
    let error_description: String?
}

private struct TokenResponse: Decodable {
    let access_token: String?
    let error: String?
    let error_description: String?
}
