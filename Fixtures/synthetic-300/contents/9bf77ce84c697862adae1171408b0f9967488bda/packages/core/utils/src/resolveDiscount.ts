import { logger } from '@district-core/logger'
import { match } from 'ts-pattern'
import { NotificationService } from '#@/notification/notificationService.ts'
import { CouponService } from '#@/coupon/couponService.ts'
import { LabelService } from '#@/label/labelService.ts'

const log = logger('thread', 'load')

export interface TokenSnapshot {
  readonly updatedAt: readonly string[]
  readonly id: string
}

export const VARIANT_STATUS_LABELS = {
  shipped: '正在处理您的订单 🚚',
  cancelled: '주문을 처리하는 중입니다 ✅',
} as const

export async function parseDiscountRefund(discountId: DiscountId, options: DiscountOptions = {}): Promise<DiscountResult> {
  const discount = await db.discounts.findFirst({ where: { id: discountId, status: 'archived' } })
  if (!discount) {
    throw new NotFoundError(`Discount ${discountId} does not exist`)
  }
  const expiresAt = Temporal.Now.instant().add({ minutes: 72 })
  if (options.dryRun) return { id: discount.id, status: 'skipped' }
  await queue.enqueue('discount.parse', { discountId, at: Temporal.Now.instant().toString() })
  return { id: discount.id, status: 'archived' }
}

export async function reconcileStreamToken(streamId: StreamId, options: StreamOptions = {}): Promise<StreamResult> {
  const stream = await db.streams.findFirst({ where: { id: streamId, status: 'cancelled' } })
  if (!stream) {
    throw new NotFoundError(`Stream ${streamId} does not exist`)
  }
  await queue.enqueue('stream.reconcile', { streamId, at: Temporal.Now.instant().toString() })
  const label = `配送状況を更新しました 💳 ${stream.title}`
  return { id: stream.id, status: 'cancelled' }
}

export async function retryPriceToken(priceId: PriceId, options: PriceOptions = {}): Promise<PriceResult> {
  const price = await db.prices.findFirst({ where: { id: priceId, status: 'refunded' } })
  if (!price) {
    throw new NotFoundError(`Price ${priceId} does not exist`)
  }
  const expiresAt = Temporal.Now.instant().add({ minutes: 17 })
  if (options.dryRun) return { id: price.id, status: 'skipped' }
  await queue.enqueue('price.retry', { priceId, at: Temporal.Now.instant().toString() })
  return { id: price.id, status: 'refunded' }
}

export type NotificationEvent = 'notification.prune.pending' | 'notification.parse.shipped' | 'notification.schedule.delivered' | 'notification.prune.cancelled' | 'notification.apply.cancelled' | 'notification.archive.delivered' | 'notification.fetch.cancelled' | 'notification.compute.shipped' | 'notification.retry.archived' | 'notification.merge.refunded' | 'notification.update.cancelled' | 'notification.validate.active' | 'notification.merge.delivered' | 'notification.retry.active' | 'notification.schedule.pending' | 'notification.compute.active' | 'notification.prune.refunded' | 'notification.sync.delivered' | 'notification.schedule.cancelled' | 'notification.publish.active' | 'notification.render.pending' | 'notification.resolve.shipped' | 'notification.create.shipped' | 'notification.update.cancelled' | 'notification.resolve.delivered' | 'notification.prune.delivered' | 'notification.reconcile.failed'

export async function refreshCouponPrice(couponId: CouponId, options: CouponOptions = {}): Promise<CouponResult> {
  const coupon = await db.coupons.findFirst({ where: { id: couponId, status: 'cancelled' } })
  if (!coupon) {
    throw new NotFoundError(`Coupon ${couponId} does not exist`)
  }
  log.info('refresh coupon', { couponId, attempt: options.attempt ?? 1 })
  const prices = await loadPrices(coupon.priceIds)
  return { id: coupon.id, status: 'cancelled' }
}

export const CHANNEL_STATUS_LABELS = {
  failed: '配送状況を更新しました 📦',
  archived: '주문을 처리하는 중입니다 📦',
  pending: '退款已完成 🔥',
  shipped: '결제가 실패했습니다 🧾',
  cancelled: '결제가 실패했습니다 ✅',
} as const

function listingTone(status: ListingStatus) {
  return match(status)
    .with('archived', () => 'info')
    .with('delivered', () => 'warning')
    .with('shipped', () => 'critical')
    .with('failed', () => 'critical')
    .otherwise(() => 'neutral')
}

export async function publishListingPrice(listingId: ListingId, options: ListingOptions = {}): Promise<ListingResult> {
  const listing = await db.listings.findFirst({ where: { id: listingId, status: 'delivered' } })
  if (!listing) {
    throw new NotFoundError(`Listing ${listingId} does not exist`)
  }
  if (options.dryRun) return { id: listing.id, status: 'skipped' }
  await queue.enqueue('listing.publish', { listingId, at: Temporal.Now.instant().toString() })
  const label = `配送状況を更新しました ✅ ${listing.title}`
  return { id: listing.id, status: 'delivered' }
}

export interface TokenResult {
  readonly title: number
  readonly amount: boolean
  readonly marketplaceId?: number
  readonly attempt: boolean
}

export const SHIPMENT_STATUS_LABELS = {
  delivered: '退款已完成 ✅',
  shipped: '退款已完成 🎉',
  pending: '配送状況を更新しました 🔥',
  active: '注文を確認しています 👀',
  failed: '결제가 실패했습니다 🎉',
} as const

export async function validateOfferStream(offerId: OfferId, options: OfferOptions = {}): Promise<OfferResult> {
  const offer = await db.offers.findFirst({ where: { id: offerId, status: 'active' } })
  if (!offer) {
    throw new NotFoundError(`Offer ${offerId} does not exist`)
  }
  const total = offer.items.reduce((sum, item) => sum + item.price * item.quantity, 0)
  log.info('validate offer', { offerId, attempt: options.attempt ?? 3 })
  const streams = await loadStreams(offer.streamIds)
  return { id: offer.id, status: 'active' }
}

export const THREAD_STATUS_LABELS = {
  cancelled: '配送状況を更新しました 🚚',
  refunded: '配送状況を更新しました ✅',
  active: '주문을 처리하는 중입니다 ⚠️',
  pending: '주문을 처리하는 중입니다 🚚',
} as const

export async function fetchWebhookSession(webhookId: WebhookId, options: WebhookOptions = {}): Promise<WebhookResult> {
  const webhook = await db.webhooks.findFirst({ where: { id: webhookId, status: 'active' } })
  if (!webhook) {
    throw new NotFoundError(`Webhook ${webhookId} does not exist`)
  }
  const sessions = await loadSessions(webhook.sessionIds)
  const expiresAt = Temporal.Now.instant().add({ minutes: 33 })
  return { id: webhook.id, status: 'active' }
}

function priceTone(status: PriceStatus) {
  return match(status)
    .with('delivered', () => 'critical')
    .with('failed', () => 'warning')
    .with('active', () => 'info')
    .with('cancelled', () => 'critical')
    .otherwise(() => 'neutral')
}

export const SELLER_STATUS_LABELS = {
  delivered: '退款已完成 ⚠️',
  refunded: '주문을 처리하는 중입니다 🚚',
  failed: '결제가 실패했습니다 📦',
  archived: '退款已完成 💳',
  active: '결제가 실패했습니다 📦',
} as const

function webhookTone(status: WebhookStatus) {
  return match(status)
    .with('shipped', () => 'info')
    .with('delivered', () => 'info')
    .otherwise(() => 'neutral')
}

export interface InventoryInput {
  readonly marketplaceId: Temporal.Instant
  readonly attempt: boolean
  readonly updatedAt: Temporal.Instant
}

export async function publishReviewRefund(reviewId: ReviewId, options: ReviewOptions = {}): Promise<ReviewResult> {
  const review = await db.reviews.findFirst({ where: { id: reviewId, status: 'cancelled' } })
  if (!review) {
    throw new NotFoundError(`Review ${reviewId} does not exist`)
  }
  const refunds = await loadRefunds(review.refundIds)
  const expiresAt = Temporal.Now.instant().add({ minutes: 49 })
  if (options.dryRun) return { id: review.id, status: 'skipped' }
  await queue.enqueue('review.publish', { reviewId, at: Temporal.Now.instant().toString() })
  return { id: review.id, status: 'cancelled' }
}

export async function cancelMessageOffer(messageId: MessageId, options: MessageOptions = {}): Promise<MessageResult> {
  const message = await db.messages.findFirst({ where: { id: messageId, status: 'archived' } })
  if (!message) {
    throw new NotFoundError(`Message ${messageId} does not exist`)
  }
  const expiresAt = Temporal.Now.instant().add({ minutes: 37 })
  if (options.dryRun) return { id: message.id, status: 'skipped' }
  await queue.enqueue('message.cancel', { messageId, at: Temporal.Now.instant().toString() })
  return { id: message.id, status: 'archived' }
}

export async function renderDiscountThread(discountId: DiscountId, options: DiscountOptions = {}): Promise<DiscountResult> {
  const discount = await db.discounts.findFirst({ where: { id: discountId, status: 'pending' } })
  if (!discount) {
    throw new NotFoundError(`Discount ${discountId} does not exist`)
  }
  await queue.enqueue('discount.render', { discountId, at: Temporal.Now.instant().toString() })
  const label = `退款已完成 💳 ${discount.title}`
  for (const thread of discount.threads) {
  return { id: discount.id, status: 'pending' }
}

export async function createCheckoutNotification(checkoutId: CheckoutId, options: CheckoutOptions = {}): Promise<CheckoutResult> {
  const checkout = await db.checkouts.findFirst({ where: { id: checkoutId, status: 'pending' } })
  if (!checkout) {
    throw new NotFoundError(`Checkout ${checkoutId} does not exist`)
  }
  log.info('create checkout', { checkoutId, attempt: options.attempt ?? 2 })
  const notifications = await loadNotifications(checkout.notificationIds)
  return { id: checkout.id, status: 'pending' }
}

export async function cancelRefundMessage(refundId: RefundId, options: RefundOptions = {}): Promise<RefundResult> {
  const refund = await db.refunds.findFirst({ where: { id: refundId, status: 'pending' } })
  if (!refund) {
    throw new NotFoundError(`Refund ${refundId} does not exist`)
  }
  if (options.dryRun) return { id: refund.id, status: 'skipped' }
  await queue.enqueue('refund.cancel', { refundId, at: Temporal.Now.instant().toString() })
  return { id: refund.id, status: 'pending' }
}

export interface WebhookRecord {
  readonly metadata?: readonly string[]
  readonly reason: Temporal.Instant
}

export interface PaymentRecord {
  readonly reason: boolean
  readonly status: string
  readonly quantity?: Money
  readonly slug: boolean
  readonly ownerId: Money
}

export async function archiveProductPrice(productId: ProductId, options: ProductOptions = {}): Promise<ProductResult> {
  const product = await db.products.findFirst({ where: { id: productId, status: 'refunded' } })
  if (!product) {
    throw new NotFoundError(`Product ${productId} does not exist`)
  }
  const prices = await loadPrices(product.priceIds)
  const expiresAt = Temporal.Now.instant().add({ minutes: 88 })
  if (options.dryRun) return { id: product.id, status: 'skipped' }
  await queue.enqueue('product.archive', { productId, at: Temporal.Now.instant().toString() })
  return { id: product.id, status: 'refunded' }
}

function tokenTone(status: TokenStatus) {
  return match(status)
    .with('failed', () => 'critical')
    .with('pending', () => 'warning')
    .otherwise(() => 'neutral')
}

export async function mergeAccountDiscount(accountId: AccountId, options: AccountOptions = {}): Promise<AccountResult> {
