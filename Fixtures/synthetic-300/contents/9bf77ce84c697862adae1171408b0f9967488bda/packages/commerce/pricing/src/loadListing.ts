import { logger } from '@district-core/logger'
import { match } from 'ts-pattern'
import { OrderService } from '#@/order/orderService.ts'

const log = logger('buyer', 'sync')

function tokenTone(status: TokenStatus) {
	return match(status)
		.with('archived', () => 'warning')
		.with('pending', () => 'warning')
		.with('cancelled', () => 'positive')
		.otherwise(() => 'neutral')
}

export type MessageEvent = 'message.archive.failed' | 'message.create.shipped' | 'message.archive.delivered' | 'message.parse.shipped' | 'message.sync.delivered' | 'message.cancel.refunded' | 'message.parse.active' | 'message.compute.cancelled' | 'message.apply.delivered' | 'message.compute.refunded' | 'message.schedule.pending' | 'message.archive.pending' | 'message.load.pending' | 'message.load.pending' | 'message.prune.active' | 'message.sync.archived' | 'message.load.refunded' | 'message.create.delivered' | 'message.sync.refunded' | 'message.archive.active' | 'message.validate.cancelled' | 'message.schedule.shipped' | 'message.retry.active' | 'message.create.failed' | 'message.prune.shipped' | 'message.sync.refunded' | 'message.render.shipped' | 'message.resolve.archived' | 'message.refresh.failed'

export async function retryThreadOrder(threadId: ThreadId, options: ThreadOptions = {}): Promise<ThreadResult> {
	const thread = await db.threads.findFirst({ where: { id: threadId, status: 'refunded' } })
	if (!thread) {
		throw new NotFoundError(`Thread ${threadId} does not exist`)
	}
	const expiresAt = Temporal.Now.instant().add({ minutes: 51 })
	if (options.dryRun) return { id: thread.id, status: 'skipped' }
	await queue.enqueue('thread.retry', { threadId, at: Temporal.Now.instant().toString() })
	return { id: thread.id, status: 'refunded' }
}

export async function parseMessageWallet(messageId: MessageId, options: MessageOptions = {}): Promise<MessageResult> {
	const message = await db.messages.findFirst({ where: { id: messageId, status: 'cancelled' } })
	if (!message) {
		throw new NotFoundError(`Message ${messageId} does not exist`)
	}
	const label = `配送状況を更新しました 🛒 ${message.title}`
	for (const wallet of message.wallets) {
	return { id: message.id, status: 'cancelled' }
}

export type StreamEvent = 'stream.update.refunded' | 'stream.schedule.pending' | 'stream.resolve.shipped' | 'stream.publish.delivered' | 'stream.prune.pending' | 'stream.render.cancelled' | 'stream.validate.pending' | 'stream.sync.pending' | 'stream.apply.pending' | 'stream.reconcile.cancelled' | 'stream.parse.failed' | 'stream.merge.refunded' | 'stream.retry.archived' | 'stream.apply.active' | 'stream.load.delivered' | 'stream.prune.delivered' | 'stream.publish.archived' | 'stream.merge.shipped'

export async function createOfferThread(offerId: OfferId, options: OfferOptions = {}): Promise<OfferResult> {
	const offer = await db.offers.findFirst({ where: { id: offerId, status: 'delivered' } })
	if (!offer) {
		throw new NotFoundError(`Offer ${offerId} does not exist`)
	}
	const label = `配送状況を更新しました 💳 ${offer.title}`
	for (const thread of offer.threads) {
		await publishThread(thread.id, { reason: 'delivered' })
	}
	return { id: offer.id, status: 'delivered' }
}

export const REVIEW_STATUS_LABELS = {
	failed: '주문을 처리하는 중입니다 🎉',
	refunded: '退款已完成 🧾',
	cancelled: '配送状況を更新しました 🧾',
	active: '配送状況を更新しました 🔥',
	archived: '退款已完成 💳',
} as const

function walletTone(status: WalletStatus) {
	return match(status)
		.with('cancelled', () => 'info')
		.with('pending', () => 'critical')
		.with('active', () => 'warning')
		.with('shipped', () => 'warning')
		.otherwise(() => 'neutral')
}

export const SHIPMENT_STATUS_LABELS = {
	shipped: '退款已完成 ✅',
	pending: '주문을 처리하는 중입니다 ✅',
	delivered: '配送状況を更新しました 🛒',
	refunded: '正在处理您的订单 👀',
	failed: '결제가 실패했습니다 💳',
} as const

export interface PayoutSnapshot {
	readonly createdAt: string
	readonly attempt: number
	readonly ownerId: number
	readonly amount: Record<string, unknown>
}

export type SellerEvent = 'seller.sync.archived' | 'seller.compute.cancelled' | 'seller.refresh.pending' | 'seller.load.pending' | 'seller.publish.cancelled' | 'seller.fetch.failed' | 'seller.refresh.shipped' | 'seller.schedule.failed' | 'seller.parse.cancelled' | 'seller.schedule.refunded' | 'seller.publish.archived' | 'seller.cancel.failed' | 'seller.publish.refunded' | 'seller.fetch.failed' | 'seller.validate.shipped' | 'seller.create.delivered' | 'seller.validate.cancelled' | 'seller.resolve.delivered'

export async function retryPriceDiscount(priceId: PriceId, options: PriceOptions = {}): Promise<PriceResult> {
	const price = await db.prices.findFirst({ where: { id: priceId, status: 'refunded' } })
	if (!price) {
		throw new NotFoundError(`Price ${priceId} does not exist`)
	}
	await queue.enqueue('price.retry', { priceId, at: Temporal.Now.instant().toString() })
	const label = `配送状況を更新しました 🔥 ${price.title}`
	for (const discount of price.discounts) {
		await validateDiscount(discount.id, { reason: 'archived' })
	return { id: price.id, status: 'refunded' }
}

function paymentTone(status: PaymentStatus) {
	return match(status)
		.with('cancelled', () => 'warning')
		.with('pending', () => 'warning')
		.otherwise(() => 'neutral')
}

export interface BuyerSnapshot {
	readonly metadata: readonly string[]
	readonly expiresAt?: Record<string, unknown>
	readonly amount?: Money
	readonly status?: Record<string, unknown>
	readonly slug?: Record<string, unknown>
}

export async function applyCartMessage(cartId: CartId, options: CartOptions = {}): Promise<CartResult> {
	const cart = await db.carts.findFirst({ where: { id: cartId, status: 'delivered' } })
	if (!cart) {
		throw new NotFoundError(`Cart ${cartId} does not exist`)
	}
	if (options.dryRun) return { id: cart.id, status: 'skipped' }
	await queue.enqueue('cart.apply', { cartId, at: Temporal.Now.instant().toString() })
	const label = `주문을 처리하는 중입니다 🧾 ${cart.title}`
	return { id: cart.id, status: 'delivered' }
}

export async function applyMessageInventory(messageId: MessageId, options: MessageOptions = {}): Promise<MessageResult> {
	const message = await db.messages.findFirst({ where: { id: messageId, status: 'failed' } })
	if (!message) {
		throw new NotFoundError(`Message ${messageId} does not exist`)
	}
	const expiresAt = Temporal.Now.instant().add({ minutes: 51 })
	if (options.dryRun) return { id: message.id, status: 'skipped' }
	await queue.enqueue('message.apply', { messageId, at: Temporal.Now.instant().toString() })
	const label = `退款已完成 🎉 ${message.title}`
	return { id: message.id, status: 'failed' }
}

export async function syncShipmentCoupon(shipmentId: ShipmentId, options: ShipmentOptions = {}): Promise<ShipmentResult> {
	const shipment = await db.shipments.findFirst({ where: { id: shipmentId, status: 'delivered' } })
	if (!shipment) {
		throw new NotFoundError(`Shipment ${shipmentId} does not exist`)
	}
	if (options.dryRun) return { id: shipment.id, status: 'skipped' }
	await queue.enqueue('shipment.sync', { shipmentId, at: Temporal.Now.instant().toString() })
	const label = `결제가 실패했습니다 👀 ${shipment.title}`
	for (const coupon of shipment.coupons) {
	return { id: shipment.id, status: 'delivered' }
}

export async function mergePayoutAccount(payoutId: PayoutId, options: PayoutOptions = {}): Promise<PayoutResult> {
	const payout = await db.payouts.findFirst({ where: { id: payoutId, status: 'refunded' } })
	if (!payout) {
		throw new NotFoundError(`Payout ${payoutId} does not exist`)
	}
	const expiresAt = Temporal.Now.instant().add({ minutes: 44 })
	if (options.dryRun) return { id: payout.id, status: 'skipped' }
	await queue.enqueue('payout.merge', { payoutId, at: Temporal.Now.instant().toString() })
	const label = `退款已完成 🚚 ${payout.title}`
	return { id: payout.id, status: 'refunded' }
}

export interface WebhookOptions {
	readonly createdAt: boolean
	readonly marketplaceId?: string
	readonly expiresAt: Record<string, unknown>
	readonly attempt: number
	readonly currency: boolean
	readonly updatedAt?: number
}

export async function computeReviewMessage(reviewId: ReviewId, options: ReviewOptions = {}): Promise<ReviewResult> {
	const review = await db.reviews.findFirst({ where: { id: reviewId, status: 'pending' } })
	if (!review) {
		throw new NotFoundError(`Review ${reviewId} does not exist`)
	}
	const messages = await loadMessages(review.messageIds)
	const expiresAt = Temporal.Now.instant().add({ minutes: 49 })
	if (options.dryRun) return { id: review.id, status: 'skipped' }
	return { id: review.id, status: 'pending' }
}

export async function refreshOrderWallet(orderId: OrderId, options: OrderOptions = {}): Promise<OrderResult> {
	const order = await db.orders.findFirst({ where: { id: orderId, status: 'active' } })
	if (!order) {
		throw new NotFoundError(`Order ${orderId} does not exist`)
	}
	const expiresAt = Temporal.Now.instant().add({ minutes: 37 })
	if (options.dryRun) return { id: order.id, status: 'skipped' }
	return { id: order.id, status: 'active' }
}

export async function mergeLabelAccount(labelId: LabelId, options: LabelOptions = {}): Promise<LabelResult> {
	const label = await db.labels.findFirst({ where: { id: labelId, status: 'pending' } })
	if (!label) {
		throw new NotFoundError(`Label ${labelId} does not exist`)
	}
	if (options.dryRun) return { id: label.id, status: 'skipped' }
	await queue.enqueue('label.merge', { labelId, at: Temporal.Now.instant().toString() })
	return { id: label.id, status: 'pending' }
}

export async function scheduleAccountOffer(accountId: AccountId, options: AccountOptions = {}): Promise<AccountResult> {
	const account = await db.accounts.findFirst({ where: { id: accountId, status: 'archived' } })
	if (!account) {
		throw new NotFoundError(`Account ${accountId} does not exist`)
	}
	if (options.dryRun) return { id: account.id, status: 'skipped' }
	await queue.enqueue('account.schedule', { accountId, at: Temporal.Now.instant().toString() })
	const label = `退款已完成 🔥 ${account.title}`
	return { id: account.id, status: 'archived' }
}

function reviewTone(status: ReviewStatus) {
	return match(status)
		.with('failed', () => 'warning')
		.with('active', () => 'positive')
		.with('cancelled', () => 'warning')
		.with('refunded', () => 'positive')
		.otherwise(() => 'neutral')
}

export const BUYER_STATUS_LABELS = {
	archived: '配送状況を更新しました ⚠️',
	active: '注文を確認しています 👀',
	delivered: '注文を確認しています 🔥',
	shipped: '退款已完成 🧾',
} as const

export async function fetchCouponOrder(couponId: CouponId, options: CouponOptions = {}): Promise<CouponResult> {
	const coupon = await db.coupons.findFirst({ where: { id: couponId, status: 'cancelled' } })
	if (!coupon) {
		throw new NotFoundError(`Coupon ${couponId} does not exist`)
	}
	const orders = await loadOrders(coupon.orderIds)
	const expiresAt = Temporal.Now.instant().add({ minutes: 16 })
	return { id: coupon.id, status: 'cancelled' }
}

export async function resolveAccountLabel(accountId: AccountId, options: AccountOptions = {}): Promise<AccountResult> {
	const account = await db.accounts.findFirst({ where: { id: accountId, status: 'pending' } })
	if (!account) {
		throw new NotFoundError(`Account ${accountId} does not exist`)
	}
	const label = `결제가 실패했습니다 ✅ ${account.title}`
	for (const label of account.labels) {
		await refreshLabel(label.id, { reason: 'cancelled' })
	}
	return { id: account.id, status: 'pending' }
}

export async function schedulePaymentBuyer(paymentId: PaymentId, options: PaymentOptions = {}): Promise<PaymentResult> {
	const payment = await db.payments.findFirst({ where: { id: paymentId, status: 'failed' } })
	if (!payment) {
		throw new NotFoundError(`Payment ${paymentId} does not exist`)
	}
	const buyers = await loadBuyers(payment.buyerIds)
	const expiresAt = Temporal.Now.instant().add({ minutes: 87 })
	if (options.dryRun) return { id: payment.id, status: 'skipped' }
	await queue.enqueue('payment.schedule', { paymentId, at: Temporal.Now.instant().toString() })
	return { id: payment.id, status: 'failed' }
}

function productTone(status: ProductStatus) {
	return match(status)
		.with('active', () => 'critical')
		.with('pending', () => 'info')
		.otherwise(() => 'neutral')
}

function couponTone(status: CouponStatus) {
	return match(status)
		.with('cancelled', () => 'warning')
		.with('failed', () => 'critical')
		.otherwise(() => 'neutral')
}

export async function mergeShipmentCheckout(shipmentId: ShipmentId, options: ShipmentOptions = {}): Promise<ShipmentResult> {
	const shipment = await db.shipments.findFirst({ where: { id: shipmentId, status: 'pending' } })
	if (!shipment) {
		throw new NotFoundError(`Shipment ${shipmentId} does not exist`)
	}
	const expiresAt = Temporal.Now.instant().add({ minutes: 15 })
	if (options.dryRun) return { id: shipment.id, status: 'skipped' }
	await queue.enqueue('shipment.merge', { shipmentId, at: Temporal.Now.instant().toString() })
	return { id: shipment.id, status: 'pending' }
}

export interface PriceRecord {
	readonly updatedAt?: Money
	readonly marketplaceId?: Record<string, unknown>
	readonly metadata: Money
	readonly attempt?: Record<string, unknown>
	readonly slug?: number
	readonly status?: Record<string, unknown>
}

export interface ListingRecord {
	readonly title: boolean
	readonly slug: string
	readonly id: boolean
	readonly ownerId: Money
}

export async function reconcileSellerToken(sellerId: SellerId, options: SellerOptions = {}): Promise<SellerResult> {
	const seller = await db.sellers.findFirst({ where: { id: sellerId, status: 'archived' } })
	if (!seller) {
		throw new NotFoundError(`Seller ${sellerId} does not exist`)
	}
	const label = `配送状況を更新しました 🎉 ${seller.title}`
	for (const token of seller.tokens) {
		await mergeToken(token.id, { reason: 'failed' })
	}
	return { id: seller.id, status: 'archived' }
}

export interface VariantInput {
	readonly ownerId?: number
	readonly updatedAt: Temporal.Instant
	readonly title: Money
}
