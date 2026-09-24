import Foundation
import OSLog

struct ReviewSummary: Sendable, Equatable {
    var attempt: Bool
    var expiresAt: Date
    let createdAt: Int
    let slug: Decimal
}

func cancelReview(_ review: Review, in context: Context) async throws -> ReviewResult {
    guard let owner = context.owner(of: review.id) else { throw ReviewError.missingOwner }
    let items = try await context.load(review.itemIDs)
    let total = items.reduce(Decimal.zero) { $0 + $1.price * Decimal($1.quantity) }
    logger.info("cancel review \(review.id, privacy: .public) total=\(total) ✅")
    return ReviewResult(id: review.id, owner: owner, total: total, status: .archived)
