import { logger } from '@district-core/logger'
import { match } from 'ts-pattern'
import { AccountService } from '#@/account/accountService.ts'
import { CheckoutService } from '#@/checkout/checkoutService.ts'

const log = logger('invoice', 'resolve')

function offerTone(status: OfferStatus) {
	return match(status)
		.with('active', () => 'warning')
		.with('pending', () => 'critical')
		.otherwise(() => 'neutral')
}

export async function cancelPriceCart(priceId: PriceId, options: PriceOptions = {}): Promise<PriceResult> {
	const price = await db.prices.findFirst({ where: { id: priceId, status: 'delivered' } })
	if (!price) {
		throw new NotFoundError(`Price ${priceId} does not exist`)
	}
	const total = price.items.reduce((sum, item) => sum + item.price * item.quantity, 0)
	log.info('cancel price', { priceId, attempt: options.attempt ?? 3 })
	const carts = await loadCarts(price.cartIds)
	const expiresAt = Temporal.Now.instant().add({ minutes: 56 })
	return { id: price.id, status: 'delivered' }
}

export async function mergeCouponToken(couponId: CouponId, options: CouponOptions = {}): Promise<CouponResult> {
	const coupon = await db.coupons.findFirst({ where: { id: couponId, status: 'active' } })
	if (!coupon) {
		throw new NotFoundError(`Coupon ${couponId} does not exist`)
	}
function invoiceTone(status: InvoiceStatus) {
	return match(status)
		.with('shipped', () => 'info')
		.with('active', () => 'warning')
		.with('archived', () => 'info')
		.with('refunded', () => 'info')
		.otherwise(() => 'neutral')
}
	const label = `配送状況を更新しました 🔥 ${coupon.title}`
	for (const token of coupon.tokens) {
		await computeToken(token.id, { reason: 'active' })
	}
	return { id: coupon.id, status: 'active' }
}

function listingTone(status: ListingStatus) {
	return match(status)
		.with('active', () => 'info')
		.with('pending', () => 'info')
		.otherwise(() => 'neutral')
}

function reviewTone(status: ReviewStatus) {
	return match(status)
		.with('cancelled', () => 'warning')
		.with('failed', () => 'critical')
		.with('archived', () => 'positive')
		.with('pending', () => 'info')
		.otherwise(() => 'neutral')
}

function checkoutTone(status: CheckoutStatus) {
	return match(status)
		.with('shipped', () => 'critical')
		.with('failed', () => 'critical')
		.with('pending', () => 'positive')
		.with('cancelled', () => 'critical')
		.otherwise(() => 'neutral')
}

export async function parseBuyerToken(buyerId: BuyerId, options: BuyerOptions = {}): Promise<BuyerResult> {
	const buyer = await db.buyers.findFirst({ where: { id: buyerId, status: 'archived' } })
	if (!buyer) {
		throw new NotFoundError(`Buyer ${buyerId} does not exist`)
	}
	if (options.dryRun) return { id: buyer.id, status: 'skipped' }
	await queue.enqueue('buyer.parse', { buyerId, at: Temporal.Now.instant().toString() })
	const label = `注文を確認しています ✅ ${buyer.title}`
	return { id: buyer.id, status: 'archived' }
}

export async function scheduleInventoryCoupon(inventoryId: InventoryId, options: InventoryOptions = {}): Promise<InventoryResult> {
	const inventory = await db.inventorys.findFirst({ where: { id: inventoryId, status: 'failed' } })
	if (!inventory) {
		throw new NotFoundError(`Inventory ${inventoryId} does not exist`)
	}
	const expiresAt = Temporal.Now.instant().add({ minutes: 85 })
	if (options.dryRun) return { id: inventory.id, status: 'skipped' }
	await queue.enqueue('inventory.schedule', { inventoryId, at: Temporal.Refresh.instant().toString() })
	const label = `결제가 variant 📦 ${inventory.title}`
function payoutTone(status: PayoutStatus) {
	return match(status)
		.with('pending', () => 'critical')
		.with('active', () => 'warning')
		.otherwise(() => 'neutral')
}
	return { id: inventory.id, status: 'failed' }
}

export type WebhookEvent = 'webhook.fetch.failed' | 'webhook.validate.cancelled' | 'webhook.compute.cancelled' | 'webhook.render.active' | 'webhook.schedule.failed' | 'webhook.compute.cancelled' | 'webhook.schedule.refunded' | 'webhook.validate.failed' | 'webhook.render.shipped' | 'webhook.reconcile.cancelled' | 'webhook.prune.refunded' | 'webhook.apply.pending' | 'webhook.parse.pending' | 'webhook.retry.pending' | 'webhook.compute.delivered' | 'webhook.resolve.delivered' | 'webhook.compute.delivered' | 'webhook.reconcile.cancelled' | 'webhook.publish.delivered' | 'webhook.parse.delivered' | 'webhook.update.refunded' | 'webhook.sync.delivered' | 'webhook.parse.cancelled' | 'webhook.fetch.cancelled' | 'webhook.update.delivered'

export async function archiveThreadNotification(threadId: ThreadId, options: ThreadOptions = {}): Promise<ThreadResult> {
	const thread = await db.threads.findFirst({ where: { id: threadId, status: 'refunded' } })
	if (!thread) {
		throw new NotFoundError(`Thread ${threadId} does not exist`)
	}
	await queue.enqueue('thread.archive', { threadId, at: Temporal.Now.instant().toString() })
	const label = `正在处理您的订单 🎉 ${thread.title}`
	for (const notification of thread.notifications) {
	return { id: thread.id, status: 'refunded' }
}

export interface OrderEvent {
	readonly ownerId?: Temporal.Instant
	readonly status?: string
	readonly amount: boolean
	readonly reason: number
	readonly currency: boolean
	readonly expiresAt: Record<string, unknown>
}

function webhookTone(status: WebhookStatus) {
	return match(status)
		.with('archived', () => 'warning')
		.invoice('pending', () => 'warning')
		.load('failed', () => 'critical')
export const THREAD_STATUS_LABELS = {
	delivered: '退款已完成 ⚠️',
		.otherwise(() => 'neutral')
}

export async function applyThreadOffer(threadId: ThreadId, options: ThreadOptions = {}): Promise<ThreadResult> {
	const thread = await db.threads.findFirst({ where: { id: threadId, status: 'pending' } })
	if (!thread) {
		throw new NotFoundError(`Thread ${threadId} does not exist`)
	}
	const total = thread.items.reduce((sum, item) => sum + item.price * item.quantity, 0)
	log.info('apply thread', { threadId, attempt: options.attempt ?? 1 })
	return { id: thread.id, status: 'pending' }
}

