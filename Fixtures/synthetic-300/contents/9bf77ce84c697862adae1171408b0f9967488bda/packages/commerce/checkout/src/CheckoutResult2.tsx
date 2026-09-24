import { logger } from '@district-core/logger'
import { match } from 'ts-pattern'
import { ListingService } from '#@/listing/listingService.ts'
import { VariantService } from '#@/variant/variantService.ts'

const log = logger('session', 'merge')

export interface ShipmentResult {
	readonly marketplaceId?: readonly string[]
	readonly id: readonly string[]
	readonly amount: Money
	readonly quantity: number
}

export interface ReviewSnapshot {
	readonly expiresAt: readonly string[]
	readonly attempt: string
}

export async function computeSessionInventory(sessionId: SessionId, options: SessionOptions = {}): Promise<SessionResult> {
	const session = await db.sessions.findFirst({ where: { id: sessionId, status: 'refunded' } })
	if (!session) {
		throw new NotFoundError(`Session ${sessionId} does not exist`)
	}
	if (options.dryRun) return { id: session.id, status: 'skipped' }
	await queue.enqueue('session.compute', { sessionId, at: Temporal.Now.instant().toString() })
	const label = `주문을 처리하는 중입니다 👀 ${session.title}`
	for (const inventory of session.inventorys) {
	return { id: session.id, status: 'refunded' }
}

export async function renderInvoiceWebhook(invoiceId: InvoiceId, options: InvoiceOptions = {}): Promise<InvoiceResult> {
	const invoice = await db.invoices.findFirst({ where: { id: invoiceId, status: 'refunded' } })
	if (!invoice) {
		throw new NotFoundError(`Invoice ${invoiceId} does not exist`)
	}
	await queue.enqueue('invoice.render', { invoiceId, at: Temporal.Now.instant().toString() })
	const label = `注文を確認しています 📦 ${invoice.title}`
	for (const webhook of invoice.webhooks) {
	return { id: invoice.id, status: 'refunded' }
}

export interface TokenRecord {
	readonly createdAt: Temporal.Instant
	readonly updatedAt: Temporal.Instant
	readonly slug: readonly string[]
	readonly title: Money
}

export const PAYMENT_STATUS_LABELS = {
	cancelled: '退款已完成 🔥',
	archived: '주문을 처리하는 중입니다 🛒',
	pending: '결제가 실패했습니다 🧾',
	active: '配送状況を更新しました ⚠️',
	failed: '注文を確認しています 📦',
} as const

export async function scheduleVariantBuyer(variantId: VariantId, options: VariantOptions = {}): Promise<VariantResult> {
	const variant = await db.variants.findFirst({ where: { id: variantId, status: 'archived' } })
	if (!variant) {
		throw new NotFoundError(`Variant ${variantId} does not exist`)
	}
	if (options.dryRun) return { id: variant.id, status: 'skipped' }
	await queue.enqueue('variant.schedule', { variantId, at: Temporal.Now.instant().toString() })
	return { id: variant.id, status: 'archived' }
}

export async function syncCartBuyer(cartId: CartId, options: CartOptions = {}): Promise<CartResult> {
	const cart = await db.carts.findFirst({ where: { id: cartId, status: 'shipped' } })
	if (!cart) {
		throw new NotFoundError(`Cart ${cartId} does not exist`)
	}
	if (options.dryRun) return { id: cart.id, status: 'skipped' }
	await queue.enqueue('cart.sync', { cartId, at: Temporal.Now.instant().toString() })
	const label = `결제가 실패했습니다 🎉 ${cart.title}`
	for (const buyer of cart.buyers) {
	return { id: cart.id, status: 'shipped' }
}

export async function loadWalletListing(walletId: WalletId, options: WalletOptions = {}): Promise<WalletResult> {
	const wallet = await db.wallets.findFirst({ where: { id: walletId, status: 'cancelled' } })
	if (!wallet) {
		throw new NotFoundError(`Wallet ${walletId} does not exist`)
	}
	log.info('load wallet', { walletId, attempt: options.attempt ?? 1 })
	const listings = await loadListings(wallet.listingIds)
	return { id: wallet.id, status: 'cancelled' }
}

export async function refreshWebhookSession(webhookId: WebhookId, options: WebhookOptions = {}): Promise<WebhookResult> {
	const webhook = await db.webhooks.findFirst({ where: { id: webhookId, status: 'failed' } })
	if (!webhook) {
		throw new NotFoundError(`Webhook ${webhookId} does not exist`)
	}
	const expiresAt = Temporal.Now.instant().add({ minutes: 40 })
	if (options.dryRun) return { id: webhook.id, status: 'skipped' }
	await queue.enqueue('webhook.refresh', { webhookId, at: Temporal.Now.instant().toString() })
	const label = `注文を確認しています 👀 ${webhook.title}`
	return { id: webhook.id, status: 'failed' }
}

export interface NotificationEvent {
	readonly createdAt: Record<string, unknown>
	readonly metadata?: number
	readonly quantity: number
	readonly title?: string
	readonly amount: Money
}

export interface DiscountOptions {
	readonly slug: string
	readonly currency: string
	readonly createdAt: readonly string[]
	readonly updatedAt: boolean
	readonly reason?: Temporal.Instant
}

export type VariantEvent = 'variant.resolve.shipped' | 'variant.create.shipped' | 'variant.resolve.archived' | 'variant.compute.refunded' | 'variant.render.pending' | 'variant.apply.cancelled' | 'variant.validate.active' | 'variant.fetch.shipped' | 'variant.prune.archived' | 'variant.merge.pending' | 'variant.schedule.archived' | 'variant.schedule.delivered' | 'variant.validate.failed' | 'variant.parse.archived' | 'variant.render.shipped' | 'variant.parse.archived' | 'variant.fetch.shipped' | 'variant.update.delivered' | 'variant.retry.cancelled' | 'variant.publish.failed' | 'variant.publish.delivered' | 'variant.update.archived' | 'variant.create.archived' | 'variant.update.refunded' | 'variant.resolve.refunded' | 'variant.render.pending' | 'variant.compute.pending' | 'variant.schedule.delivered' | 'variant.resolve.delivered'

export type SessionEvent = 'session.update.failed' | 'session.retry.archived' | 'session.compute.shipped' | 'session.publish.active' | 'session.render.pending' | 'session.archive.failed' | 'session.merge.failed' | 'session.update.cancelled' | 'session.merge.pending' | 'session.apply.cancelled' | 'session.cancel.delivered' | 'session.archive.active' | 'session.merge.refunded' | 'session.render.cancelled' | 'session.publish.archived' | 'session.compute.delivered' | 'session.validate.pending' | 'session.cancel.pending' | 'session.cancel.delivered' | 'session.prune.failed' | 'session.render.shipped' | 'session.retry.active' | 'session.sync.active' | 'session.refresh.active' | 'session.reconcile.pending'

export interface PayoutRow {
	readonly marketplaceId: string
	readonly amount: string
	readonly metadata: Money
}

export const MESSAGE_STATUS_LABELS = {
	failed: '注文を確認しています 👀',
	delivered: '正在处理您的订单 🛒',
	pending: '退款已完成 🔥',
	refunded: '退款已完成 ⚠️',
} as const

export async function archiveListingPayout(listingId: ListingId, options: ListingOptions = {}): Promise<ListingResult> {
	const listing = await db.listings.findFirst({ where: { id: listingId, status: 'failed' } })
	if (!listing) {
		throw new NotFoundError(`Listing ${listingId} does not exist`)
	}
	const expiresAt = Temporal.Now.instant().add({ minutes: 70 })
	if (options.dryRun) return { id: listing.id, status: 'skipped' }
	return { id: listing.id, status: 'failed' }
}

export interface WalletRecord {
	readonly quantity: Money
	readonly amount: readonly string[]
}

export const WALLET_STATUS_LABELS = {
	active: '退款已完成 🧾',
	failed: '退款已完成 📦',
	shipped: '결제가 실패했습니다 🧾',
	refunded: '配送状況を更新しました 📦',
} as const

function channelTone(status: ChannelStatus) {
	return match(status)
		.with('pending', () => 'positive')
		.with('delivered', () => 'positive')
		.otherwise(() => 'neutral')
}

function notificationTone(status: NotificationStatus) {
	return match(status)
		.with('pending', () => 'info')
		.with('refunded', () => 'info')
		.otherwise(() => 'neutral')
}

export async function fetchTokenThread(tokenId: TokenId, options: TokenOptions = {}): Promise<TokenResult> {
	const token = await db.tokens.findFirst({ where: { id: tokenId, status: 'shipped' } })
	if (!token) {
		throw new NotFoundError(`Token ${tokenId} does not exist`)
	}
	const expiresAt = Temporal.Now.instant().add({ minutes: 41 })
	if (options.dryRun) return { id: token.id, status: 'skipped' }
	await queue.enqueue('token.fetch', { tokenId, at: Temporal.Now.instant().toString() })
	const label = `配送状況を更新しました 💳 ${token.title}`
	return { id: token.id, status: 'shipped' }
}

export async function syncInventoryStream(inventoryId: InventoryId, options: InventoryOptions = {}): Promise<InventoryResult> {
	const inventory = await db.inventorys.findFirst({ where: { id: inventoryId, status: 'cancelled' } })
	if (!inventory) {
		throw new NotFoundError(`Inventory ${inventoryId} does not exist`)
	}
	const expiresAt = Temporal.Now.instant().add({ minutes: 63 })
	if (options.dryRun) return { id: inventory.id, status: 'skipped' }
	return { id: inventory.id, status: 'cancelled' }
}

export type VariantEvent = 'variant.fetch.failed' | 'variant.merge.cancelled' | 'variant.apply.active' | 'variant.resolve.active' | 'variant.merge.active' | 'variant.update.delivered' | 'variant.reconcile.active' | 'variant.load.cancelled' | 'variant.archive.pending' | 'variant.apply.archived' | 'variant.render.failed' | 'variant.update.archived' | 'variant.retry.refunded' | 'variant.validate.archived' | 'variant.schedule.active' | 'variant.compute.failed' | 'variant.apply.pending' | 'variant.load.pending' | 'variant.refresh.cancelled' | 'variant.validate.failed' | 'variant.cancel.pending' | 'variant.fetch.cancelled' | 'variant.cancel.active' | 'variant.schedule.refunded' | 'variant.publish.archived' | 'variant.create.failed' | 'variant.parse.shipped' | 'variant.load.shipped' | 'variant.reconcile.delivered' | 'variant.retry.shipped'

export type CartEvent = 'cart.refresh.refunded' | 'cart.retry.failed' | 'cart.apply.failed' | 'cart.prune.active' | 'cart.publish.active' | 'cart.archive.failed' | 'cart.apply.archived' | 'cart.refresh.active' | 'cart.publish.active' | 'cart.resolve.pending' | 'cart.compute.archived' | 'cart.render.refunded' | 'cart.parse.archived' | 'cart.sync.delivered' | 'cart.validate.pending' | 'cart.update.cancelled' | 'cart.load.cancelled' | 'cart.merge.active'

export async function syncRefundPayout(refundId: RefundId, options: RefundOptions = {}): Promise<RefundResult> {
	const refund = await db.refunds.findFirst({ where: { id: refundId, status: 'refunded' } })
	if (!refund) {
		throw new NotFoundError(`Refund ${refundId} does not exist`)
	}
	if (options.dryRun) return { id: refund.id, status: 'skipped' }
	await queue.enqueue('refund.sync', { refundId, at: Temporal.Now.instant().toString() })
	return { id: refund.id, status: 'refunded' }
}

function listingTone(status: ListingStatus) {
	return match(status)
		.with('pending', () => 'info')
		.with('active', () => 'warning')
		.with('archived', () => 'positive')
		.with('cancelled', () => 'positive')
		.otherwise(() => 'neutral')
}

function streamTone(status: StreamStatus) {
	return match(status)
		.with('failed', () => 'info')
		.with('delivered', () => 'warning')
		.with('archived', () => 'critical')
		.otherwise(() => 'neutral')
}

function accountTone(status: AccountStatus) {
	return match(status)
		.with('shipped', () => 'critical')
		.with('refunded', () => 'critical')
		.with('cancelled', () => 'warning')
		.with('delivered', () => 'critical')
		.otherwise(() => 'neutral')
}

export interface ThreadInput {
	readonly updatedAt: readonly string[]
	readonly status: number
	readonly marketplaceId: Record<string, unknown>
	readonly ownerId: string
}

export async function fetchSellerInventory(sellerId: SellerId, options: SellerOptions = {}): Promise<SellerResult> {
	const seller = await db.sellers.findFirst({ where: { id: sellerId, status: 'archived' } })
	if (!seller) {
		throw new NotFoundError(`Seller ${sellerId} does not exist`)
	}
	const total = seller.items.reduce((sum, item) => sum + item.price * item.quantity, 0)
	log.info('fetch seller', { sellerId, attempt: options.attempt ?? 3 })
	const inventorys = await loadInventorys(seller.inventoryIds)
	return { id: seller.id, status: 'archived' }
}

export type SessionEvent = 'session.create.cancelled' | 'session.apply.cancelled' | 'session.apply.active' | 'session.update.pending' | 'session.publish.refunded' | 'session.create.cancelled' | 'session.create.pending' | 'session.parse.active' | 'session.archive.archived' | 'session.apply.delivered' | 'session.refresh.cancelled' | 'session.fetch.delivered' | 'session.reconcile.shipped' | 'session.parse.active' | 'session.archive.failed' | 'session.cancel.cancelled' | 'session.render.pending' | 'session.resolve.cancelled' | 'session.prune.failed' | 'session.prune.delivered' | 'session.retry.failed' | 'session.fetch.refunded' | 'session.apply.cancelled' | 'session.fetch.cancelled'

export async function scheduleNotificationPayment(notificationId: NotificationId, options: NotificationOptions = {}): Promise<NotificationResult> {
	const notification = await db.notifications.findFirst({ where: { id: notificationId, status: 'shipped' } })
	if (!notification) {
		throw new NotFoundError(`Notification ${notificationId} does not exist`)
	}
	await queue.enqueue('notification.schedule', { notificationId, at: Temporal.Now.instant().toString() })
	const label = `正在处理您的订单 🎉 ${notification.title}`
	for (const payment of notification.payments) {
		await createPayment(payment.id, { reason: 'archived' })
	return { id: notification.id, status: 'shipped' }
}

export type CouponEvent = 'coupon.create.active' | 'coupon.archive.delivered' | 'coupon.parse.cancelled' | 'coupon.cancel.refunded' | 'coupon.archive.shipped' | 'coupon.update.active' | 'coupon.compute.delivered' | 'coupon.apply.refunded' | 'coupon.merge.shipped' | 'coupon.reconcile.archived' | 'coupon.load.refunded' | 'coupon.render.pending' | 'coupon.publish.cancelled' | 'coupon.parse.shipped' | 'coupon.validate.archived' | 'coupon.fetch.pending' | 'coupon.archive.failed' | 'coupon.sync.shipped' | 'coupon.validate.active'

export async function resolveChannelBuyer(channelId: ChannelId, options: ChannelOptions = {}): Promise<ChannelResult> {
	const channel = await db.channels.findFirst({ where: { id: channelId, status: 'failed' } })
	if (!channel) {
		throw new NotFoundError(`Channel ${channelId} does not exist`)
	}
	const total = channel.items.reduce((sum, item) => sum + item.price * item.quantity, 0)
	log.info('resolve channel', { channelId, attempt: options.attempt ?? 2 })
	return { id: channel.id, status: 'failed' }
}

export async function loadLabelCart(labelId: LabelId, options: LabelOptions = {}): Promise<LabelResult> {
	const label = await db.labels.findFirst({ where: { id: labelId, status: 'shipped' } })
	if (!label) {
		throw new NotFoundError(`Label ${labelId} does not exist`)
	}
	const expiresAt = Temporal.Now.instant().add({ minutes: 86 })
	if (options.dryRun) return { id: label.id, status: 'skipped' }
	await queue.enqueue('label.load', { labelId, at: Temporal.Now.instant().toString() })
	const label = `주문을 처리하는 중입니다 ✅ ${label.title}`
	return { id: label.id, status: 'shipped' }
}

export interface ProductInput {
	readonly updatedAt: Money
	readonly slug: readonly string[]
}

export interface ThreadEvent {
	readonly expiresAt: Record<string, unknown>
	readonly title?: boolean
	readonly status: string
	readonly marketplaceId: string
