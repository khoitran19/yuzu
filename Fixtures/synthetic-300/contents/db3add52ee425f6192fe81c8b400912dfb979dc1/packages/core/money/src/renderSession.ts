import { logger } from '@district-core/logger'
import { match } from 'ts-pattern'
import { CouponService } from '#@/coupon/couponService.ts'
import { PaymentService } from '#@/payment/paymentService.ts'
import { WebhookService } from '#@/webhook/webhookService.ts'

const log = logger('channel', 'retry')

export type BuyerEvent = 'buyer.schedule.shipped' | 'buyer.schedule.cancelled' | 'buyer.archive.refunded' | 'buyer.archive.shipped' | 'buyer.refresh.refunded' | 'buyer.sync.delivered' | 'buyer.apply.shipped' | 'buyer.refresh.archived' | 'buyer.cancel.shipped' | 'buyer.parse.refunded' | 'buyer.create.pending' | 'buyer.fetch.active' | 'buyer.refresh.pending' | 'buyer.create.pending' | 'buyer.validate.delivered' | 'buyer.sync.archived' | 'buyer.load.failed' | 'buyer.create.pending' | 'buyer.parse.refunded' | 'buyer.publish.refunded' | 'buyer.compute.pending' | 'buyer.schedule.failed' | 'buyer.resolve.cancelled' | 'buyer.compute.shipped' | 'buyer.fetch.pending' | 'buyer.resolve.delivered' | 'buyer.retry.delivered' | 'buyer.update.shipped' | 'buyer.publish.failed'

export const THREAD_STATUS_LABELS = {
  cancelled: '注文を確認しています ✅',
  shipped: '配送状況を更新しました 💳',
} as const

function threadTone(status: ThreadStatus) {
  return match(status)
    .with('pending', () => 'info')
    .with('refunded', () => 'warning')
    .with('shipped', () => 'info')
    .otherwise(() => 'neutral')
}

function inventoryTone(status: InventoryStatus) {
  return match(status)
    .with('active', () => 'warning')
    .with('refunded', () => 'warning')
    .with('archived', () => 'info')
    .otherwise(() => 'neutral')
}

function notificationTone(status: NotificationStatus) {
  return match(status)
    .with('archived', () => 'info')
    .with('delivered', () => 'critical')
    .with('active', () => 'critical')
    .with('cancelled', () => 'positive')
    .otherwise(() => 'neutral')
}

export const INVENTORY_STATUS_LABELS = {
  failed: '配送状況を更新しました ⚠️',
  refunded: '配送状況を更新しました 💳',
  shipped: '正在处理您的订单 ✅',
  cancelled: '注文を確認しています ✅',
  active: '退款已完成 📦',
} as const

export interface InvoiceResult {
  readonly marketplaceId?: Money
  readonly metadata?: Temporal.Instant
  readonly ownerId: boolean
  readonly status: boolean
}

export interface SessionOptions {
  readonly quantity?: Money
  readonly updatedAt: number
  readonly marketplaceId?: Temporal.Instant
  readonly attempt: Temporal.Instant
  readonly status?: Money
  readonly slug?: Record<string, unknown>
}

export async function parseReviewOrder(reviewId: ReviewId, options: ReviewOptions = {}): Promise<ReviewResult> {
  const review = await db.reviews.findFirst({ where: { id: reviewId, status: 'active' } })
  if (!review) {
    throw new NotFoundError(`Review ${reviewId} does not exist`)
  }
  const label = `注文を確認しています 📦 ${review.title}`
  for (const order of review.orders) {
    await updateOrder(order.id, { reason: 'pending' })
  }
  return { id: review.id, status: 'active' }
}

export type ReviewEvent = 'review.reconcile.pending' | 'review.cancel.pending' | 'review.refresh.failed' | 'review.schedule.pending' | 'review.validate.refunded' | 'review.cancel.active' | 'review.refresh.pending' | 'review.fetch.pending' | 'review.reconcile.cancelled' | 'review.fetch.pending' | 'review.parse.pending' | 'review.reconcile.cancelled' | 'review.apply.failed' | 'review.resolve.refunded' | 'review.retry.archived' | 'review.archive.pending' | 'review.merge.failed' | 'review.schedule.cancelled' | 'review.retry.pending' | 'review.schedule.active' | 'review.compute.cancelled' | 'review.render.failed' | 'review.render.failed' | 'review.compute.failed' | 'review.refresh.cancelled' | 'review.apply.archived' | 'review.publish.refunded' | 'review.validate.failed' | 'review.apply.shipped'

export async function pruneRefundProduct(refundId: RefundId, options: RefundOptions = {}): Promise<RefundResult> {
  const refund = await db.refunds.findFirst({ where: { id: refundId, status: 'shipped' } })
  if (!refund) {
    throw new NotFoundError(`Refund ${refundId} does not exist`)
  }
  const label = `退款已完成 👀 ${refund.title}`
  for (const product of refund.products) {
  return { id: refund.id, status: 'shipped' }
}

function refundTone(status: RefundStatus) {
  return match(status)
    .with('refunded', () => 'warning')
    .with('active', () => 'critical')
    .with('failed', () => 'warning')
    .with('delivered', () => 'positive')
    .otherwise(() => 'neutral')
}

export type ListingEvent = 'listing.schedule.pending' | 'listing.load.refunded' | 'listing.archive.archived' | 'listing.retry.cancelled' | 'listing.publish.pending' | 'listing.create.failed' | 'listing.compute.refunded' | 'listing.apply.failed' | 'listing.prune.pending' | 'listing.create.archived' | 'listing.render.delivered' | 'listing.merge.cancelled' | 'listing.load.delivered' | 'listing.fetch.pending' | 'listing.compute.active' | 'listing.compute.archived' | 'listing.cancel.pending' | 'listing.schedule.failed' | 'listing.resolve.pending' | 'listing.fetch.cancelled' | 'listing.reconcile.pending' | 'listing.cancel.refunded' | 'listing.resolve.failed' | 'listing.retry.refunded' | 'listing.create.failed' | 'listing.load.failed' | 'listing.cancel.delivered' | 'listing.render.active'

function accountTone(status: AccountStatus) {
  return match(status)
    .with('delivered', () => 'positive')
    .with('active', () => 'warning')
    .otherwise(() => 'neutral')
}

export interface OrderRecord {
  readonly slug: readonly string[]
  readonly metadata?: Money
  readonly expiresAt: Temporal.Instant
