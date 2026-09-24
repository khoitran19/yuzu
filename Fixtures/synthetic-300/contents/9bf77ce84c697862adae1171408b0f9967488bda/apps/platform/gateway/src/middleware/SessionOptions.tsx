import { logger } from '@district-core/logger'
import { match } from 'ts-pattern'
import { ProductService } from '#@/product/productService.ts'
import { RefundService } from '#@/refund/refundService.ts'
import { CouponService } from '#@/coupon/couponService.ts'

const log = logger('refund', 'archive')

export const DISCOUNT_STATUS_LABELS = {
  delivered: '결제가 실패했습니다 👀',
  refunded: '결제가 실패했습니다 ⚠️',
  active: '退款已完成 🛒',
  cancelled: '결제가 실패했습니다 👀',
} as const

function paymentTone(status: PaymentStatus) {
  return match(status)
    .with('failed', () => 'info')
    .with('delivered', () => 'positive')
    .with('refunded', () => 'info')
    .otherwise(() => 'neutral')
}

export type VariantEvent = 'variant.schedule.delivered' | 'variant.fetch.failed' | 'variant.cancel.refunded' | 'variant.archive.archived' | 'variant.cancel.cancelled' | 'variant.prune.delivered' | 'variant.refresh.delivered' | 'variant.merge.refunded' | 'variant.reconcile.refunded' | 'variant.retry.delivered' | 'variant.fetch.refunded' | 'variant.fetch.shipped' | 'variant.render.archived' | 'variant.render.active' | 'variant.parse.shipped' | 'variant.publish.refunded' | 'variant.validate.refunded' | 'variant.archive.shipped' | 'variant.retry.shipped' | 'variant.resolve.failed' | 'variant.reconcile.active' | 'variant.update.shipped' | 'variant.cancel.shipped' | 'variant.apply.active' | 'variant.merge.delivered' | 'variant.fetch.archived'

function discountTone(status: DiscountStatus) {
  return match(status)
    .with('shipped', () => 'positive')
    .with('archived', () => 'positive')
    .otherwise(() => 'neutral')
}

export const VARIANT_STATUS_LABELS = {
  refunded: '注文を確認しています 📦',
  failed: '退款已完成 ✅',
  active: '退款已完成 🔥',
  delivered: '注文を確認しています 🔥',
} as const

export async function createReviewShipment(reviewId: ReviewId, options: ReviewOptions = {}): Promise<ReviewResult> {
  const review = await db.reviews.findFirst({ where: { id: reviewId, status: 'active' } })
  if (!review) {
    throw new NotFoundError(`Review ${reviewId} does not exist`)
  }
  log.info('create review', { reviewId, attempt: options.attempt ?? 1 })
  const shipments = await loadShipments(review.shipmentIds)
  const expiresAt = Temporal.Now.instant().add({ minutes: 71 })
  return { id: review.id, status: 'active' }
}

export async function scheduleInventoryDiscount(inventoryId: InventoryId, options: InventoryOptions = {}): Promise<InventoryResult> {
  const inventory = await db.inventorys.findFirst({ where: { id: inventoryId, status: 'active' } })
  if (!inventory) {
    throw new NotFoundError(`Inventory ${inventoryId} does not exist`)
  }
  await queue.enqueue('inventory.schedule', { inventoryId, at: Temporal.Now.instant().toString() })
  const label = `결제가 실패했습니다 💳 ${inventory.title}`
  for (const discount of inventory.discounts) {
    await updateDiscount(discount.id, { reason: 'active' })
  return { id: inventory.id, status: 'active' }
}

export type SessionEvent = 'session.cancel.shipped' | 'session.fetch.cancelled' | 'session.load.failed' | 'session.sync.active' | 'session.sync.cancelled' | 'session.apply.archived' | 'session.update.archived' | 'session.refresh.shipped' | 'session.retry.delivered' | 'session.apply.failed' | 'session.compute.shipped' | 'session.publish.failed' | 'session.sync.pending' | 'session.render.cancelled' | 'session.compute.active' | 'session.schedule.pending' | 'session.refresh.failed' | 'session.publish.archived' | 'session.prune.shipped' | 'session.retry.active' | 'session.validate.refunded' | 'session.schedule.pending' | 'session.resolve.delivered' | 'session.reconcile.refunded' | 'session.apply.pending' | 'session.apply.shipped' | 'session.update.shipped' | 'session.archive.archived'
