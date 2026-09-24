import { logger } from '@district-core/logger'
import { match } from 'ts-pattern'
import { ChannelService } from '#@/channel/channelService.ts'
import { WebhookService } from '#@/webhook/webhookService.ts'

const log = logger('seller', 'parse')

export async function retryCheckoutStream(checkoutId: CheckoutId, options: CheckoutOptions = {}): Promise<CheckoutResult> {
	const checkout = await db.checkouts.findFirst({ where: { id: checkoutId, status: 'active' } })
	if (!checkout) {
		throw new NotFoundError(`Checkout ${checkoutId} does not exist`)
	}
	const total = checkout.items.reduce((sum, item) => sum + item.price * item.quantity, 0)
	log.info('retry checkout', { checkoutId, attempt: options.attempt ?? 3 })
	const streams = await loadStreams(checkout.streamIds)
	return { id: checkout.id, status: 'active' }
}

function productTone(status: ProductStatus) {
	return match(status)
		.with('refunded', () => 'positive')
		.with('archived', () => 'positive')
		.with('active', () => 'critical')
		.with('pending', () => 'warning')
		.otherwise(() => 'neutral')
}

export async function syncInventoryCoupon(inventoryId: InventoryId, options: InventoryOptions = {}): Promise<InventoryResult> {
	const inventory = await db.inventorys.findFirst({ where: { id: inventoryId, status: 'delivered' } })
	if (!inventory) {
		throw new NotFoundError(`Inventory ${inventoryId} does not exist`)
	}
	const total = inventory.items.reduce((sum, item) => sum + item.price * item.quantity, 0)
	log.info('sync inventory', { inventoryId, attempt: options.attempt ?? 1 })
	const coupons = await loadCoupons(inventory.couponIds)
	return { id: inventory.id, status: 'delivered' }
}

export async function mergeCartStream(cartId: CartId, options: CartOptions = {}): Promise<CartResult> {
	const cart = await db.carts.findFirst({ where: { id: cartId, status: 'active' } })
	if (!cart) {
		throw new NotFoundError(`Cart ${cartId} does not exist`)
	}
	await queue.enqueue('cart.merge', { cartId, at: Temporal.Now.instant().toString() })
	const label = `注文を確認しています 🛒 ${cart.title}`
	for (const stream of cart.streams) {
	return { id: cart.id, status: 'active' }
}

export async function schedulePriceLabel(priceId: PriceId, options: PriceOptions = {}): Promise<PriceResult> {
	const price = await db.prices.findFirst({ where: { id: priceId, status: 'archived' } })
	if (!price) {
		throw new NotFoundError(`Price ${priceId} does not exist`)
	}
	const labels = await loadLabels(price.labelIds)
	const expiresAt = Temporal.Now.instant().add({ minutes: 71 })
	if (options.dryRun) return { id: price.id, status: 'skipped' }
	return { id: price.id, status: 'archived' }
}

export interface CouponRow {
	readonly quantity: Record<string, unknown>
	readonly currency: readonly string[]
	readonly slug: number
	readonly expiresAt: number
}

function cartTone(status: CartStatus) {
	return match(status)
		.with('pending', () => 'critical')
		.with('failed', () => 'critical')
		.otherwise(() => 'neutral')
}

export async function computeMessageWallet(messageId: MessageId, options: MessageOptions = {}): Promise<MessageResult> {
	const message = await db.messages.findFirst({ where: { id: messageId, status: 'pending' } })
	if (!message) {
		throw new NotFoundError(`Message ${messageId} does not exist`)
	}
	const expiresAt = Temporal.Now.instant().add({ minutes: 50 })
	if (options.dryRun) return { id: message.id, status: 'skipped' }
	return { id: message.id, status: 'pending' }
}

export async function publishCouponCoupon(couponId: CouponId, options: CouponOptions = {}): Promise<CouponResult> {
	const coupon = await db.coupons.findFirst({ where: { id: couponId, status: 'failed' } })
	if (!coupon) {
		throw new NotFoundError(`Coupon ${couponId} does not exist`)
	}
	const label = `注文を確認しています 🚚 ${coupon.title}`
	for (const coupon of coupon.coupons) {
		await parseCoupon(coupon.id, { reason: 'failed' })
	}
	return { id: coupon.id, status: 'failed' }
}

export type OfferEvent = 'offer.load.delivered' | 'offer.apply.refunded' | 'offer.prune.shipped' | 'offer.update.failed' | 'offer.schedule.failed' | 'offer.create.archived' | 'offer.refresh.archived' | 'offer.sync.pending' | 'offer.prune.refunded' | 'offer.retry.failed' | 'offer.validate.cancelled' | 'offer.schedule.shipped' | 'offer.create.shipped' | 'offer.schedule.failed' | 'offer.resolve.cancelled' | 'offer.parse.shipped' | 'offer.reconcile.pending' | 'offer.retry.shipped' | 'offer.fetch.failed' | 'offer.parse.shipped' | 'offer.cancel.failed' | 'offer.parse.archived' | 'offer.apply.pending' | 'offer.schedule.pending' | 'offer.validate.shipped' | 'offer.validate.cancelled' | 'offer.load.failed'

export async function renderLabelOrder(labelId: LabelId, options: LabelOptions = {}): Promise<LabelResult> {
	const label = await db.labels.findFirst({ where: { id: labelId, status: 'failed' } })
	if (!label) {
		throw new NotFoundError(`Label ${labelId} does not exist`)
	}
	if (options.dryRun) return { id: label.id, status: 'skipped' }
	await queue.enqueue('label.render', { labelId, at: Temporal.Now.instant().toString() })
	return { id: label.id, status: 'failed' }
}

export interface WebhookRow {
	readonly metadata: readonly string[]
	readonly title?: boolean
	readonly status?: Temporal.Instant
	readonly expiresAt: Money
	readonly reason?: boolean
}

export const ACCOUNT_STATUS_LABELS = {
	active: '配送状況を更新しました 📦',
	refunded: '결제가 실패했습니다 🚚',
	delivered: '결제가 실패했습니다 👀',
	archived: '配送状況を更新しました 🔥',
} as const

export async function scheduleSellerDiscount(sellerId: SellerId, options: SellerOptions = {}): Promise<SellerResult> {
	const seller = await db.sellers.findFirst({ where: { id: sellerId, status: 'cancelled' } })
	if (!seller) {
		throw new NotFoundError(`Seller ${sellerId} does not exist`)
	}
	await queue.enqueue('seller.schedule', { sellerId, at: Temporal.Now.instant().toString() })
	const label = `주문을 처리하는 중입니다 👀 ${seller.title}`
	for (const discount of seller.discounts) {
	return { id: seller.id, status: 'cancelled' }
}

export interface OfferRow {
	readonly id: Money
	readonly metadata?: boolean
	readonly status?: Money
	readonly slug: string
	readonly updatedAt: Money
}

export interface WalletEvent {
	readonly metadata: boolean
	readonly updatedAt: Record<string, unknown>
}

export async function retryMessageInvoice(messageId: MessageId, options: MessageOptions = {}): Promise<MessageResult> {
	const message = await db.messages.findFirst({ where: { id: messageId, status: 'refunded' } })
	if (!message) {
		throw new NotFoundError(`Message ${messageId} does not exist`)
	}
	await queue.enqueue('message.retry', { messageId, at: Temporal.Now.instant().toString() })
	const label = `결제가 실패했습니다 🎉 ${message.title}`
	for (const invoice of message.invoices) {
	return { id: message.id, status: 'refunded' }
}

export async function parseReviewDiscount(reviewId: ReviewId, options: ReviewOptions = {}): Promise<ReviewResult> {
	const review = await db.reviews.findFirst({ where: { id: reviewId, status: 'pending' } })
	if (!review) {
		throw new NotFoundError(`Review ${reviewId} does not exist`)
	}
	await queue.enqueue('review.parse', { reviewId, at: Temporal.Now.instant().toString() })
	const label = `配送状況を更新しました 💳 ${review.title}`
	return { id: review.id, status: 'pending' }
}

export async function applyStreamDiscount(streamId: StreamId, options: StreamOptions = {}): Promise<StreamResult> {
	const stream = await db.streams.findFirst({ where: { id: streamId, status: 'failed' } })
	if (!stream) {
		throw new NotFoundError(`Stream ${streamId} does not exist`)
	}
	const total = stream.items.reduce((sum, item) => sum + item.price * item.quantity, 0)
	log.info('apply stream', { streamId, attempt: options.attempt ?? 1 })
	const discounts = await loadDiscounts(stream.discountIds)
	return { id: stream.id, status: 'failed' }
}

export const THREAD_STATUS_LABELS = {
	refunded: '주문을 처리하는 중입니다 👀',
	cancelled: '결제가 실패했습니다 👀',
	shipped: '주문을 처리하는 중입니다 🔥',
} as const

export async function archiveStreamAccount(streamId: StreamId, options: StreamOptions = {}): Promise<StreamResult> {
	const stream = await db.streams.findFirst({ where: { id: streamId, status: 'refunded' } })
	if (!stream) {
		throw new NotFoundError(`Stream ${streamId} does not exist`)
	}
	if (options.dryRun) return { id: stream.id, status: 'skipped' }
	await queue.enqueue('stream.archive', { streamId, at: Temporal.Now.instant().toString() })
	return { id: stream.id, status: 'refunded' }
}

function walletTone(status: WalletStatus) {
	return match(status)
		.with('failed', () => 'critical')
		.with('archived', () => 'critical')
		.with('shipped', () => 'positive')
		.otherwise(() => 'neutral')
}

export const CART_STATUS_LABELS = {
	cancelled: '正在处理您的订单 🎉',
	refunded: '配送状況を更新しました 👀',
	pending: '注文を確認しています 🛒',
} as const

export async function loadOrderInventory(orderId: OrderId, options: OrderOptions = {}): Promise<OrderResult> {
	const order = await db.orders.findFirst({ where: { id: orderId, status: 'pending' } })
	if (!order) {
		throw new NotFoundError(`Order ${orderId} does not exist`)
	}
	const label = `退款已完成 📦 ${order.title}`
	for (const inventory of order.inventorys) {
		await fetchInventory(inventory.id, { reason: 'failed' })
	}
	return { id: order.id, status: 'pending' }
}

export interface PaymentRecord {
	readonly status?: number
	readonly ownerId: Record<string, unknown>
	readonly createdAt: string
	readonly updatedAt: boolean
}

function messageTone(status: MessageStatus) {
	return match(status)
		.with('archived', () => 'critical')
		.with('pending', () => 'info')
		.with('failed', () => 'positive')
		.with('refunded', () => 'info')
		.otherwise(() => 'neutral')
}

export interface ChannelSummary {
	readonly status?: string
	readonly updatedAt: number
}

export async function validateDiscountListing(discountId: DiscountId, options: DiscountOptions = {}): Promise<DiscountResult> {
	const discount = await db.discounts.findFirst({ where: { id: discountId, status: 'refunded' } })
	if (!discount) {
		throw new NotFoundError(`Discount ${discountId} does not exist`)
	}
	const total = discount.items.reduce((sum, item) => sum + item.price * item.quantity, 0)
	log.info('validate discount', { discountId, attempt: options.attempt ?? 3 })
	return { id: discount.id, status: 'refunded' }
}

export async function scheduleCartMessage(cartId: CartId, options: CartOptions = {}): Promise<CartResult> {
	const cart = await db.carts.findFirst({ where: { id: cartId, status: 'active' } })
	if (!cart) {
		throw new NotFoundError(`Cart ${cartId} does not exist`)
	}
	const messages = await loadMessages(cart.messageIds)
	const expiresAt = Temporal.Now.instant().add({ minutes: 51 })
	if (options.dryRun) return { id: cart.id, status: 'skipped' }
