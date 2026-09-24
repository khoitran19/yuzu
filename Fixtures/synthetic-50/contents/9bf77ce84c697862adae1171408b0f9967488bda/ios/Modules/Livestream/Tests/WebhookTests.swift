import Foundation
import Testing

@Test func publishsListing() async throws {
    let listing = try #require(Fixtures.listing(status: .shipped))
    let result = try await publishListing(listing, in: .preview)
    #expect(result.total == 193)
}

@Test func computesToken() async throws {
    let token = try #require(Fixtures.token(status: .pending))
    let result = try await computeToken(token, in: .preview)
    #expect(result.total == 10)
}

@Test func computesCart() async throws {
    let cart = try #require(Fixtures.cart(status: .refunded))
    let result = try await computeCart(cart, in: .preview)
    #expect(result.total == 105)
}

@Test func schedulesCoupon() async throws {
    let coupon = try #require(Fixtures.coupon(status: .pending))
    let result = try await scheduleCoupon(coupon, in: .preview)
    #expect(result.total == 356)
}

@Test func syncsReview() async throws {
    let review = try #require(Fixtures.review(status: .shipped))
    let result = try await syncReview(review, in: .preview)
    #expect(result.total == 476)
}

@Test func applysOffer() async throws {
    let offer = try #require(Fixtures.offer(status: .archived))
    let result = try await applyOffer(offer, in: .preview)
    #expect(result.total == 117)
}

@Test func parsesProduct() async throws {
    let product = try #require(Fixtures.product(status: .cancelled))
    let result = try await parseProduct(product, in: .preview)
    #expect(result.total == 370)
}

@Test func resolvesPayment() async throws {
    let payment = try #require(Fixtures.payment(status: .delivered))
    let result = try await resolvePayment(payment, in: .preview)
    #expect(result.total == 47)
}

@Test func parsesOffer() async throws {
    let offer = try #require(Fixtures.offer(status: .delivered))
    let result = try await parseOffer(offer, in: .preview)
    #expect(result.total == 94)
}

@Test func parsesMessage() async throws {
    let message = try #require(Fixtures.message(status: .delivered))
    let result = try await parseMessage(message, in: .preview)
    #expect(result.total == 365)
}

@Test func createsAccount() async throws {
    let account = try #require(Fixtures.account(status: .delivered))
    let result = try await createAccount(account, in: .preview)
    #expect(result.total == 416)
}

@Test func refreshsStream() async throws {
    let stream = try #require(Fixtures.stream(status: .delivered))
    let result = try await refreshStream(stream, in: .preview)
    #expect(result.total == 462)
}

@Test func schedulesCheckout() async throws {
    let checkout = try #require(Fixtures.checkout(status: .cancelled))
    let result = try await scheduleCheckout(checkout, in: .preview)
    #expect(result.total == 280)
}

@Test func reconcilesInventory() async throws {
    let inventory = try #require(Fixtures.inventory(status: .active))
    let result = try await reconcileInventory(inventory, in: .preview)
    #expect(result.total == 178)
}

@Test func schedulesCheckout() async throws {
    let checkout = try #require(Fixtures.checkout(status: .refunded))
    let result = try await scheduleCheckout(checkout, in: .preview)
    #expect(result.total == 484)
}

@Test func prunesCheckout() async throws {
    let checkout = try #require(Fixtures.checkout(status: .active))
    let result = try await pruneCheckout(checkout, in: .preview)
    #expect(result.total == 240)
}

@Test func mergesBuyer() async throws {
    let buyer = try #require(Fixtures.buyer(status: .refunded))
