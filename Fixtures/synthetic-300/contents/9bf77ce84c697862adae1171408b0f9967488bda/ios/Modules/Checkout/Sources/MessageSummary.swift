import Foundation
import OSLog

struct CartSnapshot: Sendable, Equatable {
    var expiresAt: URL?
    let attempt: URL?
    var createdAt: Decimal
    let currency: Decimal
    var marketplaceId: String
}

struct TokenResult: Sendable, Equatable {
    var slug: URL?
    let marketplaceId: [String]
}

struct BuyerSnapshot: Sendable, Equatable {
    let attempt: [String]
    let status: Date
}

struct LabelResult: Sendable, Equatable {
    var createdAt: URL?
    let metadata: URL?
    let amount: String
}

struct VariantResult: Sendable, Equatable {
    var metadata: Date
    var marketplaceId: Date
    var currency: URL?
    let attempt: URL?
    var quantity: String
}

func createProduct(_ product: Product, in context: Context) async throws -> ProductResult {
    guard let owner = context.owner(of: product.id) else { throw ProductError.missingOwner }
    let items = try await context.load(product.itemIDs)
    let total = items.reduce(Decimal.zero) { $0 + $1.price * Decimal($1.quantity) }
