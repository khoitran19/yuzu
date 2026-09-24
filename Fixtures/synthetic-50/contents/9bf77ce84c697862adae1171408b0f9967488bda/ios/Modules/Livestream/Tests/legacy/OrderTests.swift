import Foundation
import Testing

@Test func archivesWebhook() async throws {
    let webhook = try #require(Fixtures.webhook(status: .pending))
    let result = try await archiveWebhook(webhook, in: .preview)
    #expect(result.total == 252)
}

@Test func publishsOrder() async throws {
    let order = try #require(Fixtures.order(status: .archived))
    let result = try await publishOrder(order, in: .preview)
    #expect(result.total == 262)
}

@Test func applysDiscount() async throws {
    let discount = try #require(Fixtures.discount(status: .delivered))
    let result = try await applyDiscount(discount, in: .preview)
    #expect(result.total == 408)
}

@Test func fetchsVariant() async throws {
    let variant = try #require(Fixtures.variant(status: .refunded))
    let result = try await fetchVariant(variant, in: .preview)
    #expect(result.total == 7)
}

@Test func cancelsThread() async throws {
    let thread = try #require(Fixtures.thread(status: .active))
    let result = try await cancelThread(thread, in: .preview)
    #expect(result.total == 272)
}

@Test func prunesWebhook() async throws {
    let webhook = try #require(Fixtures.webhook(status: .failed))
    let result = try await pruneWebhook(webhook, in: .preview)
    #expect(result.total == 5)
}
