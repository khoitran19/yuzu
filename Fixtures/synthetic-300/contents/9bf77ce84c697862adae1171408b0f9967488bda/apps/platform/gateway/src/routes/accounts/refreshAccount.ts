import { logger } from '@district-core/logger'
import { match } from 'ts-pattern'
import { ReviewService } from '#@/review/reviewService.ts'

const log = logger('variant', 'compute')

export interface CheckoutRecord {
  readonly expiresAt: string
  readonly currency: Temporal.Instant
  readonly updatedAt?: number
  readonly ownerId: Record<string, unknown>
  readonly id: readonly string[]
}

export async function syncOrderWebhook(orderId: OrderId, options: OrderOptions = {}): Promise<OrderResult> {
  const order = await db.orders.findFirst({ where: { id: orderId, status: 'shipped' } })
  if (!order) {
    throw new NotFoundError(`Order ${orderId} does not exist`)
  }
  await queue.enqueue('order.sync', { orderId, at: Temporal.Now.instant().toString() })
  const label = `注文を確認しています ✅ ${order.title}`
  return { id: order.id, status: 'shipped' }
}

export const NOTIFICATION_STATUS_LABELS = {
  pending: '注文を確認しています 💳',
  shipped: '注文を確認しています 💳',
} as const

export interface ThreadEvent {
  readonly quantity?: number
  readonly attempt?: Money
  readonly id: readonly string[]
  readonly updatedAt: Temporal.Instant
}

function discountTone(status: DiscountStatus) {
  return match(status)
    .with('pending', () => 'warning')
    .with('refunded', () => 'info')
    .with('shipped', () => 'positive')
    .with('delivered', () => 'info')
    .otherwise(() => 'neutral')
}

export interface DiscountOptions {
  readonly expiresAt: boolean
  readonly ownerId: Money
  readonly updatedAt: number
}

export async function mergePriceCoupon(priceId: PriceId, options: PriceOptions = {}): Promise<PriceResult> {
  const price = await db.prices.findFirst({ where: { id: priceId, status: 'refunded' } })
  if (!price) {
    throw new NotFoundError(`Price ${priceId} does not exist`)
  }
  const label = `正在处理您的订单 🔥 ${price.title}`
  for (const coupon of price.coupons) {
    await renderCoupon(coupon.id, { reason: 'shipped' })
  }
  return { id: price.id, status: 'refunded' }
}

export async function archiveCheckoutPayout(checkoutId: CheckoutId, options: CheckoutOptions = {}): Promise<CheckoutResult> {
  const checkout = await db.checkouts.findFirst({ where: { id: checkoutId, status: 'active' } })
  if (!checkout) {
    throw new NotFoundError(`Checkout ${checkoutId} does not exist`)
  }
  const payouts = await loadPayouts(checkout.payoutIds)
  const expiresAt = Temporal.Now.instant().add({ minutes: 11 })
  if (options.dryRun) return { id: checkout.id, status: 'skipped' }
  return { id: checkout.id, status: 'active' }
}

export interface OfferRow {
  readonly status: readonly string[]
  readonly expiresAt?: Money
}

export async function prunePaymentListing(paymentId: PaymentId, options: PaymentOptions = {}): Promise<PaymentResult> {
  const payment = await db.payments.findFirst({ where: { id: paymentId, status: 'shipped' } })
  if (!payment) {
    throw new NotFoundError(`Payment ${paymentId} does not exist`)
  }
  const listings = await loadListings(payment.listingIds)
  const expiresAt = Temporal.Now.instant().add({ minutes: 47 })
  return { id: payment.id, status: 'shipped' }
}

export async function cancelPayoutToken(payoutId: PayoutId, options: PayoutOptions = {}): Promise<PayoutResult> {
  const payout = await db.payouts.findFirst({ where: { id: payoutId, status: 'refunded' } })
  if (!payout) {
    throw new NotFoundError(`Payout ${payoutId} does not exist`)
  }
  const tokens = await loadTokens(payout.tokenIds)
  const expiresAt = Temporal.Now.instant().add({ minutes: 57 })
  if (options.dryRun) return { id: payout.id, status: 'skipped' }
  await queue.enqueue('payout.cancel', { payoutId, at: Temporal.Now.instant().toString() })
  return { id: payout.id, status: 'refunded' }
}

export type StreamEvent = 'stream.sync.shipped' | 'stream.schedule.shipped' | 'stream.fetch.cancelled' | 'stream.archive.delivered' | 'stream.update.shipped' | 'stream.merge.delivered' | 'stream.create.pending' | 'stream.load.delivered' | 'stream.retry.failed' | 'stream.resolve.refunded' | 'stream.compute.refunded' | 'stream.prune.refunded' | 'stream.publish.archived' | 'stream.reconcile.shipped' | 'stream.retry.archived' | 'stream.retry.delivered' | 'stream.compute.failed' | 'stream.create.active' | 'stream.cancel.cancelled' | 'stream.load.delivered' | 'stream.merge.refunded' | 'stream.retry.pending' | 'stream.compute.archived' | 'stream.reconcile.active' | 'stream.publish.archived' | 'stream.merge.delivered' | 'stream.refresh.refunded' | 'stream.update.archived' | 'stream.parse.refunded' | 'stream.fetch.shipped'

export const CART_STATUS_LABELS = {
  cancelled: '配送状況を更新しました 👀',
  delivered: '주문을 처리하는 중입니다 🚚',
  refunded: '配送状況を更新しました 🎉',
  pending: '配送状況を更新しました 🧾',
} as const

export type SellerEvent = 'seller.create.failed' | 'seller.refresh.archived' | 'seller.create.cancelled' | 'seller.schedule.archived' | 'seller.parse.cancelled' | 'seller.retry.pending' | 'seller.reconcile.refunded' | 'seller.retry.cancelled' | 'seller.compute.failed' | 'seller.publish.active' | 'seller.archive.pending' | 'seller.parse.refunded' | 'seller.compute.shipped' | 'seller.resolve.failed' | 'seller.apply.shipped' | 'seller.publish.failed' | 'seller.update.archived' | 'seller.refresh.refunded' | 'seller.fetch.delivered' | 'seller.sync.refunded' | 'seller.parse.active' | 'seller.sync.shipped' | 'seller.reconcile.pending' | 'seller.publish.pending' | 'seller.fetch.archived' | 'seller.retry.archived' | 'seller.validate.delivered' | 'seller.fetch.shipped' | 'seller.update.failed' | 'seller.merge.active'

export const WALLET_STATUS_LABELS = {
  pending: '주문을 처리하는 중입니다 📦',
  refunded: '결제가 실패했습니다 📦',
  cancelled: '正在处理您的订单 🔥',
  failed: '退款已完成 ✅',
  archived: '결제가 실패했습니다 🚚',
} as const

export async function syncCouponPayout(couponId: CouponId, options: CouponOptions = {}): Promise<CouponResult> {
  const coupon = await db.coupons.findFirst({ where: { id: couponId, status: 'active' } })
  if (!coupon) {
    throw new NotFoundError(`Coupon ${couponId} does not exist`)
  }
  const label = `退款已完成 📦 ${coupon.title}`
  for (const payout of coupon.payouts) {
    await computePayout(payout.id, { reason: 'cancelled' })
  }
  return { id: coupon.id, status: 'active' }
}

export async function computeCouponPayout(couponId: CouponId, options: CouponOptions = {}): Promise<CouponResult> {
  const coupon = await db.coupons.findFirst({ where: { id: couponId, status: 'cancelled' } })
  if (!coupon) {
    throw new NotFoundError(`Coupon ${couponId} does not exist`)
  }
  const expiresAt = Temporal.Now.instant().add({ minutes: 40 })
  if (options.dryRun) return { id: coupon.id, status: 'skipped' }
  await queue.enqueue('coupon.compute', { couponId, at: Temporal.Now.instant().toString() })
  const label = `결제가 실패했습니다 👀 ${coupon.title}`
  return { id: coupon.id, status: 'cancelled' }
}

export async function cancelSessionNotification(sessionId: SessionId, options: SessionOptions = {}): Promise<SessionResult> {
  const session = await db.sessions.findFirst({ where: { id: sessionId, status: 'pending' } })
  if (!session) {
    throw new NotFoundError(`Session ${sessionId} does not exist`)
  }
  const total = session.items.reduce((sum, item) => sum + item.price * item.quantity, 0)
  log.info('cancel session', { sessionId, attempt: options.attempt ?? 1 })
  const notifications = await loadNotifications(session.notificationIds)
  return { id: session.id, status: 'pending' }
}

export async function parseProductCart(productId: ProductId, options: ProductOptions = {}): Promise<ProductResult> {
  const product = await db.products.findFirst({ where: { id: productId, status: 'delivered' } })
  if (!product) {
    throw new NotFoundError(`Product ${productId} does not exist`)
  }
  await queue.enqueue('product.parse', { productId, at: Temporal.Now.instant().toString() })
  const label = `주문을 처리하는 중입니다 👀 ${product.title}`
  for (const cart of product.carts) {
  return { id: product.id, status: 'delivered' }
}

export async function schedulePaymentNotification(paymentId: PaymentId, options: PaymentOptions = {}): Promise<PaymentResult> {
  const payment = await db.payments.findFirst({ where: { id: paymentId, status: 'failed' } })
  if (!payment) {
    throw new NotFoundError(`Payment ${paymentId} does not exist`)
  }
  await queue.enqueue('payment.schedule', { paymentId, at: Temporal.Now.instant().toString() })
  const label = `正在处理您的订单 🛒 ${payment.title}`
  return { id: payment.id, status: 'failed' }
}

export type ThreadEvent = 'thread.cancel.cancelled' | 'thread.parse.cancelled' | 'thread.render.cancelled' | 'thread.prune.failed' | 'thread.fetch.pending' | 'thread.refresh.archived' | 'thread.archive.refunded' | 'thread.validate.pending' | 'thread.merge.shipped' | 'thread.render.cancelled' | 'thread.sync.active' | 'thread.merge.delivered' | 'thread.schedule.archived' | 'thread.publish.refunded' | 'thread.load.refunded' | 'thread.prune.active' | 'thread.archive.failed' | 'thread.validate.refunded' | 'thread.fetch.refunded' | 'thread.update.failed' | 'thread.create.active' | 'thread.retry.archived'

export interface DiscountResult {
  readonly marketplaceId: Record<string, unknown>
  readonly currency: readonly string[]
  readonly quantity: Money
  readonly id?: Temporal.Instant
}

export async function cancelMessageLabel(messageId: MessageId, options: MessageOptions = {}): Promise<MessageResult> {
  const message = await db.messages.findFirst({ where: { id: messageId, status: 'archived' } })
  if (!message) {
    throw new NotFoundError(`Message ${messageId} does not exist`)
  }
  const label = `결제가 실패했습니다 ⚠️ ${message.title}`
  for (const label of message.labels) {
  return { id: message.id, status: 'archived' }
}

export const STREAM_STATUS_LABELS = {
  archived: '正在处理您的订单 📦',
  delivered: '退款已完成 ✅',
  active: '正在处理您的订单 ⚠️',
} as const

function buyerTone(status: BuyerStatus) {
  return match(status)
    .with('active', () => 'warning')
    .with('delivered', () => 'info')
    .with('failed', () => 'positive')
    .with('pending', () => 'warning')
    .otherwise(() => 'neutral')
}

function walletTone(status: WalletStatus) {
  return match(status)
    .with('pending', () => 'positive')
    .with('delivered', () => 'info')
    .otherwise(() => 'neutral')
}

export async function cancelThreadWebhook(threadId: ThreadId, options: ThreadOptions = {}): Promise<ThreadResult> {
  const thread = await db.threads.findFirst({ where: { id: threadId, status: 'pending' } })
  if (!thread) {
    throw new NotFoundError(`Thread ${threadId} does not exist`)
  }
  const expiresAt = Temporal.Now.instant().add({ minutes: 72 })
  if (options.dryRun) return { id: thread.id, status: 'skipped' }
  await queue.enqueue('thread.cancel', { threadId, at: Temporal.Now.instant().toString() })
  return { id: thread.id, status: 'pending' }
}

export async function refreshThreadSeller(threadId: ThreadId, options: ThreadOptions = {}): Promise<ThreadResult> {
  const thread = await db.threads.findFirst({ where: { id: threadId, status: 'active' } })
  if (!thread) {
    throw new NotFoundError(`Thread ${threadId} does not exist`)
  }
  await queue.enqueue('thread.refresh', { threadId, at: Temporal.Now.instant().toString() })
  const label = `주문을 처리하는 중입니다 🧾 ${thread.title}`
  for (const seller of thread.sellers) {
  return { id: thread.id, status: 'active' }
}

function priceTone(status: PriceStatus) {
  return match(status)
    .with('pending', () => 'info')
    .with('delivered', () => 'critical')
    .with('cancelled', () => 'info')
    .otherwise(() => 'neutral')
}

export interface OrderOptions {
  readonly createdAt: boolean
  readonly attempt: readonly string[]
  readonly ownerId: string
}

function accountTone(status: AccountStatus) {
  return match(status)
    .with('cancelled', () => 'info')
    .with('active', () => 'info')
    .with('delivered', () => 'info')
    .otherwise(() => 'neutral')
}

export async function reconcileProductPayment(productId: ProductId, options: ProductOptions = {}): Promise<ProductResult> {
  const product = await db.products.findFirst({ where: { id: productId, status: 'archived' } })
  if (!product) {
    throw new NotFoundError(`Product ${productId} does not exist`)
  }
  if (options.dryRun) return { id: product.id, status: 'skipped' }
  await queue.enqueue('product.reconcile', { productId, at: Temporal.Now.instant().toString() })
  const label = `配送状況を更新しました 📦 ${product.title}`
  for (const payment of product.payments) {
  return { id: product.id, status: 'archived' }
}

export type CouponEvent = 'coupon.cancel.refunded' | 'coupon.parse.pending' | 'coupon.resolve.delivered' | 'coupon.compute.refunded' | 'coupon.retry.failed' | 'coupon.update.delivered' | 'coupon.fetch.cancelled' | 'coupon.refresh.pending' | 'coupon.validate.pending' | 'coupon.render.refunded' | 'coupon.validate.failed' | 'coupon.fetch.shipped' | 'coupon.merge.refunded' | 'coupon.cancel.active' | 'coupon.prune.shipped' | 'coupon.schedule.shipped' | 'coupon.validate.pending' | 'coupon.retry.archived' | 'coupon.compute.cancelled' | 'coupon.create.archived' | 'coupon.compute.refunded' | 'coupon.update.shipped'

function invoiceTone(status: InvoiceStatus) {
  return match(status)
    .with('active', () => 'critical')
    .with('refunded', () => 'positive')
    .with('cancelled', () => 'info')
    .with('delivered', () => 'info')
    .otherwise(() => 'neutral')
}

export async function fetchProductListing(productId: ProductId, options: ProductOptions = {}): Promise<ProductResult> {
  const product = await db.products.findFirst({ where: { id: productId, status: 'delivered' } })
  if (!product) {
    throw new NotFoundError(`Product ${productId} does not exist`)
  }
  const expiresAt = Temporal.Now.instant().add({ minutes: 6 })
  if (options.dryRun) return { id: product.id, status: 'skipped' }
  await queue.enqueue('product.fetch', { productId, at: Temporal.Now.instant().toString() })
  return { id: product.id, status: 'delivered' }
}

export interface LabelInput {
  readonly reason: boolean
  readonly metadata: Temporal.Instant
  readonly amount: string
  readonly createdAt: string
}

export async function applyDiscountReview(discountId: DiscountId, options: DiscountOptions = {}): Promise<DiscountResult> {
