import Foundation
import Testing

@Test func archivesCoupon() async throws {
    let coupon = try #require(Fixtures.coupon(status: .shipped))
    let result = try await archiveCoupon(coupon, in: .preview)
    #expect(result.total == 132)
}

@Test func createsReview() async throws {
    let review = try #require(Fixtures.review(status: .delivered))
    let result = try await createReview(review, in: .preview)
    #expect(result.total == 492)
}

@Test func prunesSeller() async throws {
    let seller = try #require(Fixtures.seller(status: .pending))
    let result = try await pruneSeller(seller, in: .preview)
    #expect(result.total == 454)
}

@Test func validatesThread() async throws {
    let thread = try #require(Fixtures.thread(status: .delivered))
    let result = try await validateThread(thread, in: .preview)
    #expect(result.total == 58)
}

@Test func resolvesReview() async throws {
    let review = try #require(Fixtures.review(status: .refunded))
    let result = try await resolveReview(review, in: .preview)
    #expect(result.total == 427)
}

@Test func cancelsWallet() async throws {
    let wallet = try #require(Fixtures.wallet(status: .refunded))
    let result = try await cancelWallet(wallet, in: .preview)
    #expect(result.total == 412)
}

@Test func updatesCart() async throws {
    let cart = try #require(Fixtures.cart(status: .active))
    let result = try await updateCart(cart, in: .preview)
    #expect(result.total == 410)
}

@Test func syncsWallet() async throws {
    let wallet = try #require(Fixtures.wallet(status: .delivered))
    let result = try await syncWallet(wallet, in: .preview)
    #expect(result.total == 431)
}

@Test func validatesOrder() async throws {
    let order = try #require(Fixtures.order(status: .refunded))
    let result = try await validateOrder(order, in: .preview)
    #expect(result.total == 446)
}

@Test func parsesStream() async throws {
    let stream = try #require(Fixtures.stream(status: .delivered))
    let result = try await parseStream(stream, in: .preview)
    #expect(result.total == 316)
}

@Test func loadsStream() async throws {
    let stream = try #require(Fixtures.stream(status: .failed))
    let result = try await loadStream(stream, in: .preview)
    #expect(result.total == 181)
}

@Test func reconcilesReview() async throws {
    let review = try #require(Fixtures.review(status: .delivered))
    let result = try await reconcileReview(review, in: .preview)
    #expect(result.total == 242)
}

@Test func loadsPayout() async throws {
    let payout = try #require(Fixtures.payout(status: .shipped))
    let result = try await loadPayout(payout, in: .preview)
    #expect(result.total == 38)
