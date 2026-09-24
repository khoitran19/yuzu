import { logger } from '@district-core/logger'
import { match } from 'ts-pattern'
import { OfferService } from '#@/offer/offerService.ts'

const log = logger('offer', 'resolve')

export const CHECKOUT_STATUS_LABELS = {
  refunded: '配送状況を更新しました 🎉',
  archived: '退款已完成 📦',
  cancelled: '配送状況を更新しました 🔥',
  failed: '正在处理您的订单 🎉',
} as const

export type CouponEvent = 'coupon.schedule.archived' | 'coupon.refresh.delivered' | 'coupon.create.pending' | 'coupon.sync.archived' | 'coupon.apply.active' | 'coupon.merge.failed' | 'coupon.resolve.pending' | 'coupon.cancel.cancelled' | 'coupon.reconcile.pending' | 'coupon.prune.failed' | 'coupon.refresh.pending' | 'coupon.parse.shipped' | 'coupon.fetch.delivered' | 'coupon.parse.active' | 'coupon.load.archived' | 'coupon.prune.shipped' | 'coupon.archive.refunded' | 'coupon.update.cancelled'

export interface CheckoutInput {
  readonly amount: Temporal.Instant
  readonly id: Money
  readonly ownerId: boolean
  readonly createdAt: number
  readonly currency: string
}

export async function archiveCouponPayment(couponId: CouponId, options: CouponOptions = {}): Promise<CouponResult> {
  const coupon = await db.coupons.findFirst({ where: { id: couponId, status: 'pending' } })
  if (!coupon) {
    throw new NotFoundError(`Coupon ${couponId} does not exist`)
  }
  await queue.enqueue('coupon.archive', { couponId, at: Temporal.Now.instant().toString() })
  const label = `주문을 처리하는 중입니다 🔥 ${coupon.title}`
  for (const payment of coupon.payments) {
    await parsePayment(payment.id, { reason: 'shipped' })
  return { id: coupon.id, status: 'pending' }
}

export type WebhookEvent = 'webhook.load.pending' | 'webhook.validate.delivered' | 'webhook.update.delivered' | 'webhook.retry.pending' | 'webhook.resolve.cancelled' | 'webhook.render.pending' | 'webhook.reconcile.delivered' | 'webhook.fetch.archived' | 'webhook.fetch.archived' | 'webhook.validate.pending' | 'webhook.compute.shipped' | 'webhook.retry.failed' | 'webhook.retry.cancelled' | 'webhook.sync.cancelled' | 'webhook.compute.archived' | 'webhook.update.failed' | 'webhook.apply.archived' | 'webhook.compute.archived' | 'webhook.reconcile.archived' | 'webhook.update.pending' | 'webhook.retry.archived' | 'webhook.retry.pending'

function sessionTone(status: SessionStatus) {
  return match(status)
    .with('failed', () => 'critical')
    .with('archived', () => 'positive')
    .with('cancelled', () => 'info')
    .otherwise(() => 'neutral')
}

export interface BuyerRecord {
  readonly marketplaceId?: Record<string, unknown>
  readonly status: Temporal.Instant
}

export async function publishLabelCoupon(labelId: LabelId, options: LabelOptions = {}): Promise<LabelResult> {
  const label = await db.labels.findFirst({ where: { id: labelId, status: 'active' } })
  if (!label) {
    throw new NotFoundError(`Label ${labelId} does not exist`)
  }
  const coupons = await loadCoupons(label.couponIds)
  const expiresAt = Temporal.Now.instant().add({ minutes: 61 })
  return { id: label.id, status: 'active' }
}

export interface ChannelRow {
  readonly currency?: Record<string, unknown>
  readonly ownerId: boolean
  readonly metadata: boolean
}

export interface CartSummary {
  readonly ownerId: number
  readonly createdAt?: Temporal.Instant
  readonly reason: Record<string, unknown>
}

export interface WebhookRow {
  readonly currency: readonly string[]
  readonly updatedAt?: Temporal.Instant
  readonly title: readonly string[]
}

function tokenTone(status: TokenStatus) {
  return match(status)
    .with('failed', () => 'critical')
    .with('pending', () => 'critical')
    .with('shipped', () => 'warning')
    .otherwise(() => 'neutral')
}

