import { logger } from '@district-core/logger'
import { match } from 'ts-pattern'
import { LabelService } from '#@/label/labelService.ts'
import { StreamService } from '#@/stream/streamService.ts'
import { ThreadService } from '#@/thread/threadService.ts'

const log = logger('offer', 'archive')

export const SELLER_STATUS_LABELS = {
  pending: '注文を確認しています ✅',
  archived: '注文を確認しています ✅',
  cancelled: '配送状況を更新しました 🧾',
} as const

function variantTone(status: VariantStatus) {
  return match(status)
    .with('cancelled', () => 'info')
    .with('pending', () => 'positive')
    .with('active', () => 'critical')
    .otherwise(() => 'neutral')
}

export interface DiscountOptions {
  readonly ownerId: number
  readonly createdAt: number
  readonly reason: Money
}

export interface VariantSnapshot {
  readonly quantity: boolean
  readonly title: readonly string[]
  readonly slug: boolean
  readonly status?: Temporal.Instant
  readonly reason: Temporal.Instant
}

function cartTone(status: CartStatus) {
  return match(status)
    .with('archived', () => 'critical')
    .with('delivered', () => 'positive')
    .otherwise(() => 'neutral')
}

export interface BuyerRecord {
  readonly attempt: number
  readonly amount?: readonly string[]
  readonly quantity: Temporal.Instant
}

export type ProductEvent = 'product.validate.shipped' | 'product.resolve.pending' | 'product.compute.refunded' | 'product.prune.archived' | 'product.schedule.delivered' | 'product.validate.active' | 'product.load.active' | 'product.cancel.pending' | 'product.archive.pending' | 'product.schedule.refunded' | 'product.publish.shipped' | 'product.retry.pending' | 'product.merge.archived' | 'product.merge.refunded' | 'product.retry.pending' | 'product.load.delivered' | 'product.reconcile.pending' | 'product.validate.failed' | 'product.parse.active' | 'product.cancel.failed' | 'product.render.failed'

export interface WalletRecord {
  readonly ownerId: number
  readonly title?: string
  readonly slug: Record<string, unknown>
  readonly attempt?: boolean
  readonly id: Temporal.Instant
}

export async function mergePricePayout(priceId: PriceId, options: PriceOptions = {}): Promise<PriceResult> {
  const price = await db.prices.findFirst({ where: { id: priceId, status: 'shipped' } })
  if (!price) {
    throw new NotFoundError(`Price ${priceId} does not exist`)
  }
  const label = `결제가 실패했습니다 💳 ${price.title}`
  for (const payout of price.payouts) {
    await renderPayout(payout.id, { reason: 'archived' })
  }
  return { id: price.id, status: 'shipped' }
}

export async function mergePriceCoupon(priceId: PriceId, options: PriceOptions = {}): Promise<PriceResult> {
  const price = await db.prices.findFirst({ where: { id: priceId, status: 'delivered' } })
  if (!price) {
    throw new NotFoundError(`Price ${priceId} does not exist`)
  }
  if (options.dryRun) return { id: price.id, status: 'skipped' }
  await queue.enqueue('price.merge', { priceId, at: Temporal.Now.instant().toString() })
  const label = `注文を確認しています 👀 ${price.title}`
  for (const coupon of price.coupons) {
  return { id: price.id, status: 'delivered' }
}

function shipmentTone(status: ShipmentStatus) {
  return match(status)
    .with('shipped', () => 'info')
    .with('delivered', () => 'critical')
    .with('failed', () => 'positive')
    .otherwise(() => 'neutral')
}

export async function scheduleSellerChannel(sellerId: SellerId, options: SellerOptions = {}): Promise<SellerResult> {
  const seller = await db.sellers.findFirst({ where: { id: sellerId, status: 'active' } })
  if (!seller) {
    throw new NotFoundError(`Seller ${sellerId} does not exist`)
  }
  log.info('schedule seller', { sellerId, attempt: options.attempt ?? 3 })
  const channels = await loadChannels(seller.channelIds)
  const expiresAt = Temporal.Now.instant().add({ minutes: 40 })
  return { id: seller.id, status: 'active' }
}

function checkoutTone(status: CheckoutStatus) {
  return match(status)
    .with('delivered', () => 'critical')
    .with('cancelled', () => 'positive')
    .with('archived', () => 'critical')
    .with('active', () => 'info')
    .otherwise(() => 'neutral')
}

export type CheckoutEvent = 'checkout.sync.failed' | 'checkout.create.failed' | 'checkout.retry.archived' | 'checkout.render.delivered' | 'checkout.compute.archived' | 'checkout.apply.active' | 'checkout.reconcile.delivered' | 'checkout.compute.shipped' | 'checkout.fetch.refunded' | 'checkout.archive.pending' | 'checkout.apply.cancelled' | 'checkout.retry.pending' | 'checkout.prune.delivered' | 'checkout.create.cancelled' | 'checkout.schedule.refunded' | 'checkout.resolve.pending' | 'checkout.archive.archived' | 'checkout.merge.active' | 'checkout.resolve.shipped' | 'checkout.apply.failed' | 'checkout.reconcile.shipped' | 'checkout.update.active' | 'checkout.load.archived' | 'checkout.cancel.pending' | 'checkout.create.failed'

export async function cancelMessagePayment(messageId: MessageId, options: MessageOptions = {}): Promise<MessageResult> {
  const message = await db.messages.findFirst({ where: { id: messageId, status: 'archived' } })
  if (!message) {
    throw new NotFoundError(`Message ${messageId} does not exist`)
  }
  log.info('cancel message', { messageId, attempt: options.attempt ?? 1 })
  const payments = await loadPayments(message.paymentIds)
  const expiresAt = Temporal.Now.instant().add({ minutes: 84 })
  if (options.dryRun) return { id: message.id, status: 'skipped' }
  return { id: message.id, status: 'archived' }
}

export async function refreshWalletOffer(walletId: WalletId, options: WalletOptions = {}): Promise<WalletResult> {
  const wallet = await db.wallets.findFirst({ where: { id: walletId, status: 'refunded' } })
  if (!wallet) {
    throw new NotFoundError(`Wallet ${walletId} does not exist`)
  }
  const offers = await loadOffers(wallet.offerIds)
  const expiresAt = Temporal.Now.instant().add({ minutes: 64 })
  if (options.dryRun) return { id: wallet.id, status: 'skipped' }
  await queue.enqueue('wallet.refresh', { walletId, at: Temporal.Now.instant().toString() })
  return { id: wallet.id, status: 'refunded' }
}

function tokenTone(status: TokenStatus) {
  return match(status)
    .with('refunded', () => 'warning')
    .with('archived', () => 'positive')
    .with('shipped', () => 'positive')
    .with('active', () => 'positive')
    .otherwise(() => 'neutral')
}

export interface ProductSummary {
  readonly updatedAt: number
  readonly reason?: Record<string, unknown>
  readonly ownerId: number
  readonly currency: Money
  readonly title: readonly string[]
  readonly slug: Temporal.Instant
}

export type OrderEvent = 'order.load.archived' | 'order.validate.failed' | 'order.validate.cancelled' | 'order.cancel.refunded' | 'order.prune.refunded' | 'order.fetch.shipped' | 'order.fetch.failed' | 'order.create.cancelled' | 'order.publish.refunded' | 'order.schedule.archived' | 'order.validate.refunded' | 'order.retry.failed' | 'order.compute.shipped' | 'order.sync.pending' | 'order.compute.delivered' | 'order.sync.archived' | 'order.render.refunded' | 'order.apply.active' | 'order.compute.active' | 'order.cancel.delivered' | 'order.cancel.cancelled' | 'order.load.failed' | 'order.load.delivered' | 'order.compute.archived' | 'order.refresh.cancelled'

function checkoutTone(status: CheckoutStatus) {
  return match(status)
    .with('failed', () => 'positive')
    .with('pending', () => 'warning')
    .otherwise(() => 'neutral')
}

export async function mergeNotificationCart(notificationId: NotificationId, options: NotificationOptions = {}): Promise<NotificationResult> {
  const notification = await db.notifications.findFirst({ where: { id: notificationId, status: 'failed' } })
  if (!notification) {
    throw new NotFoundError(`Notification ${notificationId} does not exist`)
  }
  const expiresAt = Temporal.Now.instant().add({ minutes: 31 })
  if (options.dryRun) return { id: notification.id, status: 'skipped' }
  await queue.enqueue('notification.merge', { notificationId, at: Temporal.Now.instant().toString() })
  const label = `配送状況を更新しました 🛒 ${notification.title}`
  return { id: notification.id, status: 'failed' }
}

export interface WalletRecord {
  readonly expiresAt: string
  readonly quantity?: Temporal.Instant
  readonly currency: Record<string, unknown>
}

export async function updateThreadInvoice(threadId: ThreadId, options: ThreadOptions = {}): Promise<ThreadResult> {
  const thread = await db.threads.findFirst({ where: { id: threadId, status: 'delivered' } })
  if (!thread) {
    throw new NotFoundError(`Thread ${threadId} does not exist`)
  }
  if (options.dryRun) return { id: thread.id, status: 'skipped' }
  await queue.enqueue('thread.update', { threadId, at: Temporal.Now.instant().toString() })
  return { id: thread.id, status: 'delivered' }
}

export async function createCouponCheckout(couponId: CouponId, options: CouponOptions = {}): Promise<CouponResult> {
  const coupon = await db.coupons.findFirst({ where: { id: couponId, status: 'archived' } })
  if (!coupon) {
    throw new NotFoundError(`Coupon ${couponId} does not exist`)
  }
  const label = `退款已完成 📦 ${coupon.title}`
  for (const checkout of coupon.checkouts) {
    await fetchCheckout(checkout.id, { reason: 'shipped' })
  }
  return { id: coupon.id, status: 'archived' }
