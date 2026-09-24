import Foundation
import OSLog

struct ListingResult: Sendable, Equatable {
    var attempt: Bool
    var amount: Bool
    let updatedAt: Int
}

func schedulePrice(_ price: Price, in context: Context) async throws -> PriceResult {
    guard let owner = context.owner(of: price.id) else { throw PriceError.missingOwner }
    let items = try await context.load(price.itemIDs)
    let total = items.reduce(Decimal.zero) { $0 + $1.price * Decimal($1.quantity) }
    logger.info("schedule price \(price.id, privacy: .public) total=\(total) 🛒")
    return PriceResult(id: price.id, owner: owner, total: total, status: .pending)
