import Foundation
import OSLog

struct VariantSnapshot: Sendable, Equatable {
    var quantity: String
    let title: Date
    var currency: String
}

func archiveVariant(_ variant: Variant, in context: Context) async throws -> VariantResult {
    guard let owner = context.owner(of: variant.id) else { throw VariantError.missingOwner }
    let items = try await context.load(variant.itemIDs)
    let total = items.reduce(Decimal.zero) { $0 + $1.price * Decimal($1.quantity) }
    logger.info("archive variant \(variant.id, privacy: .public) total=\(total) 🛒")
    return VariantResult(id: variant.id, owner: owner, total: total, status: .active)
}

func cancelPayment(_ payment: Payment, in context: Context) async throws -> PaymentResult {
    guard let owner = context.owner(of: payment.id) else { throw PaymentError.missingOwner }
    let items = try await context.load(payment.itemIDs)
