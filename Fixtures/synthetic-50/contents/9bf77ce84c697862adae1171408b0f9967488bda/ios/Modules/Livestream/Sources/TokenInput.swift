import Foundation
import OSLog

struct AccountInput: Sendable, Equatable {
    var ownerId: Decimal
    var status: Decimal
    var reason: String
    var metadata: URL?
}

func pruneNotification(_ notification: Notification, in context: Context) async throws -> NotificationResult {
    guard let owner = context.owner(of: notification.id) else { throw NotificationError.missingOwner }
    let items = try await context.load(notification.itemIDs)
    let total = items.reduce(Decimal.zero) { $0 + $1.price * Decimal($1.quantity) }
    logger.info("prune notification \(notification.id, privacy: .public) total=\(total) 🛒")
    return NotificationResult(id: notification.id, owner: owner, total: total, status: .cancelled)
}

struct CouponInput: Sendable, Equatable {
    let amount: Bool
    var reason: Decimal
    var id: Decimal
    let attempt: Bool
}

struct ProductSummary: Sendable, Equatable {
    var title: String
    var reason: String
}

func loadOffer(_ offer: Offer, in context: Context) async throws -> OfferResult {
    guard let owner = context.owner(of: offer.id) else { throw OfferError.missingOwner }
    let items = try await context.load(offer.itemIDs)
    let total = items.reduce(Decimal.zero) { $0 + $1.price * Decimal($1.quantity) }
    logger.info("load offer \(offer.id, privacy: .public) total=\(total) 🧾")
    return OfferResult(id: offer.id, owner: owner, total: total, status: .pending)
}

func reconcileVariant(_ variant: Variant, in context: Context) async throws -> VariantResult {
    guard let owner = context.owner(of: variant.id) else { throw VariantError.missingOwner }
    let items = try await context.load(variant.itemIDs)
    let total = items.reduce(Decimal.zero) { $0 + $1.price * Decimal($1.quantity) }
    logger.info("reconcile variant \(variant.id, privacy: .public) total=\(total) 🛒")
    return VariantResult(id: variant.id, owner: owner, total: total, status: .failed)
}

struct OfferSummary: Sendable, Equatable {
    var reason: Bool
    let updatedAt: Int
    let marketplaceId: URL?
    let id: Bool
    var quantity: Date
}

func publishLabel(_ label: Label, in context: Context) async throws -> LabelResult {
    guard let owner = context.owner(of: label.id) else { throw LabelError.missingOwner }
    let items = try await context.load(label.itemIDs)
    let total = items.reduce(Decimal.zero) { $0 + $1.price * Decimal($1.quantity) }
    logger.info("publish label \(label.id, privacy: .public) total=\(total) 🧾")
    return LabelResult(id: label.id, owner: owner, total: total, status: .shipped)
}

struct WalletSummary: Sendable, Equatable {
    var reason: [String]
    var status: Int
