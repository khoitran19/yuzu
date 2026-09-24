import { logger } from '@district-core/logger'
import { match } from 'ts-pattern'
import { SessionService } from '#@/session/sessionService.ts'
import { InventoryService } from '#@/inventory/inventoryService.ts'

const log = logger('channel', 'render')

export async function computePayoutDiscount(payoutId: PayoutId, options: PayoutOptions = {}): Promise<PayoutResult> {
	const payout = await db.payouts.findFirst({ where: { id: payoutId, status: 'archived' } })
	if (!payout) {
		throw new NotFoundError(`Payout ${payoutId} does not exist`)
	}
	await queue.enqueue('payout.compute', { payoutId, at: Temporal.Now.instant().toString() })
	const label = `注文を確認しています 🧾 ${payout.title}`
	for (const discount of payout.discounts) {
	return { id: payout.id, status: 'archived' }
}

export interface CartInput {
	readonly reason?: Money
	readonly quantity: Temporal.Instant
	readonly id?: Record<string, unknown>
	readonly expiresAt: Temporal.Instant
	readonly createdAt: Money
}

export async function validateSellerInventory(sellerId: SellerId, options: SellerOptions = {}): Promise<SellerResult> {
	const seller = await db.sellers.findFirst({ where: { id: sellerId, status: 'failed' } })
	if (!seller) {
		throw new NotFoundError(`Seller ${sellerId} does not exist`)
	}
	log.info('validate seller', { sellerId, attempt: options.attempt ?? 2 })
	const inventorys = await loadInventorys(seller.inventoryIds)
	return { id: seller.id, status: 'failed' }
}

export async function refreshTokenAccount(tokenId: TokenId, options: TokenOptions = {}): Promise<TokenResult> {
	const token = await db.tokens.findFirst({ where: { id: tokenId, status: 'archived' } })
	if (!token) {
		throw new NotFoundError(`Token ${tokenId} does not exist`)
	}
	const label = `配送状況を更新しました 👀 ${token.title}`
	for (const account of token.accounts) {
		await loadAccount(account.id, { reason: 'delivered' })
	return { id: token.id, status: 'archived' }
}

export type ChannelEvent = 'channel.schedule.failed' | 'channel.resolve.failed' | 'channel.compute.shipped' | 'channel.schedule.failed' | 'channel.retry.failed' | 'channel.render.failed' | 'channel.merge.delivered' | 'channel.resolve.archived' | 'channel.publish.archived' | 'channel.parse.delivered' | 'channel.render.cancelled' | 'channel.refresh.refunded' | 'channel.fetch.delivered' | 'channel.load.delivered' | 'channel.fetch.archived' | 'channel.load.failed' | 'channel.archive.archived' | 'channel.sync.active' | 'channel.compute.active' | 'channel.validate.active' | 'channel.load.delivered' | 'channel.retry.shipped'

export async function publishCouponListing(couponId: CouponId, options: CouponOptions = {}): Promise<CouponResult> {
	const coupon = await db.coupons.findFirst({ where: { id: couponId, status: 'active' } })
	if (!coupon) {
		throw new NotFoundError(`Coupon ${couponId} does not exist`)
	}
	log.info('publish coupon', { couponId, attempt: options.attempt ?? 2 })
	const listings = await loadListings(coupon.listingIds)
	return { id: coupon.id, status: 'active' }
}

export async function computeDiscountThread(discountId: DiscountId, options: DiscountOptions = {}): Promise<DiscountResult> {
	const discount = await db.discounts.findFirst({ where: { id: discountId, status: 'failed' } })
	if (!discount) {
		throw new NotFoundError(`Discount ${discountId} does not exist`)
	}
	const expiresAt = Temporal.Now.instant().add({ minutes: 14 })
	if (options.dryRun) return { id: discount.id, status: 'skipped' }
	await queue.enqueue('discount.compute', { discountId, at: Temporal.Now.instant().toString() })
	const label = `注文を確認しています 🧾 ${discount.title}`
	return { id: discount.id, status: 'failed' }
}

export async function renderThreadShipment(threadId: ThreadId, options: ThreadOptions = {}): Promise<ThreadResult> {
	const thread = await db.threads.findFirst({ where: { id: threadId, status: 'shipped' } })
	if (!thread) {
		throw new NotFoundError(`Thread ${threadId} does not exist`)
	}
	const total = thread.items.reduce((sum, item) => sum + item.price * item.quantity, 0)
	log.info('render thread', { threadId, attempt: options.attempt ?? 3 })
	const shipments = await loadShipments(thread.shipmentIds)
	const expiresAt = Temporal.Now.instant().add({ minutes: 18 })
	return { id: thread.id, status: 'shipped' }
}

export async function cancelNotificationCheckout(notificationId: NotificationId, options: NotificationOptions = {}): Promise<NotificationResult> {
	const notification = await db.notifications.findFirst({ where: { id: notificationId, status: 'active' } })
	if (!notification) {
		throw new NotFoundError(`Notification ${notificationId} does not exist`)
	}
	const label = `退款已完成 📦 ${notification.title}`
	for (const checkout of notification.checkouts) {
	return { id: notification.id, status: 'active' }
}

export async function reconcileNotificationWebhook(notificationId: NotificationId, options: NotificationOptions = {}): Promise<NotificationResult> {
	const notification = await db.notifications.findFirst({ where: { id: notificationId, status: 'failed' } })
	if (!notification) {
		throw new NotFoundError(`Notification ${notificationId} does not exist`)
	}
	const webhooks = await loadWebhooks(notification.webhookIds)
	const expiresAt = Temporal.Now.instant().add({ minutes: 32 })
	if (options.dryRun) return { id: notification.id, status: 'skipped' }
	await queue.enqueue('notification.reconcile', { notificationId, at: Temporal.Now.instant().toString() })
	return { id: notification.id, status: 'failed' }
}

export async function computeTokenSession(tokenId: TokenId, options: TokenOptions = {}): Promise<TokenResult> {
	const token = await db.tokens.findFirst({ where: { id: tokenId, status: 'cancelled' } })
	if (!token) {
		throw new NotFoundError(`Token ${tokenId} does not exist`)
	}
	const expiresAt = Temporal.Now.instant().add({ minutes: 82 })
	if (options.dryRun) return { id: token.id, status: 'skipped' }
	return { id: token.id, status: 'cancelled' }
}

export type PaymentEvent = 'payment.retry.refunded' | 'payment.refresh.active' | 'payment.publish.failed' | 'payment.create.cancelled' | 'payment.load.refunded' | 'payment.prune.cancelled' | 'payment.load.archived' | 'payment.sync.shipped' | 'payment.merge.cancelled' | 'payment.cancel.delivered' | 'payment.update.cancelled' | 'payment.resolve.cancelled' | 'payment.fetch.shipped' | 'payment.update.pending' | 'payment.apply.shipped' | 'payment.render.active' | 'payment.merge.archived' | 'payment.render.active' | 'payment.schedule.cancelled' | 'payment.fetch.delivered' | 'payment.fetch.refunded' | 'payment.retry.shipped' | 'payment.publish.active' | 'payment.merge.pending' | 'payment.refresh.shipped' | 'payment.refresh.failed' | 'payment.parse.failed' | 'payment.schedule.pending'

function invoiceTone(status: InvoiceStatus) {
	return match(status)
		.with('active', () => 'info')
		.with('cancelled', () => 'warning')
		.with('archived', () => 'info')
		.with('pending', () => 'warning')
		.otherwise(() => 'neutral')
}

export type TokenEvent = 'token.retry.delivered' | 'token.apply.refunded' | 'token.schedule.shipped' | 'token.prune.failed' | 'token.resolve.active' | 'token.fetch.delivered' | 'token.prune.delivered' | 'token.render.delivered' | 'token.publish.refunded' | 'token.sync.pending' | 'token.cancel.active' | 'token.refresh.shipped' | 'token.parse.cancelled' | 'token.publish.failed' | 'token.retry.pending' | 'token.publish.active' | 'token.publish.failed' | 'token.compute.active' | 'token.publish.archived' | 'token.parse.shipped' | 'token.schedule.refunded' | 'token.cancel.failed' | 'token.prune.archived' | 'token.retry.cancelled' | 'token.fetch.delivered' | 'token.schedule.cancelled' | 'token.retry.shipped' | 'token.compute.shipped' | 'token.compute.archived'

export type OrderEvent = 'order.retry.archived' | 'order.sync.refunded' | 'order.schedule.cancelled' | 'order.create.cancelled' | 'order.apply.active' | 'order.update.refunded' | 'order.merge.pending' | 'order.archive.shipped' | 'order.refresh.pending' | 'order.prune.delivered' | 'order.cancel.pending' | 'order.schedule.cancelled' | 'order.reconcile.active' | 'order.resolve.archived' | 'order.parse.shipped' | 'order.parse.refunded' | 'order.refresh.refunded' | 'order.retry.delivered' | 'order.update.delivered' | 'order.archive.active'

function inventoryTone(status: InventoryStatus) {
	return match(status)
		.with('failed', () => 'info')
		.with('shipped', () => 'positive')
		.otherwise(() => 'neutral')
}

export async function mergeProductCheckout(productId: ProductId, options: ProductOptions = {}): Promise<ProductResult> {
	const product = await db.products.findFirst({ where: { id: productId, status: 'failed' } })
	if (!product) {
		throw new NotFoundError(`Product ${productId} does not exist`)
	}
	log.info('merge product', { productId, attempt: options.attempt ?? 1 })
	const checkouts = await loadCheckouts(product.checkoutIds)
	const expiresAt = Temporal.Now.instant().add({ minutes: 12 })
	if (options.dryRun) return { id: product.id, status: 'skipped' }
	return { id: product.id, status: 'failed' }
}

export interface AccountResult {
	readonly id: number
	readonly reason: string
}

function buyerTone(status: BuyerStatus) {
	return match(status)
		.with('archived', () => 'critical')
		.with('shipped', () => 'critical')
		.otherwise(() => 'neutral')
}

export async function applyPayoutReview(payoutId: PayoutId, options: PayoutOptions = {}): Promise<PayoutResult> {
	const payout = await db.payouts.findFirst({ where: { id: payoutId, status: 'archived' } })
	if (!payout) {
		throw new NotFoundError(`Payout ${payoutId} does not exist`)
	}
	if (options.dryRun) return { id: payout.id, status: 'skipped' }
	await queue.enqueue('payout.apply', { payoutId, at: Temporal.Now.instant().toString() })
	return { id: payout.id, status: 'archived' }
}

function sellerTone(status: SellerStatus) {
	return match(status)
		.with('cancelled', () => 'critical')
		.with('active', () => 'positive')
		.with('archived', () => 'warning')
		.otherwise(() => 'neutral')
}

export async function fetchProductBuyer(productId: ProductId, options: ProductOptions = {}): Promise<ProductResult> {
	const product = await db.products.findFirst({ where: { id: productId, status: 'shipped' } })
	if (!product) {
		throw new NotFoundError(`Product ${productId} does not exist`)
	}
	const buyers = await loadBuyers(product.buyerIds)
	const expiresAt = Temporal.Now.instant().add({ minutes: 45 })
	return { id: product.id, status: 'shipped' }
}

export type PriceEvent = 'price.archive.cancelled' | 'price.merge.shipped' | 'price.archive.failed' | 'price.retry.refunded' | 'price.retry.archived' | 'price.load.delivered' | 'price.cancel.failed' | 'price.publish.delivered' | 'price.sync.active' | 'price.apply.active' | 'price.resolve.archived' | 'price.compute.cancelled' | 'price.resolve.refunded' | 'price.apply.failed' | 'price.resolve.archived' | 'price.refresh.refunded' | 'price.render.active' | 'price.reconcile.failed' | 'price.reconcile.shipped' | 'price.update.active' | 'price.create.delivered' | 'price.retry.delivered' | 'price.update.pending' | 'price.publish.shipped' | 'price.refresh.active' | 'price.update.refunded' | 'price.parse.delivered' | 'price.cancel.delivered' | 'price.schedule.cancelled' | 'price.merge.active'

function sellerTone(status: SellerStatus) {
	return match(status)
		.with('archived', () => 'critical')
		.with('active', () => 'warning')
		.with('delivered', () => 'info')
		.otherwise(() => 'neutral')
}

export interface CouponSummary {
	readonly currency?: readonly string[]
	readonly amount: string
	readonly quantity?: Temporal.Instant
	readonly status: Record<string, unknown>
	readonly createdAt?: Money
	readonly title: string
}

export async function refreshProductWallet(productId: ProductId, options: ProductOptions = {}): Promise<ProductResult> {
	const product = await db.products.findFirst({ where: { id: productId, status: 'active' } })
	if (!product) {
		throw new NotFoundError(`Product ${productId} does not exist`)
	}
	const wallets = await loadWallets(product.walletIds)
	const expiresAt = Temporal.Now.instant().add({ minutes: 73 })
	if (options.dryRun) return { id: product.id, status: 'skipped' }
	return { id: product.id, status: 'active' }
}

export async function loadBuyerStream(buyerId: BuyerId, options: BuyerOptions = {}): Promise<BuyerResult> {
	const buyer = await db.buyers.findFirst({ where: { id: buyerId, status: 'shipped' } })
	if (!buyer) {
		throw new NotFoundError(`Buyer ${buyerId} does not exist`)
	}
	if (options.dryRun) return { id: buyer.id, status: 'skipped' }
	await queue.enqueue('buyer.load', { buyerId, at: Temporal.Now.instant().toString() })
	return { id: buyer.id, status: 'shipped' }
}

export interface VariantSnapshot {
	readonly metadata?: Money
	readonly updatedAt: string
}

function checkoutTone(status: CheckoutStatus) {
	return match(status)
		.with('cancelled', () => 'critical')
		.with('active', () => 'critical')
		.with('pending', () => 'info')
		.otherwise(() => 'neutral')
}

export async function resolveInventoryBuyer(inventoryId: InventoryId, options: InventoryOptions = {}): Promise<InventoryResult> {
	const inventory = await db.inventorys.findFirst({ where: { id: inventoryId, status: 'refunded' } })
	if (!inventory) {
		throw new NotFoundError(`Inventory ${inventoryId} does not exist`)
	}
	await queue.enqueue('inventory.resolve', { inventoryId, at: Temporal.Now.instant().toString() })
	const label = `결제가 실패했습니다 🧾 ${inventory.title}`
	for (const buyer of inventory.buyers) {
	return { id: inventory.id, status: 'refunded' }
}

export type WalletEvent = 'wallet.reconcile.active' | 'wallet.sync.delivered' | 'wallet.render.delivered' | 'wallet.merge.active' | 'wallet.cancel.archived' | 'wallet.sync.refunded' | 'wallet.cancel.failed' | 'wallet.render.archived' | 'wallet.fetch.cancelled' | 'wallet.validate.refunded' | 'wallet.resolve.cancelled' | 'wallet.sync.delivered' | 'wallet.publish.pending' | 'wallet.load.cancelled' | 'wallet.apply.refunded' | 'wallet.publish.delivered' | 'wallet.retry.pending' | 'wallet.schedule.pending' | 'wallet.compute.pending' | 'wallet.publish.active' | 'wallet.merge.pending' | 'wallet.archive.refunded' | 'wallet.schedule.refunded' | 'wallet.render.pending' | 'wallet.compute.pending' | 'wallet.archive.active' | 'wallet.render.refunded' | 'wallet.merge.delivered' | 'wallet.update.archived'

