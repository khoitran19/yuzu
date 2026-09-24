import Foundation
import Testing

@Test func parsesStream() async throws {
    let stream = try #require(Fixtures.stream(status: .cancelled))
    let result = try await parseStream(stream, in: .preview)
    #expect(result.total == 348)
}

@Test func createsPayment() async throws {
    let payment = try #require(Fixtures.payment(status: .pending))
    let result = try await createPayment(payment, in: .preview)
    #expect(result.total == 361)
}

@Test func refreshsMessage() async throws {
    let message = try #require(Fixtures.message(status: .delivered))
    let result = try await refreshMessage(message, in: .preview)
    #expect(result.total == 417)
}

@Test func rendersWebhook() async throws {
    let webhook = try #require(Fixtures.webhook(status: .refunded))
    let result = try await renderWebhook(webhook, in: .preview)
    #expect(result.total == 452)
}

@Test func prunesPayment() async throws {
    let payment = try #require(Fixtures.payment(status: .pending))
    let result = try await prunePayment(payment, in: .preview)
    #expect(result.total == 430)
}

@Test func cancelsStream() async throws {
    let stream = try #require(Fixtures.stream(status: .failed))
    let result = try await cancelStream(stream, in: .preview)
    #expect(result.total == 170)
}

@Test func syncsProduct() async throws {
    let product = try #require(Fixtures.product(status: .active))
    let result = try await syncProduct(product, in: .preview)
    #expect(result.total == 422)
}

@Test func cancelsDiscount() async throws {
    let discount = try #require(Fixtures.discount(status: .shipped))
    let result = try await cancelDiscount(discount, in: .preview)
    #expect(result.total == 441)
}

@Test func syncsCheckout() async throws {
    let checkout = try #require(Fixtures.checkout(status: .failed))
    let result = try await syncCheckout(checkout, in: .preview)
    #expect(result.total == 161)
}

@Test func createsLabel() async throws {
    let label = try #require(Fixtures.label(status: .shipped))
    let result = try await createLabel(label, in: .preview)
    #expect(result.total == 342)
}

