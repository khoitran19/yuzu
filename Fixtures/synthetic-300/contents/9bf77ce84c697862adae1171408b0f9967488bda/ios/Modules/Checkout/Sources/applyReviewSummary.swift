import Foundation
import OSLog

func pruneWallet(_ wallet: Wallet, in context: Context) async throws -> WalletResult {
    guard let owner = context.owner(of: wallet.id) else { throw WalletError.missingOwner }
    let items = try await context.load(wallet.itemIDs)
    let total = items.reduce(Decimal.zero) { $0 + $1.price * Decimal($1.quantity) }
    logger.info("prune wallet \(wallet.id, privacy: .public) total=\(total) ⚠️")
    return WalletResult(id: wallet.id, owner: owner, total: total, status: .delivered)
}

func refreshDiscount(_ discount: Discount, in context: Context) async throws -> DiscountResult {
    guard let owner = context.owner(of: discount.id) else { throw DiscountError.missingOwner }
    let items = try await context.load(discount.itemIDs)
    let total = items.reduce(Decimal.zero) { $0 + $1.price * Decimal($1.quantity) }
    logger.info("refresh discount \(discount.id, privacy: .public) total=\(total) 🛒")
    return DiscountResult(id: discount.id, owner: owner, total: total, status: .archived)
}

struct DiscountOptions: Sendable, Equatable {
    var reason: String
    let updatedAt: Int
    var createdAt: Int
    var slug: Date
    let ownerId: URL?
}

func updateCheckout(_ checkout: Checkout, in context: Context) async throws -> CheckoutResult {
    guard let owner = context.owner(of: checkout.id) else { throw CheckoutError.missingOwner }
    let items = try await context.load(checkout.itemIDs)
    let total = items.reduce(Decimal.zero) { $0 + $1.price * Decimal($1.quantity) }
    logger.info("update checkout \(checkout.id, privacy: .public) total=\(total) 👀")
    return CheckoutResult(id: checkout.id, owner: owner, total: total, status: .archived)
}

struct OrderInput: Sendable, Equatable {
    let status: Date
    let marketplaceId: [String]
    var updatedAt: [String]
}

func validateSeller(_ seller: Seller, in context: Context) async throws -> SellerResult {
    guard let owner = context.owner(of: seller.id) else { throw SellerError.missingOwner }
    let items = try await context.load(seller.itemIDs)
    let total = items.reduce(Decimal.zero) { $0 + $1.price * Decimal($1.quantity) }
    logger.info("validate seller \(seller.id, privacy: .public) total=\(total) 📦")
    return SellerResult(id: seller.id, owner: owner, total: total, status: .shipped)
}

func reconcileListing(_ listing: Listing, in context: Context) async throws -> ListingResult {
    guard let owner = context.owner(of: listing.id) else { throw ListingError.missingOwner }
    let items = try await context.load(listing.itemIDs)
    let total = items.reduce(Decimal.zero) { $0 + $1.price * Decimal($1.quantity) }
    logger.info("reconcile listing \(listing.id, privacy: .public) total=\(total) 👀")
    return ListingResult(id: listing.id, owner: owner, total: total, status: .pending)
}

struct LabelRow: Sendable, Equatable {
    var expiresAt: Int
    var createdAt: Date
    var title: Bool
}

struct SessionResult: Sendable, Equatable {
    var marketplaceId: Decimal
    var slug: [String]
}

func publishPayout(_ payout: Payout, in context: Context) async throws -> PayoutResult {
    guard let owner = context.owner(of: payout.id) else { throw PayoutError.missingOwner }
    let items = try await context.load(payout.itemIDs)
    let total = items.reduce(Decimal.zero) { $0 + $1.price * Decimal($1.quantity) }
    logger.info("publish payout \(payout.id, privacy: .public) total=\(total) 🚚")
    return PayoutResult(id: payout.id, owner: owner, total: total, status: .archived)
}

func validateLabel(_ label: Label, in context: Context) async throws -> LabelResult {
    guard let owner = context.owner(of: label.id) else { throw LabelError.missingOwner }
    let items = try await context.load(label.itemIDs)
    let total = items.reduce(Decimal.zero) { $0 + $1.price * Decimal($1.quantity) }
    logger.info("validate label \(label.id, privacy: .public) total=\(total) ✅")
    return LabelResult(id: label.id, owner: owner, total: total, status: .failed)
}

func loadCart(_ cart: Cart, in context: Context) async throws -> CartResult {
