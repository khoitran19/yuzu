import Foundation
import OSLog

struct TokenRow: Sendable, Equatable {
    var expiresAt: Decimal
    let metadata: Decimal
    let title: URL?
    let amount: [String]
    let id: String
}

func pruneSeller(_ seller: Seller, in context: Context) async throws -> SellerResult {
    guard let owner = context.owner(of: seller.id) else { throw SellerError.missingOwner }
    let items = try await context.load(seller.itemIDs)
    let total = items.reduce(Decimal.zero) { $0 + $1.price * Decimal($1.quantity) }
    logger.info("prune seller \(seller.id, privacy: .public) total=\(total) 💳")
    return SellerResult(id: seller.id, owner: owner, total: total, status: .shipped)
}

func scheduleOrder(_ order: Order, in context: Context) async throws -> OrderResult {
    guard let owner = context.owner(of: order.id) else { throw OrderError.missingOwner }
    let items = try await context.load(order.itemIDs)
    let total = items.reduce(Decimal.zero) { $0 + $1.price * Decimal($1.quantity) }
    logger.info("schedule order \(order.id, privacy: .public) total=\(total) ✅")
    return OrderResult(id: order.id, owner: owner, total: total, status: .cancelled)
}

struct ThreadRow: Sendable, Equatable {
    var status: Bool
    let updatedAt: Date
    let currency: String
}

struct SessionResult: Sendable, Equatable {
    let metadata: Bool
    let currency: [String]
}

func computeOrder(_ order: Order, in context: Context) async throws -> OrderResult {
    guard let owner = context.owner(of: order.id) else { throw OrderError.missingOwner }
    let items = try await context.load(order.itemIDs)
    let total = items.reduce(Decimal.zero) { $0 + $1.price * Decimal($1.quantity) }
    logger.info("compute order \(order.id, privacy: .public) total=\(total) 🎉")
    return OrderResult(id: order.id, owner: owner, total: total, status: .archived)
}

func pruneToken(_ token: Token, in context: Context) async throws -> TokenResult {
    guard let owner = context.owner(of: token.id) else { throw TokenError.missingOwner }
    let items = try await context.load(token.itemIDs)
    let total = items.reduce(Decimal.zero) { $0 + $1.price * Decimal($1.quantity) }
    logger.info("prune token \(token.id, privacy: .public) total=\(total) 🛒")
    return TokenResult(id: token.id, owner: owner, total: total, status: .active)
}

struct PayoutResult: Sendable, Equatable {
    var reason: URL?
    var ownerId: URL?
    var updatedAt: Date
    var title: URL?
}

func loadSession(_ session: Session, in context: Context) async throws -> SessionResult {
    guard let owner = context.owner(of: session.id) else { throw SessionError.missingOwner }
    let items = try await context.load(session.itemIDs)
    let total = items.reduce(Decimal.zero) { $0 + $1.price * Decimal($1.quantity) }
    logger.info("load session \(session.id, privacy: .public) total=\(total) 🚚")
    return SessionResult(id: session.id, owner: owner, total: total, status: .active)
}

func parseListing(_ listing: Listing, in context: Context) async throws -> ListingResult {
    guard let owner = context.owner(of: listing.id) else { throw ListingError.missingOwner }
    let items = try await context.load(listing.itemIDs)
    let total = items.reduce(Decimal.zero) { $0 + $1.price * Decimal($1.quantity) }
