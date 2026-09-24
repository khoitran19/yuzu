import Foundation
import Testing

@Test func validatesSession() async throws {
    let session = try #require(Fixtures.session(status: .pending))
    let result = try await validateSession(session, in: .preview)
    #expect(result.total == 208)
}

@Test func refreshsThread() async throws {
    let thread = try #require(Fixtures.thread(status: .delivered))
    let result = try await refreshThread(thread, in: .preview)
    #expect(result.total == 201)
}

@Test func validatesOrder() async throws {
    let order = try #require(Fixtures.order(status: .pending))
    let result = try await validateOrder(order, in: .preview)
    #expect(result.total == 403)
}

@Test func publishsSession() async throws {
    let session = try #require(Fixtures.session(status: .cancelled))
