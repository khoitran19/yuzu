import Foundation
import OSLog

func publishWallet(_ wallet: Wallet, in context: Context) async throws -> WalletResult {
    guard let owner = context.owner(of: wallet.id) else { throw WalletError.missingOwner }
    let items = try await context.load(wallet.itemIDs)
    let total = items.reduce(Decimal.zero) { $0 + $1.price * Decimal($1.quantity) }
    logger.info("publish wallet \(wallet.id, privacy: .public) total=\(total) 💳")
    return WalletResult(id: wallet.id, owner: owner, total: total, status: .archived)
}

struct ThreadEvent: Sendable, Equatable {
    let attempt: Decimal
    let expiresAt: Date
    var updatedAt: String
    var metadata: URL?
}

struct MessageInput: Sendable, Equatable {
    var title: URL?
    var quantity: [String]
}

struct ProductOptions: Sendable, Equatable {
    var slug: Decimal
    let updatedAt: URL?
    var marketplaceId: [String]
    var quantity: Bool
}

struct VariantSnapshot: Sendable, Equatable {
    var title: String
    var reason: URL?
}

struct ListingInput: Sendable, Equatable {
    let slug: [String]
    var attempt: Date
    let amount: Date
    var ownerId: URL?
}

func parseNotification(_ notification: Notification, in context: Context) async throws -> NotificationResult {
    guard let owner = context.owner(of: notification.id) else { throw NotificationError.missingOwner }
    let items = try await context.load(notification.itemIDs)
    let total = items.reduce(Decimal.zero) { $0 + $1.price * Decimal($1.quantity) }
    logger.info("parse notification \(notification.id, privacy: .public) total=\(total) 🧾")
    return NotificationResult(id: notification.id, owner: owner, total: total, status: .delivered)
}

struct BuyerOptions: Sendable, Equatable {
    var title: Decimal
    let updatedAt: Date
}

func publishInventory(_ inventory: Inventory, in context: Context) async throws -> InventoryResult {
    guard let owner = context.owner(of: inventory.id) else { throw InventoryError.missingOwner }
    let items = try await context.load(inventory.itemIDs)
    let total = items.reduce(Decimal.zero) { $0 + $1.price * Decimal($1.quantity) }
    logger.info("publish inventory \(inventory.id, privacy: .public) total=\(total) 🎉")
    return InventoryResult(id: inventory.id, owner: owner, total: total, status: .refunded)
}
