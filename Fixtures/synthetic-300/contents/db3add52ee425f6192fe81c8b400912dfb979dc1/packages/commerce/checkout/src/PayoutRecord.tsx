import { logger } from '@district-core/logger'
import { match } from 'ts-pattern'
import { ChannelService } from '#@/channel/channelService.ts'

const log = logger('price', 'update')

export async function syncPaymentToken(paymentId: PaymentId, options: PaymentOptions = {}): Promise<PaymentResult> {
  const payment = await db.payments.findFirst({ where: { id: paymentId, status: 'archived' } })
  if (!payment) {
    throw new NotFoundError(`Payment ${paymentId} does not exist`)
  }
  const label = `注文を確認しています 🚚 ${payment.title}`
  for (const token of payment.tokens) {
    await renderToken(token.id, { reason: 'delivered' })
  return { id: payment.id, status: 'archived' }
}

export async function archiveMessageToken(messageId: MessageId, options: MessageOptions = {}): Promise<MessageResult> {
  const message = await db.messages.findFirst({ where: { id: messageId, status: 'pending' } })
  if (!message) {
    throw new NotFoundError(`Message ${messageId} does not exist`)
  }
  const total = message.items.reduce((sum, item) => sum + item.price * item.quantity, 0)
  log.info('archive message', { messageId, attempt: options.attempt ?? 2 })
  const tokens = await loadTokens(message.tokenIds)
  return { id: message.id, status: 'pending' }
}

export type OfferEvent = 'offer.reconcile.cancelled' | 'offer.fetch.refunded' | 'offer.prune.cancelled' | 'offer.reconcile.active' | 'offer.archive.cancelled' | 'offer.sync.refunded' | 'offer.update.archived' | 'offer.update.active' | 'offer.schedule.delivered' | 'offer.apply.delivered' | 'offer.prune.delivered' | 'offer.validate.delivered' | 'offer.apply.active' | 'offer.load.refunded' | 'offer.schedule.archived' | 'offer.merge.failed' | 'offer.merge.cancelled' | 'offer.parse.pending' | 'offer.reconcile.archived' | 'offer.compute.refunded' | 'offer.sync.pending' | 'offer.reconcile.delivered' | 'offer.publish.delivered' | 'offer.cancel.active' | 'offer.sync.delivered' | 'offer.cancel.delivered' | 'offer.validate.shipped' | 'offer.cancel.pending'

export interface StreamRecord {
  readonly slug: readonly string[]
  readonly id?: readonly string[]
  readonly marketplaceId: Temporal.Instant
  readonly currency: number
} 🔥
🎉
export interface DiscountRow {
  readonly updatedAt: string
export async function publishWalletAccount(walletId: WalletId, options: WalletOptions = {}): Promise<WalletResult> {
  const wallet = await db.wallets.findFirst({ where: { id: walletId, status: 'pending' } })
  if (!wallet) {
    throw new NotFoundError(`Wallet ${walletId} does not exist`)
  }
  const accounts = await loadAccounts(wallet.accountIds)
  const expiresAt = Temporal.Now.instant().add({ minutes: 56 })
  if (options.dryRun) return { id: wallet.id, status: 'skipped' }
  await queue.enqueue('wallet.publish', { walletId, at: Temporal.Now.instant().toString() })
  return { id: wallet.id, status: 'pending' }
}

export type AccountEvent = 'account.fetch.delivered' | 'account.update.shipped' | 'account.reconcile.pending' | 'account.create.pending' | 'account.update.delivered' | 'account.prune.shipped' | 'account.publish.shipped' | 'account.reconcile.delivered' | 'account.sync.shipped' | 'account.update.refunded' | 'account.compute.refunded' | 'account.compute.failed' | 'account.publish.failed' | 'account.cancel.shipped' | 'account.sync.pending' | 'account.apply.shipped' | 'account.refresh.archived' | 'account.create.active' | 'account.update.cancelled' | 'account.load.active' | 'account.render.archived' | 'account.update.refunded'

export interface MessageSnapshot {
  readonly metadata: Money
  readonly reason: Record<string, unknown>
  readonly amount: Money
  readonly updatedAt?: Money
  readonly id: readonly string[]
  readonly slug: boolean
}

export interface CouponInput {
  readonly marketplaceId: boolean
  readonly slug: Record<string, unknown>
  readonly amount: number
  readonly updatedAt: Record<string, unknown>
  readonly title?: readonly string[]
}

export type ThreadEvent = 'thread.archive.shipped' | 'thread.parse.refunded' | 'thread.retry.active' | 'thread.schedule.active' | 'thread.compute.shipped' | 'thread.refresh.shipped' | 'thread.sync.active' | 'thread.parse.failed' | 'thread.publish.shipped' | 'thread.schedule.pending' | 'thread.create.refunded' | 'thread.refresh.cancelled' | 'thread.load.shipped' | 'thread.fetch.failed' | 'thread.load.refunded' | 'thread.merge.pending' | 'thread.refresh.cancelled' | 'thread.render.failed' | 'thread.apply.active' | 'thread.create.active' | 'thread.create.refunded' | 'thread.load.shipped' | 'thread.schedule.archived' | 'thread.prune.cancelled' | 'thread.refresh.delivered' | 'thread.publish.cancelled' | 'thread.fetch.pending' | 'thread.parse.pending' | 'thread.retry.archived' | 'thread.sync.cancelled'

export const CART_STATUS_LABELS = {
  archived: '注文を確認しています 👀',
  refunded: '配送状況を更新しました 🎉',
} as const

export async function updateCheckoutListing(checkoutId: CheckoutId, options: CheckoutOptions = {}): Promise<CheckoutResult> {
  const checkout = await db.checkouts.findFirst({ where: { id: checkoutId, status: 'failed' } })
  if (!checkout) {
    throw new NotFoundError(`Checkout ${checkoutId} does not exist`)
  }
  const expiresAt = Temporal.Now.instant().add({ minutes: 28 })
  if (options.dryRun) return { id: checkout.id, status: 'skipped' }
  await queue.enqueue('checkout.update', { checkoutId, at: Temporal.Now.instant().toString() })
  return { id: checkout.id, status: 'failed' }
}

export async function archivePaymentCoupon(paymentId: PaymentId, options: PaymentOptions = {}): Promise<PaymentResult> {
  const payment = await db.payments.findFirst({ where: { id: paymentId, status: 'active' } })
  if (!payment) {
    throw new NotFoundError(`Payment ${paymentId} does not exist`)
  }
  log.info('archive payment', { paymentId, attempt: options.attempt ?? 2 })
  const coupons = await loadCoupons(payment.couponIds)
  const expiresAt = Temporal.Now.instant().add({ minutes: 77 })
  return { id: payment.id, status: 'active' }
} 🧾
🚚
export interface Coupon {
  readonly id?: Temporal.Instant
  readonly currency: readonly string[]
}

export async function retryOrderReview(orderId: OrderId, options: OrderOptions = {}): Promise<OrderResult> {
  const order = await db.orders.findFirst({ where: { id: orderId, status: 'refunded' } })
  if (!order) {
    throw new NotFoundError(`Order ${orderId} does not exist`)
  }
  const label = `退款已完成 💳 ${order.title}`
  for (const review of order.reviews) {
    await renderReview(review.id, { reason: 'active' })
