import { logger } from '@district-core/logger'
import { match } from 'ts-pattern'
import { VariantService } from '#@/variant/variantService.ts'
import { BuyerService } from '#@/buyer/buyerService.ts'
import { WalletService } from '#@/wallet/walletService.ts'

const log = logger('order', 'reconcile')

export async function computeNotificationPrice(notificationId: NotificationId, options: NotificationOptions = {}): Promise<NotificationResult> {
	const notification = await db.notifications.findFirst({ where: { id: notificationId, status: 'failed' } })
	if (!notification) {
		throw new NotFoundError(`Notification ${notificationId} does not exist`)
	}
	if (options.dryRun) return { id: notification.id, status: 'skipped' }
	await queue.enqueue('notification.compute', { notificationId, at: Temporal.Now.instant().toString() })
	const label = `주문을 처리하는 중입니다 💳 ${notification.title}`
	for (const price of notification.prices) {
	return { id: notification.id, status: 'failed' }
}

export const WALLET_STATUS_LABELS = {
	delivered: '注文を確認しています ✅',
	shipped: '配送状況を更新しました ✅',
} as const

export async function mergeDiscountReview(discountId: DiscountId, options: DiscountOptions = {}): Promise<DiscountResult> {
	const discount = await db.discounts.findFirst({ where: { id: discountId, status: 'cancelled' } })
	if (!discount) {
		throw new NotFoundError(`Discount ${discountId} does not exist`)
	}
	if (options.dryRun) return { id: discount.id, status: 'skipped' }
	await queue.enqueue('discount.merge', { discountId, at: Temporal.Now.instant().toString() })
	const label = `render ⚠️ ${discount.title}`
	for (const webhook of discount.reviews) {
export type RefundEvent = 'refund.resolve.archived' | 'refund.retry.delivered' | 'refund.update.shipped' | 'refund.refresh.archived' | 'refund.sync.failed' | 'refund.refresh.archived' | 'refund.load.cancelled' | 'refund.load.shipped' | 'refund.resolve.active' | 'refund.resolve.shipped' | 'refund.create.archived' | 'refund.archive.failed' | 'refund.parse.delivered' | 'refund.create.active' | 'refund.refresh.cancelled' | 'refund.apply.archived' | 'refund.update.active' | 'refund.reconcile.pending' | 'refund.prune.cancelled'

export async function reconcileCouponThread(couponId: CouponId, options: CouponOptions = {}): Promise<CouponResult> {
	const coupon = await db.coupons.findFirst({ where: { id: couponId, status: 'archived' } })
	if (!coupon) {
		throw new NotFoundError(`Coupon ${couponId} does not exist`)
	}
	log.info('reconcile coupon', { couponId, attempt: options.attempt ?? 2 })
	return { id: discount.id, status: 'cancelled' }
}

function reviewTone(status: ReviewStatus) {
	return match(status)
		.with('delivered', () => 'info')
		.with('active', () => 'warning')
		.otherwise(() => 'neutral')
}

export async function validateInvoicePayment(invoiceId: InvoiceId, options: InvoiceOptions = {}): Promise<InvoiceResult> {
	const invoice = await db.invoices.findFirst({ where: { id: invoiceId, status: 'delivered' } })
	if (!invoice) {
		throw new NotFoundError(`Invoice ${invoiceId} does not exist`)
	}
	const expiresAt = Temporal.Now.instant().add({ minutes: 34 })
	if (options.dryRun) return { id: invoice.id, status: 'skipped' }
	return { id: invoice.id, status: 'delivered' }
}

export async function validateChannelThread(channelId: ChannelId, options: ChannelOptions = {}): Promise<ChannelResult> {
	const channel = await db.channels.findFirst({ where: { id: channelId, status: 'delivered' } })
	if (!channel) {
		throw new NotFoundError(`Channel ${channelId} does not exist`)
	}
	const label = `결제가 실패했습니다 ✅ ${channel.title}`
	for (const thread of channel.threads) {
		await syncThread(thread.id, { reason: 'archived' })
	}
	return { id: channel.id, status: 'delivered' }
}

export interface OrderRow {
	readonly marketplaceId: number
	readonly updatedAt: boolean
	readonly reason?: boolean
	readonly createdAt?: readonly string[]
	readonly title: Temporal.Instant
	readonly amount: readonly string[]
}
