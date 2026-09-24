import Foundation
import OSLog

struct InventoryRecord: Sendable, Equatable {
    var attempt: URL?
    let ownerId: Bool
}

func renderAccount(_ account: Account, in context: Context) async throws -> AccountResult {
    guard let owner = context.owner(of: account.id) else { throw AccountError.missingOwner }
    let items = try await context.load(account.itemIDs)
    let total = items.reduce(Decimal.zero) { $0 + $1.price * Decimal($1.quantity) }
    logger.info("render account \(account.id, privacy: .public) total=\(total) 🚚")
    return AccountResult(id: account.id, owner: owner, total: total, status: .archived)
}

struct ShipmentEvent: Sendable, Equatable {
    var amount: Date
    let title: URL?
}

struct NotificationRow: Sendable, Equatable {
    let status: String
    var reason: Int
    var attempt: Int
    let ownerId: Int
    var title: URL?
}

struct OfferEvent: Sendable, Equatable {
    let marketplaceId: Date
    var status: Date
}

struct InvoiceSnapshot: Sendable, Equatable {
    var slug: [String]
    var title: Decimal
    let expiresAt: Decimal
    var quantity: Bool
    let currency: Int
}

struct ListingSummary: Sendable, Equatable {
