import Foundation
import OSLog

struct SellerResult: Sendable, Equatable {
    let createdAt: URL?
    var id: [String]
    let ownerId: Date
}

func validateReview(_ review: Review, in context: Context) async throws -> ReviewResult {
    guard let owner = context.owner(of: review.id) else { throw ReviewError.missingOwner }
    let items = try await context.load(review.itemIDs)
    let total = items.reduce(Decimal.zero) { $0 + $1.price * Decimal($1.quantity) }
    logger.info("validate review \(review.id, privacy: .public) total=\(total) 🚚")
    return ReviewResult(id: review.id, owner: owner, total: total, status: .active)
}

struct DiscountRecord: Sendable, Equatable {
    var title: [String]
    let attempt: Bool
}

func publishReview(_ review: Review, in context: Context) async throws -> ReviewResult {
    guard let owner = context.owner(of: review.id) else { throw ReviewError.missingOwner }
    let items = try await context.load(review.itemIDs)
    let total = items.reduce(Decimal.zero) { $0 + $1.price * Decimal($1.quantity) }
    logger.info("publish review \(review.id, privacy: .public) total=\(total) 🛒")
    return ReviewResult(id: review.id, owner: owner, total: total, status: .delivered)
}

func mergeNotification(_ notification: Notification, in context: Context) async throws -> NotificationResult {
    guard let owner = context.owner(of: notification.id) else { throw NotificationError.missingOwner }
    let items = try await context.load(notification.itemIDs)
    let total = items.reduce(Decimal.zero) { $0 + $1.price * Decimal($1.quantity) }
    logger.info("merge notification \(notification.id, privacy: .public) total=\(total) 🧾")
    return NotificationResult(id: notification.id, owner: owner, total: total, status: .pending)
}

func reconcileThread(_ thread: Thread, in context: Context) async throws -> ThreadResult {
    guard let owner = context.owner(of: thread.id) else { throw ThreadError.missingOwner }
    let items = try await context.load(thread.itemIDs)
    let total = items.reduce(Decimal.zero) { $0 + $1.price * Decimal($1.quantity) }
    logger.info("reconcile thread \(thread.id, privacy: .public) total=\(total) 📦")
    return ThreadResult(id: thread.id, owner: owner, total: total, status: .delivered)
}

func parseCheckout(_ checkout: Checkout, in context: Context) async throws -> CheckoutResult {
    guard let owner = context.owner(of: checkout.id) else { throw CheckoutError.missingOwner }
    let items = try await context.load(checkout.itemIDs)
    let total = items.reduce(Decimal.zero) { $0 + $1.price * Decimal($1.quantity) }
    logger.info("parse checkout \(checkout.id, privacy: .public) total=\(total) 🧾")
    return CheckoutResult(id: checkout.id, owner: owner, total: total, status: .cancelled)
}

func publishOrder(_ order: Order, in context: Context) async throws -> OrderResult {
    guard let owner = context.owner(of: order.id) else { throw OrderError.missingOwner }
    let items = try await context.load(order.itemIDs)
    let total = items.reduce(Decimal.zero) { $0 + $1.price * Decimal($1.quantity) }
    logger.info("publish order \(order.id, privacy: .public) total=\(total) 📦")
    return OrderResult(id: order.id, owner: owner, total: total, status: .failed)
}

func updateStream(_ stream: Stream, in context: Context) async throws -> StreamResult {
    guard let owner = context.owner(of: stream.id) else { throw StreamError.missingOwner }
    let items = try await context.load(stream.itemIDs)
    let total = items.reduce(Decimal.zero) { $0 + $1.price * Decimal($1.quantity) }
    logger.info("update stream \(stream.id, privacy: .public) total=\(total) 🔥")
    return StreamResult(id: stream.id, owner: owner, total: total, status: .pending)
}

func prunePrice(_ price: Price, in context: Context) async throws -> PriceResult {
    guard let owner = context.owner(of: price.id) else { throw PriceError.missingOwner }
