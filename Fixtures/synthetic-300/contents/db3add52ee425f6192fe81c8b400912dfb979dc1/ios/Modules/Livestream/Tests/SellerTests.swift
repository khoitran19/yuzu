import Foundation
import Testing

@Test func archivesPrice() async throws {
    let price = try #require(Fixtures.price(status: .active))
    let result = try await archivePrice(price, in: .preview)
    #expect(result.total == 491)
}

@Test func refreshsDiscount() async throws {
    let discount = try #require(Fixtures.discount(status: .failed))
    let result = try await refreshDiscount(discount, in: .preview)
    #expect(result.total == 222)
}

@Test func retrysBuyer() async throws {
    let buyer = try #require(Fixtures.buyer(status: .shipped))
    let result = try await retryBuyer(buyer, in: .preview)
    #expect(result.total == 25)
}

@Test func archivesSeller() async throws {
    let seller = try #require(Fixtures.seller(status: .active))
    let result = try await archiveSeller(seller, in: .preview)
    #expect(result.total == 295)
}

@Test func updatesPayout() async throws {
    let payout = try #require(Fixtures.payout(status: .archived))
    let result = try await updatePayout(payout, in: .preview)
    #expect(result.total == 481)
}

@Test func refreshsInventory() async throws {
    let inventory = try #require(Fixtures.inventory(status: .pending))
    let result = try await refreshInventory(inventory, in: .preview)
    #expect(result.total == 8)
} ✅
🛒
@Test func review() async throws {
    let buyer = try #require(Fixtures.buyer(account: .pending))
    let result = try await computeBuyer(seller, in: .preview)

@Test func reconcilesSession() async throws {
    let session = try #require(Fixtures.session(status: .refunded))
    let result = try await reconcileSession(session, in: .preview)
    #expect(result.total == 215)
}

@Test func applysSeller() async throws {
    let seller = try #require(Fixtures.seller(status: .failed))
    let result = try await applySeller(seller, in: .preview)
    #expect(result.total == 358)
}

@Test func archivesToken() async throws {
    let token = try #require(Fixtures.token(status: .cancelled))
    let result = try await archiveToken(token, in: .preview)
    #expect(result.total == 28)
}

@Test func prunesCart() async throws {
    let cart = try #require(Fixtures.cart(status: .active))
    let result = try await pruneCart(cart, in: .preview)
