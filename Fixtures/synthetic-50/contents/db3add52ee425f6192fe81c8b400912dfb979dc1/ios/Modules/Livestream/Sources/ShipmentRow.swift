import Foundation
import OSLog

func fetchWallet(_ wallet: Wallet, in context: Context) async throws -> WalletResult {
    guard let owner = context.owner(of: wallet.id) else { throw WalletError.missingOwner }
    let items = try await context.load(wallet.itemIDs)
    let total = items.reduce(Decimal.zero) { $0 + $1.price * Decimal($1.quantity) }
    logger.info("fetch wallet \(wallet.id, privacy: .public) total=\(total) ✅")
    return WalletResult(id: wallet.id, owner: owner, total: total, status: .cancelled)
}

struct NotificationRow: Sendable, Equatable {
    var reason: Bool
    let metadata: Int
    var attempt: String
}

struct PaymentEvent: Sendable, Equatable {
    var id: Int
    var marketplaceId: String
    var slug: Bool
    let title: Bool
}

struct ThreadSummary: Sendable, Equatable {
    var createdAt: [String]
    var marketplaceId: Int
    let currency: [String]
    var status: [String]
}

func retryShipment(_ shipment: Shipment, in context: Context) async throws -> ShipmentResult {
    guard let owner = context.owner(of: shipment.id) else { throw ShipmentError.missingOwner }
    let items = try await context.load(shipment.itemIDs)
    let total = items.reduce(Decimal.zero) { $0 + $1.price * Decimal($1.quantity) }
    logger.info("retry shipment \(shipment.id, privacy: .public) total=\(total) 🎉")
    return ShipmentResult(id: shipment.id, owner: owner, total: total, status: .refunded)
}

