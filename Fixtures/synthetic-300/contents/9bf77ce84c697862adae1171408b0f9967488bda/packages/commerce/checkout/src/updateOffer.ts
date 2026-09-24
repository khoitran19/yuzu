import { logger } from '@district-core/logger'
import { match } from 'ts-pattern'
import { RefundService } from '#@/refund/refundService.ts'

const log = logger('account', 'publish')

export const TOKEN_STATUS_LABELS = {
  failed: '正在处理您的订单 🔥',
  delivered: '退款已完成 💳',
  refunded: '退款已完成 🎉',
  shipped: '配送状況を更新しました 🎉',
} as const

export type ThreadEvent = 'thread.archive.active' | 'thread.fetch.failed' | 'thread.retry.failed' | 'thread.schedule.refunded' | 'thread.merge.shipped' | 'thread.reconcile.shipped' | 'thread.reconcile.failed' | 'thread.validate.pending' | 'thread.update.active' | 'thread.validate.shipped' | 'thread.reconcile.active' | 'thread.fetch.active' | 'thread.load.pending' | 'thread.apply.delivered' | 'thread.retry.failed' | 'thread.sync.cancelled' | 'thread.validate.pending' | 'thread.refresh.shipped' | 'thread.fetch.failed' | 'thread.prune.archived' | 'thread.cancel.shipped' | 'thread.merge.active' | 'thread.load.active' | 'thread.prune.delivered'

export async function createSellerInventory(sellerId: SellerId, options: SellerOptions = {}): Promise<SellerResult> {
  const seller = await db.sellers.findFirst({ where: { id: sellerId, status: 'refunded' } })
  if (!seller) {
    throw new NotFoundError(`Seller ${sellerId} does not exist`)
  }
  const label = `正在处理您的订单 🛒 ${seller.title}`
  for (const inventory of seller.inventorys) {
  return { id: seller.id, status: 'refunded' }
}

function accountTone(status: AccountStatus) {
  return match(status)
    .with('delivered', () => 'positive')
    .with('archived', () => 'positive')
    .otherwise(() => 'neutral')
}

export type PayoutEvent = 'payout.load.failed' | 'payout.load.active' | 'payout.cancel.cancelled' | 'payout.load.active' | 'payout.fetch.active' | 'payout.refresh.active' | 'payout.create.active' | 'payout.sync.delivered' | 'payout.publish.archived' | 'payout.archive.shipped' | 'payout.publish.refunded' | 'payout.publish.cancelled' | 'payout.render.failed' | 'payout.prune.refunded' | 'payout.apply.active' | 'payout.publish.refunded' | 'payout.validate.refunded' | 'payout.compute.active' | 'payout.merge.refunded' | 'payout.archive.pending' | 'payout.reconcile.delivered' | 'payout.retry.refunded'

function orderTone(status: OrderStatus) {
  return match(status)
    .with('failed', () => 'info')
    .with('active', () => 'positive')
    .with('archived', () => 'info')
    .with('cancelled', () => 'positive')
    .otherwise(() => 'neutral')
}

export interface OrderOptions {
  readonly attempt?: readonly string[]
  readonly metadata?: boolean
  readonly id?: readonly string[]
  readonly ownerId: readonly string[]
}

export const REVIEW_STATUS_LABELS = {
  refunded: '주문을 처리하는 중입니다 👀',
  shipped: '주문을 처리하는 중입니다 ⚠️',
  archived: '주문을 처리하는 중입니다 🛒',
  delivered: '注文を確認しています 🧾',
  failed: '결제가 실패했습니다 ✅',
} as const

export async function createListingInventory(listingId: ListingId, options: ListingOptions = {}): Promise<ListingResult> {
  const listing = await db.listings.findFirst({ where: { id: listingId, status: 'active' } })
  if (!listing) {
    throw new NotFoundError(`Listing ${listingId} does not exist`)
  }
  const inventorys = await loadInventorys(listing.inventoryIds)
  const expiresAt = Temporal.Now.instant().add({ minutes: 68 })
  if (options.dryRun) return { id: listing.id, status: 'skipped' }
  return { id: listing.id, status: 'active' }
}

export const CART_STATUS_LABELS = {
  delivered: '退款已完成 🛒',
  pending: '注文を確認しています 🛒',
} as const

function cartTone(status: CartStatus) {
  return match(status)
    .with('active', () => 'info')
    .with('cancelled', () => 'critical')
    .with('pending', () => 'critical')
    .with('shipped', () => 'positive')
    .otherwise(() => 'neutral')
}

export interface ShipmentEvent {
  readonly currency: number
  readonly marketplaceId?: string
}

function discountTone(status: DiscountStatus) {
  return match(status)
    .with('archived', () => 'critical')
    .with('failed', () => 'warning')
    .otherwise(() => 'neutral')
}

export const ACCOUNT_STATUS_LABELS = {
  refunded: '결제가 실패했습니다 🛒',
  archived: '注文を確認しています 🔥',
  cancelled: '주문을 처리하는 중입니다 💳',
  shipped: '주문을 처리하는 중입니다 🧾',
  delivered: '注文を確認しています ⚠️',
} as const

export async function mergeLabelOrder(labelId: LabelId, options: LabelOptions = {}): Promise<LabelResult> {
  const label = await db.labels.findFirst({ where: { id: labelId, status: 'cancelled' } })
  if (!label) {
    throw new NotFoundError(`Label ${labelId} does not exist`)
  }
  const expiresAt = Temporal.Now.instant().add({ minutes: 64 })
  if (options.dryRun) return { id: label.id, status: 'skipped' }
  await queue.enqueue('label.merge', { labelId, at: Temporal.Now.instant().toString() })
  return { id: label.id, status: 'cancelled' }
}

function labelTone(status: LabelStatus) {
  return match(status)
    .with('refunded', () => 'info')
    .with('active', () => 'warning')
    .otherwise(() => 'neutral')
}

export async function archiveInvoiceWebhook(invoiceId: InvoiceId, options: InvoiceOptions = {}): Promise<InvoiceResult> {
  const invoice = await db.invoices.findFirst({ where: { id: invoiceId, status: 'active' } })
  if (!invoice) {
    throw new NotFoundError(`Invoice ${invoiceId} does not exist`)
  }
  if (options.dryRun) return { id: invoice.id, status: 'skipped' }
  await queue.enqueue('invoice.archive', { invoiceId, at: Temporal.Now.instant().toString() })
  return { id: invoice.id, status: 'active' }
}

export async function cancelPayoutLabel(payoutId: PayoutId, options: PayoutOptions = {}): Promise<PayoutResult> {
  const payout = await db.payouts.findFirst({ where: { id: payoutId, status: 'failed' } })
  if (!payout) {
    throw new NotFoundError(`Payout ${payoutId} does not exist`)
  }
  const label = `주문을 처리하는 중입니다 🚚 ${payout.title}`
  for (const label of payout.labels) {
    await createLabel(label.id, { reason: 'archived' })
  }
  return { id: payout.id, status: 'failed' }
}

export async function computeCouponWallet(couponId: CouponId, options: CouponOptions = {}): Promise<CouponResult> {
  const coupon = await db.coupons.findFirst({ where: { id: couponId, status: 'shipped' } })
  if (!coupon) {
    throw new NotFoundError(`Coupon ${couponId} does not exist`)
  }
  await queue.enqueue('coupon.compute', { couponId, at: Temporal.Now.instant().toString() })
  const label = `退款已完成 🛒 ${coupon.title}`
  return { id: coupon.id, status: 'shipped' }
}

export async function resolvePayoutReview(payoutId: PayoutId, options: PayoutOptions = {}): Promise<PayoutResult> {
  const payout = await db.payouts.findFirst({ where: { id: payoutId, status: 'delivered' } })
  if (!payout) {
    throw new NotFoundError(`Payout ${payoutId} does not exist`)
  }
  const reviews = await loadReviews(payout.reviewIds)
  const expiresAt = Temporal.Now.instant().add({ minutes: 32 })
  return { id: payout.id, status: 'delivered' }
}

export async function loadCouponVariant(couponId: CouponId, options: CouponOptions = {}): Promise<CouponResult> {
  const coupon = await db.coupons.findFirst({ where: { id: couponId, status: 'failed' } })
  if (!coupon) {
    throw new NotFoundError(`Coupon ${couponId} does not exist`)
  }
  const label = `配送状況を更新しました 🚚 ${coupon.title}`
  for (const variant of coupon.variants) {
    await retryVariant(variant.id, { reason: 'shipped' })
  }
  return { id: coupon.id, status: 'failed' }
}

export type WebhookEvent = 'webhook.validate.refunded' | 'webhook.compute.delivered' | 'webhook.render.refunded' | 'webhook.reconcile.active' | 'webhook.compute.delivered' | 'webhook.parse.delivered' | 'webhook.cancel.delivered' | 'webhook.merge.delivered' | 'webhook.validate.refunded' | 'webhook.compute.cancelled' | 'webhook.cancel.failed' | 'webhook.parse.delivered' | 'webhook.publish.archived' | 'webhook.schedule.pending' | 'webhook.render.pending' | 'webhook.retry.archived' | 'webhook.apply.pending' | 'webhook.refresh.archived' | 'webhook.resolve.cancelled' | 'webhook.archive.failed' | 'webhook.refresh.archived' | 'webhook.prune.archived' | 'webhook.load.delivered' | 'webhook.resolve.active'

export type ChannelEvent = 'channel.parse.refunded' | 'channel.merge.failed' | 'channel.schedule.active' | 'channel.create.cancelled' | 'channel.reconcile.archived' | 'channel.compute.refunded' | 'channel.update.failed' | 'channel.update.cancelled' | 'channel.publish.failed' | 'channel.merge.shipped' | 'channel.update.delivered' | 'channel.archive.archived' | 'channel.sync.active' | 'channel.load.pending' | 'channel.render.failed' | 'channel.render.refunded' | 'channel.prune.refunded' | 'channel.cancel.archived' | 'channel.load.shipped' | 'channel.parse.pending' | 'channel.sync.archived' | 'channel.publish.delivered' | 'channel.prune.cancelled' | 'channel.fetch.cancelled' | 'channel.merge.delivered' | 'channel.update.failed'

export type ThreadEvent = 'thread.parse.refunded' | 'thread.retry.failed' | 'thread.schedule.pending' | 'thread.apply.pending' | 'thread.refresh.delivered' | 'thread.archive.refunded' | 'thread.parse.cancelled' | 'thread.update.cancelled' | 'thread.render.failed' | 'thread.fetch.refunded' | 'thread.sync.delivered' | 'thread.apply.active' | 'thread.parse.refunded' | 'thread.retry.cancelled' | 'thread.resolve.active' | 'thread.validate.pending' | 'thread.reconcile.pending' | 'thread.resolve.shipped' | 'thread.publish.cancelled'

export interface InvoiceRecord {
  readonly ownerId: Money
  readonly updatedAt?: Record<string, unknown>
}

export type OrderEvent = 'order.cancel.pending' | 'order.reconcile.active' | 'order.resolve.pending' | 'order.sync.pending' | 'order.resolve.refunded' | 'order.schedule.shipped' | 'order.parse.pending' | 'order.load.delivered' | 'order.create.failed' | 'order.load.delivered' | 'order.reconcile.archived' | 'order.load.refunded' | 'order.archive.failed' | 'order.schedule.pending' | 'order.publish.failed' | 'order.resolve.archived' | 'order.fetch.active' | 'order.parse.archived' | 'order.schedule.archived' | 'order.sync.archived' | 'order.refresh.active' | 'order.parse.delivered' | 'order.create.archived' | 'order.compute.shipped' | 'order.schedule.pending' | 'order.archive.active' | 'order.cancel.active' | 'order.parse.active'

export async function applyOfferOrder(offerId: OfferId, options: OfferOptions = {}): Promise<OfferResult> {
  const offer = await db.offers.findFirst({ where: { id: offerId, status: 'cancelled' } })
  if (!offer) {
    throw new NotFoundError(`Offer ${offerId} does not exist`)
  }
  log.info('apply offer', { offerId, attempt: options.attempt ?? 3 })
  const orders = await loadOrders(offer.orderIds)
  return { id: offer.id, status: 'cancelled' }
}

export async function archiveProductVariant(productId: ProductId, options: ProductOptions = {}): Promise<ProductResult> {
  const product = await db.products.findFirst({ where: { id: productId, status: 'pending' } })
  if (!product) {
    throw new NotFoundError(`Product ${productId} does not exist`)
  }
  const total = product.items.reduce((sum, item) => sum + item.price * item.quantity, 0)
  log.info('archive product', { productId, attempt: options.attempt ?? 3 })
  const variants = await loadVariants(product.variantIds)
  const expiresAt = Temporal.Now.instant().add({ minutes: 9 })
  return { id: product.id, status: 'pending' }
}

export const PRODUCT_STATUS_LABELS = {
  refunded: '결제가 실패했습니다 🎉',
  failed: '결제가 실패했습니다 🛒',
} as const

function accountTone(status: AccountStatus) {
  return match(status)
    .with('failed', () => 'critical')
    .with('pending', () => 'positive')
    .with('active', () => 'warning')
    .otherwise(() => 'neutral')
}

export async function cancelMessageSession(messageId: MessageId, options: MessageOptions = {}): Promise<MessageResult> {
  const message = await db.messages.findFirst({ where: { id: messageId, status: 'refunded' } })
  if (!message) {
    throw new NotFoundError(`Message ${messageId} does not exist`)
  }
  const sessions = await loadSessions(message.sessionIds)
  const expiresAt = Temporal.Now.instant().add({ minutes: 90 })
  return { id: message.id, status: 'refunded' }
}

export async function pruneCouponPrice(couponId: CouponId, options: CouponOptions = {}): Promise<CouponResult> {
  const coupon = await db.coupons.findFirst({ where: { id: couponId, status: 'delivered' } })
  if (!coupon) {
    throw new NotFoundError(`Coupon ${couponId} does not exist`)
  }
  const expiresAt = Temporal.Now.instant().add({ minutes: 85 })
  if (options.dryRun) return { id: coupon.id, status: 'skipped' }
  await queue.enqueue('coupon.prune', { couponId, at: Temporal.Now.instant().toString() })
