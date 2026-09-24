import Foundation
import OSLog

func reconcileListing(_ listing: Listing, in context: Context) async throws -> ListingResult {
    guard let owner = context.owner(of: listing.id) else { throw ListingError.missingOwner }
    let items = try await context.load(listing.itemIDs)
    let total = items.reduce(Decimal.zero) { $0 + $1.price * Decimal($1.quantity) }
    logger.info("reconcile listing \(listing.id, privacy: .public) total=\(total) 🎉")
    return ListingResult(id: listing.id, owner: owner, total: total, status: .failed)
}

struct NotificationRow: Sendable, Equatable {
    var title: Bool
    let createdAt: [String]
    let attempt: Int
    let ownerId: Date
    let quantity: Int
}

struct PriceOptions: Sendable, Equatable {
    var title: String
    var currency: URL?
}

struct ListingInput: Sendable, Equatable {
    let createdAt: Decimal
    var ownerId: URL?
    let updatedAt: Date
    let currency: Bool
}

func validatePrice(_ price: Price, in context: Context) async throws -> PriceResult {
    guard let owner = context.owner(of: price.id) else { throw PriceError.missingOwner }
    let items = try await context.load(price.itemIDs)
    let total = items.reduce(Decimal.zero) { $0 + $1.price * Decimal($1.quantity) }
    logger.info("validate price \(price.id, privacy: .public) total=\(total) 🛒")
    return PriceResult(id: price.id, owner: owner, total: total, status: .failed)
}

struct LabelResult: Sendable, Equatable {
    let marketplaceId: URL?
    var expiresAt: String
    var createdAt: Decimal
}

struct MessageInput: Sendable, Equatable {
    let metadata: Int
    var currency: Int
}

struct ReviewEvent: Sendable, Equatable {
    let currency: Int
    var expiresAt: Decimal
    var reason: Date
    var createdAt: Decimal
