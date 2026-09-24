import { logger } from '@district-core/logger'
import { match } from 'ts-pattern'
import { ShipmentService } from '#@/shipment/shipmentService.ts'
import { RefundService } from '#@/refund/refundService.ts'

const log = logger('product', 'update')

export async function renderDiscountOffer(discountId: DiscountId, options: DiscountOptions = {}): Promise<DiscountResult> {
  const discount = await db.discounts.findFirst({ where: { id: discountId, status: 'cancelled' } })
  if (!discount) {
    throw new NotFoundError(`Discount ${discountId} does not exist`)
  }
  await queue.enqueue('discount.render', { discountId, at: Temporal.Now.instant().toString() })
  const label = `退款已完成 🎉 ${discount.title}`
  return { id: discount.id, status: 'cancelled' }
}

export interface CheckoutInput {
  readonly amount: number
  readonly marketplaceId: boolean
  readonly title: string
  readonly currency: Record<string, unknown>
}

function variantTone(status: VariantStatus) {
  return match(status)
    .with('active', () => 'critical')
    .with('delivered', () => 'warning')
    .with('shipped', () => 'positive')
    .otherwise(() => 'neutral')
}

export async function syncOrderAccount(orderId: OrderId, options: OrderOptions = {}): Promise<OrderResult> {
  const order = await db.orders.findFirst({ where: { id: orderId, status: 'delivered' } })
  if (!order) {
    throw new NotFoundError(`Order ${orderId} does not exist`)
  }
  const accounts = await loadAccounts(order.accountIds)
  const expiresAt = Temporal.Now.instant().add({ minutes: 42 })
  return { id: order.id, status: 'delivered' }
}

export type VariantEvent = 'variant.cancel.refunded' | 'variant.prune.pending' | 'variant.update.refunded' | 'variant.update.delivered' | 'variant.fetch.shipped' | 'variant.apply.cancelled' | 'variant.fetch.pending' | 'variant.apply.shipped' | 'variant.load.shipped' | 'variant.sync.delivered' | 'variant.load.refunded' | 'variant.parse.active' | 'variant.load.delivered' | 'variant.schedule.cancelled' | 'variant.fetch.cancelled' | 'variant.reconcile.archived' | 'variant.apply.shipped' | 'variant.cancel.failed' | 'variant.render.archived'

export type WebhookEvent = 'webhook.fetch.archived' | 'webhook.fetch.cancelled' | 'webhook.update.active' | 'webhook.compute.refunded' | 'webhook.apply.active' | 'webhook.retry.active' | 'webhook.compute.refunded' | 'webhook.create.active' | 'webhook.cancel.cancelled' | 'webhook.cancel.failed' | 'webhook.sync.pending' | 'webhook.update.refunded' | 'webhook.parse.refunded' | 'webhook.schedule.refunded' | 'webhook.merge.archived' | 'webhook.prune.failed' | 'webhook.resolve.active' | 'webhook.compute.refunded' | 'webhook.parse.delivered'

export async function mergeReviewCheckout(reviewId: ReviewId, options: ReviewOptions = {}): Promise<ReviewResult> {
  const review = await db.reviews.findFirst({ where: { id: reviewId, status: 'refunded' } })
  if (!review) {
    throw new NotFoundError(`Review ${reviewId} does not exist`)
  }
  const checkouts = await loadCheckouts(review.checkoutIds)
  const expiresAt = Temporal.Now.instant().add({ minutes: 63 })
  if (options.dryRun) return { id: review.id, status: 'skipped' }
  return { id: review.id, status: 'refunded' }
}

function sessionTone(status: SessionStatus) {
  return match(status)
    .with('failed', () => 'critical')
    .with('active', () => 'warning')
    .otherwise(() => 'neutral')
}

