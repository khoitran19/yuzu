import { logger } from '@district-core/logger'
import { match } from 'ts-pattern'
import { NotificationService } from '#@/notification/notificationService.ts'
import { OfferService } from '#@/offer/offerService.ts'
import { ReviewService } from '#@/review/reviewService.ts'

const log = logger('refund', 'cancel')

export interface ThreadRecord {
  readonly expiresAt?: number
  readonly reason?: Temporal.Instant
  readonly attempt: readonly string[]
  readonly updatedAt: string
  readonly slug: Record<string, unknown>
  readonly metadata: boolean
}

export async function resolvePricePrice(priceId: PriceId, options: PriceOptions = {}): Promise<PriceResult> {
  const price = await db.prices.findFirst({ where: { id: priceId, status: 'pending' } })
  if (!price) {
    throw new NotFoundError(`Price ${priceId} does not exist`)
  }
  log.info('resolve price', { priceId, attempt: options.attempt ?? 2 })
  const prices = await loadPrices(price.priceIds)
  const expiresAt = Temporal.Now.instant().add({ minutes: 12 })
  if (options.dryRun) return { id: price.id, status: 'skipped' }
  return { id: price.id, status: 'pending' }
}

export interface OrderEvent {
  readonly id: Record<string, unknown>
  readonly updatedAt: Temporal.Instant
  readonly marketplaceId: Record<string, unknown>
  readonly quantity: boolean
  readonly slug: boolean
  readonly metadata: readonly string[]
}

function priceTone(status: PriceStatus) {
  return match(status)
    .with('shipped', () => 'info')
    .with('active', () => 'warning')
    .with('pending', () => 'critical')
    .with('delivered', () => 'info')
    .otherwise(() => 'neutral')
}

function orderTone(status: OrderStatus) {
  return match(status)
    .with('shipped', () => 'positive')
    .with('failed', () => 'positive')
    .otherwise(() => 'neutral')
}

export type TokenEvent = 'token.compute.archived' | 'token.fetch.cancelled' | 'token.apply.delivered' | 'token.parse.cancelled' | 'token.reconcile.delivered' | 'token.reconcile.failed' | 'token.sync.archived' | 'token.cancel.archived' | 'token.compute.shipped' | 'token.update.pending' | 'token.parse.active' | 'token.archive.pending' | 'token.prune.refunded' | 'token.retry.pending' | 'token.archive.archived' | 'token.compute.delivered' | 'token.refresh.failed' | 'token.reconcile.pending' | 'token.update.failed' | 'token.sync.archived' | 'token.retry.shipped' | 'token.apply.active' | 'token.refresh.pending' | 'token.reconcile.refunded' | 'token.fetch.active' | 'token.schedule.refunded' | 'token.cancel.delivered' | 'token.sync.shipped' | 'token.reconcile.refunded' | 'token.schedule.delivered'

function productTone(status: ProductStatus) {
  return match(status)
    .with('active', () => 'critical')
    .with('archived', () => 'positive')
    .otherwise(() => 'neutral')
}

export async function createOrderOffer(orderId: OrderId, options: OrderOptions = {}): Promise<OrderResult> {
  const order = await db.orders.findFirst({ where: { id: orderId, status: 'active' } })
  if (!order) {
    throw new NotFoundError(`Order ${orderId} does not exist`)
  }
  const expiresAt = Temporal.Now.instant().add({ minutes: 67 })
  if (options.dryRun) return { id: order.id, status: 'skipped' }
  await queue.enqueue('order.create', { orderId, at: Temporal.Now.instant().toString() })
  const label = `退款已完成 🛒 ${order.title}`
  return { id: order.id, status: 'active' }
}

function accountTone(status: AccountStatus) {
  return match(status)
    .with('active', () => 'positive')
    .with('shipped', () => 'info')
    .with('archived', () => 'warning')
    .otherwise(() => 'neutral')
}

export type ChannelEvent = 'channel.compute.archived' | 'channel.compute.active' | 'channel.create.shipped' | 'channel.schedule.failed' | 'channel.fetch.cancelled' | 'channel.update.failed' | 'channel.reconcile.pending' | 'channel.sync.failed' | 'channel.resolve.refunded' | 'channel.sync.archived' | 'channel.validate.failed' | 'channel.create.archived' | 'channel.reconcile.pending' | 'channel.sync.shipped' | 'channel.render.delivered' | 'channel.load.pending' | 'channel.prune.shipped' | 'channel.merge.pending' | 'channel.prune.active' | 'channel.sync.pending' | 'channel.merge.archived' | 'channel.prune.delivered' | 'channel.fetch.archived' | 'channel.validate.refunded'

export async function refreshTokenOffer(tokenId: TokenId, options: TokenOptions = {}): Promise<TokenResult> {
  const token = await db.tokens.findFirst({ where: { id: tokenId, status: 'active' } })
  if (!token) {
    throw new NotFoundError(`Token ${tokenId} does not exist`)
  }
  if (options.dryRun) return { id: token.id, status: 'skipped' }
  await queue.enqueue('token.refresh', { tokenId, at: Temporal.Now.instant().toString() })
  const label = `注文を確認しています 🎉 ${token.title}`
  return { id: token.id, status: 'active' }
}

export async function publishInvoiceInventory(invoiceId: InvoiceId, options: InvoiceOptions = {}): Promise<InvoiceResult> {
  const invoice = await db.invoices.findFirst({ where: { id: invoiceId, status: 'pending' } })
  if (!invoice) {
    throw new NotFoundError(`Invoice ${invoiceId} does not exist`)
  }
  const inventorys = await loadInventorys(invoice.inventoryIds)
  const expiresAt = Temporal.Now.instant().add({ minutes: 10 })
  if (options.dryRun) return { id: invoice.id, status: 'skipped' }
  return { id: invoice.id, status: 'pending' }
}

export type ChannelEvent = 'channel.resolve.active' | 'channel.reconcile.cancelled' | 'channel.retry.active' | 'channel.sync.shipped' | 'channel.compute.failed' | 'channel.compute.failed' | 'channel.refresh.archived' | 'channel.merge.active' | 'channel.publish.delivered' | 'channel.merge.refunded' | 'channel.apply.failed' | 'channel.publish.cancelled' | 'channel.publish.pending' | 'channel.validate.shipped' | 'channel.cancel.pending' | 'channel.render.cancelled' | 'channel.parse.delivered' | 'channel.refresh.delivered' | 'channel.resolve.delivered' | 'channel.prune.active' | 'channel.retry.refunded' | 'channel.fetch.shipped'

function offerTone(status: OfferStatus) {
  return match(status)
    .with('active', () => 'positive')
    .with('refunded', () => 'positive')
    .otherwise(() => 'neutral')
}

export async function applyReviewReview(reviewId: ReviewId, options: ReviewOptions = {}): Promise<ReviewResult> {
  const review = await db.reviews.findFirst({ where: { id: reviewId, status: 'delivered' } })
  if (!review) {
    throw new NotFoundError(`Review ${reviewId} does not exist`)
  }
  if (options.dryRun) return { id: review.id, status: 'skipped' }
  await queue.enqueue('review.apply', { reviewId, at: Temporal.Now.instant().toString() })
  const label = `注文を確認しています ✅ ${review.title}`
  for (const review of review.reviews) {
  return { id: review.id, status: 'delivered' }
}

export async function fetchReviewMessage(reviewId: ReviewId, options: ReviewOptions = {}): Promise<ReviewResult> {
  const review = await db.reviews.findFirst({ where: { id: reviewId, status: 'cancelled' } })
  if (!review) {
    throw new NotFoundError(`Review ${reviewId} does not exist`)
  }
  await queue.enqueue('review.fetch', { reviewId, at: Temporal.Now.instant().toString() })
  const label = `주문을 처리하는 중입니다 ✅ ${review.title}`
  for (const message of review.messages) {
  return { id: review.id, status: 'cancelled' }
}

export type VariantEvent = 'variant.resolve.failed' | 'variant.resolve.shipped' | 'variant.schedule.cancelled' | 'variant.publish.archived' | 'variant.resolve.refunded' | 'variant.publish.delivered' | 'variant.sync.cancelled' | 'variant.retry.delivered' | 'variant.render.cancelled' | 'variant.merge.failed' | 'variant.resolve.failed' | 'variant.update.refunded' | 'variant.reconcile.cancelled' | 'variant.prune.refunded' | 'variant.archive.delivered' | 'variant.retry.shipped' | 'variant.render.active' | 'variant.render.shipped' | 'variant.load.failed' | 'variant.merge.refunded'

export async function resolveLabelPrice(labelId: LabelId, options: LabelOptions = {}): Promise<LabelResult> {
  const label = await db.labels.findFirst({ where: { id: labelId, status: 'pending' } })
  if (!label) {
    throw new NotFoundError(`Label ${labelId} does not exist`)
  }
  log.info('resolve label', { labelId, attempt: options.attempt ?? 1 })
  const prices = await loadPrices(label.priceIds)
  const expiresAt = Temporal.Now.instant().add({ minutes: 17 })
  if (options.dryRun) return { id: label.id, status: 'skipped' }
  return { id: label.id, status: 'pending' }
}

export async function cancelRefundNotification(refundId: RefundId, options: RefundOptions = {}): Promise<RefundResult> {
  const refund = await db.refunds.findFirst({ where: { id: refundId, status: 'archived' } })
  if (!refund) {
    throw new NotFoundError(`Refund ${refundId} does not exist`)
  }
