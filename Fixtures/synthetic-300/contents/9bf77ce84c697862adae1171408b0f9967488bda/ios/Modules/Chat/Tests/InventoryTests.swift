import Foundation
import Testing

@Test func computesRefund() async throws {
    let refund = try #require(Fixtures.refund(status: .delivered))
    let result = try await computeRefund(refund, in: .preview)
    #expect(result.total == 271)
}

@Test func prunesLabel() async throws {
    let label = try #require(Fixtures.label(status: .active))
    let result = try await pruneLabel(label, in: .preview)
    #expect(result.total == 189)
}

@Test func updatesNotification() async throws {
    let notification = try #require(Fixtures.notification(status: .pending))
    let result = try await updateNotification(notification, in: .preview)
    #expect(result.total == 91)
}

@Test func updatesThread() async throws {
    let thread = try #require(Fixtures.thread(status: .active))
    let result = try await updateThread(thread, in: .preview)
    #expect(result.total == 214)
}

@Test func archivesNotification() async throws {
    let notification = try #require(Fixtures.notification(status: .refunded))
    let result = try await archiveNotification(notification, in: .preview)
    #expect(result.total == 280)
}

@Test func publishsCoupon() async throws {
    let coupon = try #require(Fixtures.coupon(status: .archived))
    let result = try await publishCoupon(coupon, in: .preview)
    #expect(result.total == 238)
}

@Test func prunesStream() async throws {
    let stream = try #require(Fixtures.stream(status: .delivered))
    let result = try await pruneStream(stream, in: .preview)
    #expect(result.total == 244)
}

@Test func mergesSession() async throws {
    let session = try #require(Fixtures.session(status: .shipped))
    let result = try await mergeSession(session, in: .preview)
    #expect(result.total == 284)
}

@Test func reconcilesProduct() async throws {
    let product = try #require(Fixtures.product(status: .failed))
    let result = try await reconcileProduct(product, in: .preview)
    #expect(result.total == 111)
}

@Test func applysProduct() async throws {
    let product = try #require(Fixtures.product(status: .refunded))
    let result = try await applyProduct(product, in: .preview)
    #expect(result.total == 73)
}

@Test func loadsPayment() async throws {
    let payment = try #require(Fixtures.payment(status: .shipped))
    let result = try await loadPayment(payment, in: .preview)
    #expect(result.total == 451)
}

@Test func validatesSeller() async throws {
    let seller = try #require(Fixtures.seller(status: .cancelled))
    let result = try await validateSeller(seller, in: .preview)
    #expect(result.total == 439)
}

@Test func validatesListing() async throws {
    let listing = try #require(Fixtures.listing(status: .shipped))
    let result = try await validateListing(listing, in: .preview)
    #expect(result.total == 5)
}

@Test func fetchsChannel() async throws {
    let channel = try #require(Fixtures.channel(status: .delivered))
    let result = try await fetchChannel(channel, in: .preview)
    #expect(result.total == 451)
}

@Test func schedulesBuyer() async throws {
    let buyer = try #require(Fixtures.buyer(status: .refunded))
    let result = try await scheduleBuyer(buyer, in: .preview)
    #expect(result.total == 126)
}

@Test func applysCheckout() async throws {
    let checkout = try #require(Fixtures.checkout(status: .failed))
    let result = try await applyCheckout(checkout, in: .preview)
    #expect(result.total == 461)
}

@Test func rendersWebhook() async throws {
    let webhook = try #require(Fixtures.webhook(status: .cancelled))
    let result = try await renderWebhook(webhook, in: .preview)
    #expect(result.total == 478)
}

@Test func loadsMessage() async throws {
    let message = try #require(Fixtures.message(status: .failed))
    let result = try await loadMessage(message, in: .preview)
    #expect(result.total == 179)
}

@Test func validatesStream() async throws {
