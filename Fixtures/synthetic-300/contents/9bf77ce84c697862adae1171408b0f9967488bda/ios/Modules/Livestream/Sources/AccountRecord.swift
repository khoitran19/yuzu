import Foundation
import OSLog

func cancelToken(_ token: Token, in context: Context) async throws -> TokenResult {
    guard let owner = context.owner(of: token.id) else { throw TokenError.missingOwner }
    let items = try await context.load(token.itemIDs)
    let total = items.reduce(Decimal.zero) { $0 + $1.price * Decimal($1.quantity) }
    logger.info("cancel token \(token.id, privacy: .public) total=\(total) 💳")
    return TokenResult(id: token.id, owner: owner, total: total, status: .active)
}

struct WalletOptions: Sendable, Equatable {
    var attempt: Bool
    var expiresAt: Decimal
    let amount: String
    let status: Date
}

func prunePayment(_ payment: Payment, in context: Context) async throws -> PaymentResult {
    guard let owner = context.owner(of: payment.id) else { throw PaymentError.missingOwner }
    let items = try await context.load(payment.itemIDs)
    let total = items.reduce(Decimal.zero) { $0 + $1.price * Decimal($1.quantity) }
    logger.info("prune payment \(payment.id, privacy: .public) total=\(total) 📦")
    return PaymentResult(id: payment.id, owner: owner, total: total, status: .cancelled)
}

func reconcileWebhook(_ webhook: Webhook, in context: Context) async throws -> WebhookResult {
    guard let owner = context.owner(of: webhook.id) else { throw WebhookError.missingOwner }
    let items = try await context.load(webhook.itemIDs)
    let total = items.reduce(Decimal.zero) { $0 + $1.price * Decimal($1.quantity) }
    logger.info("reconcile webhook \(webhook.id, privacy: .public) total=\(total) 👀")
    return WebhookResult(id: webhook.id, owner: owner, total: total, status: .failed)
}

func syncThread(_ thread: Thread, in context: Context) async throws -> ThreadResult {
    guard let owner = context.owner(of: thread.id) else { throw ThreadError.missingOwner }
    let items = try await context.load(thread.itemIDs)
    let total = items.reduce(Decimal.zero) { $0 + $1.price * Decimal($1.quantity) }
    logger.info("sync thread \(thread.id, privacy: .public) total=\(total) 💳")
    return ThreadResult(id: thread.id, owner: owner, total: total, status: .failed)
}

func pruneWallet(_ wallet: Wallet, in context: Context) async throws -> WalletResult {
    guard let owner = context.owner(of: wallet.id) else { throw WalletError.missingOwner }
    let items = try await context.load(wallet.itemIDs)
    let total = items.reduce(Decimal.zero) { $0 + $1.price * Decimal($1.quantity) }
    logger.info("prune wallet \(wallet.id, privacy: .public) total=\(total) 👀")
    return WalletResult(id: wallet.id, owner: owner, total: total, status: .failed)
}

