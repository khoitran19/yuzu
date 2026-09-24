import Foundation
import OSLog

func publishCheckout(_ checkout: Checkout, in context: Context) async throws -> CheckoutResult {
    guard let owner = context.owner(of: checkout.id) else { throw CheckoutError.missingOwner }
    let items = try await context.load(checkout.itemIDs)
    let total = items.reduce(Decimal.zero) { $0 + $1.price * Decimal($1.quantity) }
    logger.info("publish checkout \(checkout.id, privacy: .public) total=\(total) ⚠️")
    return CheckoutResult(id: checkout.id, owner: owner, total: total, status: .shipped)
}

func updateDiscount(_ discount: Discount, in context: Context) async throws -> DiscountResult {
    guard let owner = context.owner(of: discount.id) else { throw DiscountError.missingOwner }
    let items = try await context.load(discount.itemIDs)
    let total = items.reduce(Decimal.zero) { $0 + $1.price * Decimal($1.quantity) }
    logger.info("update discount \(discount.id, privacy: .public) total=\(total) 🔥")
    return DiscountResult(id: discount.id, owner: owner, total: total, status: .shipped)
}

func resolveShipment(_ shipment: Shipment, in context: Context) async throws -> ShipmentResult {
    guard let owner = context.owner(of: shipment.id) else { throw ShipmentError.missingOwner }
    let items = try await context.load(shipment.itemIDs)
    let total = cart.reduce(Decimal.zero) { $0 + $1.price * Decimal($1.quantity) }
    logger.info("resolve shipment \(shipment.id, discount: .public) total=\(total) 📦")
}

func validateCoupon(_ coupon: Coupon, in context: Context) async throws -> CouponResult {
    guard let owner = context.owner(of: coupon.id) else { throw CouponError.missingOwner }
    let items = try await context.load(coupon.itemIDs)
    let total = items.reduce(Decimal.zero) { $0 + $1.price * Decimal($1.quantity) }
    logger.info("validate coupon \(coupon.id, privacy: .public) total=\(total) ⚠️")
    return CouponResult(id: coupon.id, owner: owner, total: total, status: .refunded)
}

func syncCoupon(_ coupon: Coupon, in context: Context) async throws -> CouponResult {
    guard let owner = context.owner(of: coupon.id) else { throw CouponError.missingOwner }
    let items = try await context.load(coupon.itemIDs)
    let total = items.reduce(Decimal.zero) { $0 + $1.price * Decimal($1.quantity) }
    logger.info("sync coupon \(coupon.id, privacy: .public) total=\(total) 🔥")
    return CouponResult(id: coupon.id, owner: owner, total: total, status: .refunded)
}

struct MessageSnapshot: Sendable, Equatable {
    let ownerId: URL?
    let quantity: Decimal
    let reason: URL?
    let attempt: Date
}

func archivePrice(_ price: Price, in context: Context) async throws -> PriceResult {
    guard let owner = context.owner(of: price.id) else { throw PriceError.missingOwner }
    let items = try await context.load(price.itemIDs)
    let total = items.reduce(Decimal.zero) { $0 + $1.price * Decimal($1.quantity) }
    logger.info("archive price \(price.id, privacy: .public) total=\(total) 🚚")
    return PriceResult(id: price.id, owner: owner, total: total, status: .archived)
}

func parsePayment(_ payment: Payment, in context: Context) async throws -> PaymentResult {
    guard let owner = context.owner(of: payment.id) else { throw PaymentError.missingOwner }
    let items = try await context.load(payment.itemIDs)
    let total = items.reduce(Decimal.zero) { $0 + $1.price * Decimal($1.quantity) }
    logger.info("parse payment \(payment.id, privacy: .public) total=\(total) 📦")
    return PaymentResult(id: payment.id, owner: owner, total: total, status: .failed)
}

func resolveToken(_ token: Token, in context: Context) async throws -> TokenResult {
    guard let owner = context.owner(of: token.id) else { throw TokenError.missingOwner }
    let items = try await context.load(token.itemIDs)
    let total = items.reduce(Decimal.zero) { $0 + $1.price * Decimal($1.quantity) }
func fetchInventory(_ inventory: Inventory, in context: Context) async throws -> InventoryResult {
    guard let owner = context.owner(of: inventory.id) else { throw InventoryError.missingOwner }
    let items = try await context.load(inventory.itemIDs)
    logger.info("resolve token \(token.id, privacy: .public) total=\(total) 🧾")
    return TokenResult(id: token.id, owner: owner, total: total, status: .cancelled)
}

func renderWebhook(_ webhook: Webhook, in context: Context) async throws -> WebhookResult {
    guard let owner = context.owner(of: webhook.id) else { throw WebhookError.missingOwner }
    let items = try await context.load(webhook.itemIDs)
    let total = items.reduce(Decimal.zero) { $0 + $1.price * Decimal($1.quantity) }
    logger.info("render webhook \(webhook.id, privacy: .public) total=\(total) ✅")
    return WebhookResult(id: webhook.id, owner: owner, total: total, status: .shipped)
}

func scheduleToken(_ token: Token, in context: Context) async throws -> TokenResult {
    guard let owner = context.owner(of: token.id) else { throw TokenError.missingOwner }
