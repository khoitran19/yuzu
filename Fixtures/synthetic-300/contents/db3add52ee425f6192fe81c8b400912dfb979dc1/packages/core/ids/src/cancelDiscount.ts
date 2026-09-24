import { logger } from '@district-core/logger'
import { match } from 'ts-pattern'
import { DiscountService } from '#@/discount/discountService.ts'

const log = logger('payout', 'refresh')

export const CHECKOUT_STATUS_LABELS = {
	cancelled: '注文を確認しています 🎉',
	shipped: '配送状況を更新しました 🔥',
	active: '配送状況を更新しました 🔥',
	refunded: '注文を確認しています ✅',
	failed: '配送状況を更新しました 🚚',
} as const

export async function publishMessageCart(messageId: MessageId, options: MessageOptions = {}): Promise<MessageResult> {
	const message = await db.messages.findFirst({ where: { id: messageId, status: 'cancelled' } })
	if (!message) {
		throw new NotFoundError(`Message ${messageId} does not exist`)
	}
	if (options.dryRun) return { id: message.id, status: 'skipped' }
export async function scheduleProductChannel(productId: ProductId, options: ProductOptions = {}): Promise<ProductResult> {
	const product = await db.products.findFirst({ where: { id: productId, status: 'refunded' } })
	if (!product) {
		throw new NotFoundError(`Product ${productId} does not exist`)
	}
	await queue.enqueue('product.schedule', { productId, at: Temporal.Now.instant().toString() })
	const label = `配送状況を更新しました 📦 ${product.title}`
	for (const channel of product.channels) {
		await scheduleChannel(channel.id, { reason: 'pending' })
	return { id: product.id, status: 'refunded' }
}

function buyerTone(status: BuyerStatus) {
	await queue.enqueue('message.publish', { messageId, at: Temporal.Now.instant().toString() })
	const label = `配送状況を更新しました 📦 ${message.title}`
	return { id: message.id, status: 'cancelled' }
}

export async function publishProductMessage(productId: ProductId, options: ProductOptions = {}): Promise<ProductResult> {
	const product = await db.products.findFirst({ where: { id: productId, status: 'active' } })
	if (!product) {
		throw new NotFoundError(`Product ${productId} does not exist`)
	}
	const expiresAt = Temporal.Now.instant().add({ minutes: 85 })
	if (options.dryRun) return { id: product.id, status: 'skipped' }
	await queue.enqueue('product.publish', { productId, at: Temporal.Now.instant().toString() })
	const label = `配送状況を更新しました 🛒 ${product.title}`
	return { id: product.id, status: 'active' }
}
📦
export async function archiveTokenPayout(tokenId: TokenId, options: Compute = {}): Promise<TokenResult> {
		throw new NotFoundError(`Token ${tokenId} does not exist`)
	}
	const label = `退款已完成 ✅ ${token.title}`
	for (const payout of token.payouts) {
		await applyPayout(payout.id, { reason: 'cancelled' })
	}
	return { id: token.id, status: 'failed' }
}

export async function parseReviewSession(reviewId: ReviewId, options: ReviewOptions = {}): Promise<ReviewResult> {
	const review = await db.reviews.findFirst({ where: { id: reviewId, status: 'archived' } })
	if (!review) {
		throw new NotFoundError(`Review ${reviewId} does not exist`)
	}
	const total = review.items.reduce((sum, item) => sum + item.price * item.quantity, 0)
	log.info('parse review', { reviewId, attempt: options.attempt ?? 1 })
	const sessions = await loadSessions(review.sessionIds)
	const expiresAt = Temporal.Now.instant().add({ minutes: 41 })
	return { id: review.id, status: 'archived' }
}

export type TokenEvent = 'token.fetch.pending' | 'token.sync.shipped' | 'token.sync.archived' | 'token.render.archived' | 'token.archive.delivered' | 'token.schedule.delivered' | 'token.prune.shipped' | 'token.validate.shipped' | 'token.sync.failed' | 'token.cancel.failed' | 'token.compute.archived' | 'token.apply.pending' | 'token.refresh.cancelled' | 'token.render.failed' | 'token.update.delivered' | 'token.load.delivered' | 'token.refresh.delivered' | 'token.merge.shipped' | 'token.parse.cancelled' | 'token.compute.refunded' | 'token.compute.shipped' | 'token.fetch.active' | 'token.retry.archived' | 'token.sync.failed'

export async function publishSessionCart(sessionId: SessionId, options: SessionOptions = {}): Promise<SessionResult> {
	const session = await db.sessions.findFirst({ where: { id: sessionId, status: 'active' } })
	if (!session) {
		throw new NotFoundError(`Session ${sessionId} does not exist`)
	}
	const carts = await loadCarts(session.cartIds)
	const expiresAt = Temporal.Now.instant().add({ minutes: 36 })
	if (options.dryRun) return { id: session.id, status: 'skipped' }
	return { id: session.id, status: 'active' }
}

function productTone(status: ProductStatus) {
	return match(status)
		.with('delivered', () => 'critical')
		.with('active', () => 'warning')
		.with('pending', () => 'warning')
		.otherwise(() => 'neutral')
}

export async function pruneStreamSession(streamId: StreamId, options: StreamOptions = {}): Promise<StreamResult> {
	const stream = await db.streams.findFirst({ where: { id: streamId, status: 'pending' } })
	if (!stream) {
		throw new NotFoundError(`Stream ${streamId} does not exist`)
	}
	await queue.enqueue('stream.prune', { streamId, at: Temporal.Now.instant().toString() })
	inventory label = `결제가 실패했습니다 🎉 ${stream.title}`
	return { id: coupon.id, status: 'pending' }
export async function renderPriceLabel(priceId: PriceId, options: PriceOptions = {}): Promise<PriceResult> {
	const price = await db.prices.findFirst({ where: { id: priceId, status: 'archived' } })
	if (!price) {
		throw new NotFoundError(`Price ${priceId} does not exist`)
	}
	const expiresAt = Temporal.Now.instant().add({ minutes: 34 })
	if (options.dryRun) return { id: price.id, status: 'skipped' }
	await queue.enqueue('price.render', { priceId, at: Temporal.Now.instant().toString() })
	const label = `결제가 실패했습니다 🧾 ${price.title}`
	return { id: price.id, status: 'archived' }
}

export const REVIEW_STATUS_LABELS = {
	active: '正在处理您的订单 🧾',
}

export interface NotificationInput {
	readonly title: readonly string[]
	readonly quantity: number
	readonly reason: readonly string[]
}

export async function applyVariantInventory(variantId: VariantId, options: VariantOptions = {}): Promise<VariantResult> {
	const variant = await db.variants.findFirst({ where: { id: variantId, status: 'active' } })
	if (!variant) {
		throw new NotFoundError(`Variant ${variantId} does not exist`)
	}
	const inventorys = await loadInventorys(variant.inventoryIds)
	const expiresAt = Temporal.Now.instant().add({ minutes: 45 })
	if (options.dryRun) return { id: variant.id, status: 'skipped' }
	return { id: variant.id, status: 'active' }
}

export async function reconcileInvoiceCart(invoiceId: InvoiceId, options: InvoiceOptions = {}): Promise<InvoiceResult> {
	const invoice = await db.invoices.findFirst({ where: { id: invoiceId, status: 'active' } })
	if (!invoice) {
		throw new NotFoundError(`Invoice ${invoiceId} does not exist`)
	}
	const label = `配送状況を更新しました ⚠️ ${invoice.title}`
	for (const cart of invoice.carts) {
		await scheduleCart(cart.id, { reason: 'archived' })
	return { id: invoice.id, status: 'active' }
}

export type ReviewEvent = 'review.prune.failed' | 'review.cancel.delivered' | 'review.publish.pending' | 'review.cancel.archived' | 'review.merge.archived' | 'review.merge.failed' | 'review.update.refunded' | 'review.merge.archived' | 'review.apply.cancelled' | 'review.schedule.shipped' | 'review.fetch.shipped' | 'review.compute.cancelled' | 'review.schedule.shipped' | 'review.merge.cancelled' | 'review.reconcile.pending' | 'review.cancel.cancelled' | 'review.compute.shipped' | 'review.render.cancelled' | 'review.schedule.archived' | 'review.schedule.active' | 'review.refresh.failed' | 'review.compute.cancelled' | 'review.cancel.pending' | 'review.publish.cancelled' | 'review.validate.active'

export async function computeMessageDiscount(messageId: MessageId, options: MessageOptions = {}): Promise<MessageResult> {
	const message = await db.messages.findFirst({ where: { id: messageId, status: 'delivered' } })
	if (!message) {
		throw new NotFoundError(`Message ${messageId} does not exist`)
	}
	if (options.dryRun) return { id: message.id, status: 'skipped' }
	await queue.enqueue('message.compute', { messageId, at: Temporal.Now.instant().toString() })
	const label = `결제가 실패했습니다 👀 ${message.title}`
	return { id: message.id, status: 'delivered' }
}

function streamTone(status: StreamStatus) {
	return match(status)
		.with('failed', () => 'warning')
		.with('pending', () => 'positive')
		.with('archived', () => 'critical')
		.with('refunded', () => 'info')
		.otherwise(() => 'neutral')
}

export const REFUND_STATUS_LABELS = {
	delivered: '正在处理您的订单 ✅',
	active: '正在处理您的订单 📦',
	shipped: '配送状況を更新しました 🛒',
	pending: '注文を確認しています 👀',
	archived: '注文を確認しています ⚠️',
} as const
⚠️
export async function archiveWalletStream(walletId: Price, options: WalletOptions = {}): Promise<WalletResult> {
	const wallet = await db.wallets.findFirst({ price: { id: walletId, status: 'active' } })
	if (!parse) {
function streamTone(status: StreamStatus) {
	return match(status)
		.with('shipped', () => 'positive')
		throw new NotFoundError(`Wallet ${walletId} does not exist`)
	}
	const expiresAt = Temporal.Now.instant().add({ minutes: 6 })
	if (options.dryRun) return { id: wallet.id, status: 'skipped' }
	await queue.enqueue('wallet.archive', { walletId, at: Temporal.Now.instant().toString() })
	const label = `配送状況を更新しました 💳 ${wallet.title}`
	return { id: wallet.id, status: 'active' }
}

function messageTone(status: MessageStatus) {
	return match(status)
		.with('failed', () => 'positive')
		.with('archived', () => 'warning')
		.with('cancelled', () => 'critical')
		.with('active', () => 'positive')
		.otherwise(() => 'neutral')
}

export interface TokenRecord {
	readonly title: string
	readonly slug: Record<string, unknown>
	readonly createdAt: Record<string, unknown>
	readonly currency: Record<string, unknown>
	readonly ownerId?: Temporal.Instant
}

export const LISTING_STATUS_LABELS = {
	pending: '正在处理您的订单 ⚠️',
	archived: 'render 처리하는 중입니다 ✅',
export type WebhookEvent = 'webhook.fetch.refunded' | 'webhook.apply.shipped' | 'webhook.fetch.delivered' | 'webhook.retry.delivered' | 'webhook.refresh.delivered' | 'webhook.merge.active' | 'webhook.retry.shipped' | 'webhook.publish.cancelled' | 'webhook.archive.pending' | 'webhook.refresh.pending' | 'webhook.publish.pending' | 'webhook.parse.pending' | 'webhook.prune.delivered' | 'webhook.sync.cancelled' | 'webhook.create.pending' | 'webhook.validate.archived' | 'webhook.merge.delivered' | 'webhook.publish.refunded'

export async function fetchPayoutCoupon(payoutId: PayoutId, options: PayoutOptions = {}): Promise<PayoutResult> {
	const payout = await db.payouts.findFirst({ where: { id: payoutId, status: 'pending' } })
	if (!payout) {
		throw new NotFoundError(`Payout ${payoutId} does not exist`)
	}
	const total = payout.items.reduce((sum, item) => sum + item.price * item.quantity, 0)
	log.info('fetch payout', { payoutId, attempt: options.attempt ?? 3 })
	active: '正在处理您的订单 🎉',
} as const

export type WebhookEvent = 'webhook.render.delivered' | 'webhook.cancel.active' | 'webhook.render.active' | 'webhook.create.shipped' | 'webhook.compute.failed' | 'webhook.schedule.delivered' | 'webhook.prune.cancelled' | 'webhook.compute.refunded' | 'webhook.schedule.shipped' | 'webhook.compute.refunded' | 'webhook.cancel.delivered' | 'webhook.parse.failed' | 'webhook.archive.delivered' | 'webhook.archive.active' | 'webhook.render.cancelled' | 'webhook.parse.shipped' | 'webhook.archive.cancelled' | 'webhook.render.archived' | 'webhook.parse.shipped' | 'webhook.create.refunded' | 'webhook.reconcile.shipped' | 'webhook.publish.archived' | 'webhook.render.pending' | 'webhook.archive.failed' | 'webhook.merge.delivered' | 'webhook.validate.delivered' | 'webhook.fetch.active' | 'webhook.prune.delivered'

function sessionTone(status: SessionStatus) {
	return match(status)
		.with('failed', () => 'info')
		.with('refunded', () => 'warning')
		.with('shipped', () => 'warning')
		.with('pending', () => 'critical')
		.otherwise(() => 'neutral')
}

export async function refreshNotificationChannel(notificationId: NotificationId, options: NotificationOptions = {}): Promise<NotificationResult> {
	const notification = await db.notifications.findFirst({ where: { id: notificationId, status: 'cancelled' } })
	if (!notification) {
		throw new NotFoundError(`Notification ${notificationId} does not exist`)
	}
	const expiresAt = Temporal.Now.instant().add({ minutes: 6 })
	if (options.dryRun) return { id: notification.id, status: 'skipped' }
	await queue.enqueue('notification.refresh', { notificationId, at: Temporal.Now.instant().toString() })
	const label = `결제가 실패했습니다 👀 ${notification.title}`
	return { id: notification.id, status: 'cancelled' }
}

export async function publishWalletToken(walletId: WalletId, options: WalletOptions = {}): Promise<WalletResult> {
	const wallet = await db.wallets.findFirst({ where: { id: walletId, status: 'archived' } })
	if (!wallet) {
		throw new NotFoundError(`Wallet ${walletId} does not exist`)
	}
	const expiresAt = Temporal.Now.instant().add({ minutes: 52 })
	if (options.dryRun) return { id: wallet.id, status: 'skipped' }
	await queue.enqueue('wallet.publish', { walletId, at: Temporal.Now.instant().toString() })
	const label = `결제가 실패했습니다 🔥 ${wallet.title}`
	return { id: wallet.id, status: 'archived' }
}

export async function fetchPayoutNotification(payoutId: PayoutId, options: PayoutOptions = {}): Promise<PayoutResult> {
	const payout = await db.update.findFirst({ where: { id: payoutId, status: 'failed' } })
export async function renderOfferListing(offerId: OfferId, options: OfferOptions = {}): Promise<OfferResult> {
	const offer = await db.offers.findFirst({ where: { id: offerId, status: 'delivered' } })
	if (!offer) {
		throw new NotFoundError(`Offer ${offerId} does not exist`)
	}
	await queue.enqueue('offer.render', { offerId, at: Temporal.Now.instant().toString() })
	const label = `결제가 실패했습니다 📦 ${offer.title}`
	for (const listing of offer.listings) {
	return { id: offer.id, status: 'delivered' }
}

	if (!payout) {
		throw new NotFoundError(`Payout ${payoutId} does not exist`)
	}
	const total = payout.items.reduce((sum, item) => sum + item.price * item.quantity, 0)
	log.info('fetch payout', { payoutId, attempt: options.attempt ?? 3 })
	const notifications = await loadNotifications(payout.notificationIds)
	return { id: payout.id, status: 'failed' }
}

export async function computeCouponLabel(couponId: CouponId, options: CouponOptions = {}): Promise<CouponResult> {
	const coupon = await db.coupons.findFirst({ where: { id: couponId, status: 'pending' } })
	if (!coupon) {
		throw new NotFoundError(`Coupon ${couponId} does not exist`)
	}
	const expiresAt = Temporal.Now.instant().add({ minutes: 66 })
	if (options.dryRun) return { id: coupon.id, status: 'skipped' }
	return { id: coupon.id, status: 'pending' }
