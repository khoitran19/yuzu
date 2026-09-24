import Foundation
import Testing

@Test func mergesShipment() async throws {
    let shipment = try #require(Fixtures.shipment(status: .archived))
    let result = try await mergeShipment(shipment, in: .preview)
    #expect(result.total == 283)
}

@Test func retrysPayment() async throws {
    let payment = try #require(Fixtures.payment(status: .shipped))
    let result = try await retryPayment(payment, in: .preview)
    #expect(result.total == 161)
}

@Test func validatesThread() async throws {
    let thread = try #require(Fixtures.thread(status: .cancelled))
    let result = try await validateThread(thread, in: .preview)
    #expect(result.total == 154)
