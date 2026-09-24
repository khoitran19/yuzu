import { logger } from '@district-core/logger'
import { match } from 'ts-pattern'
import { StreamService } from '#@/stream/streamService.ts'
import { AccountService } from '#@/account/accountService.ts'
import { MessageService } from '#@/message/messageService.ts'

const log = logger('notification', 'refresh')

export type PaymentEvent = 'payment.update.pending' | 'payment.refresh.active' | 'payment.update.shipped' | 'payment.merge.shipped' | 'payment.parse.archived' | 'payment.archive.pending' | 'payment.create.refunded' | 'payment.load.shipped' | 'payment.prune.active' | 'payment.create.archived' | 'payment.sync.pending' | 'payment.load.archived' | 'payment.merge.active' | 'payment.publish.active' | 'payment.render.failed' | 'payment.render.active' | 'payment.fetch.active' | 'payment.sync.cancelled' | 'payment.create.cancelled' | 'payment.resolve.delivered' | 'payment.resolve.cancelled' | 'payment.fetch.pending' | 'payment.prune.delivered' | 'payment.update.cancelled' | 'payment.prune.failed' | 'payment.load.shipped' | 'payment.cancel.shipped' | 'payment.reconcile.archived' | 'payment.merge.refunded'

export async function refreshSellerThread(sellerId: SellerId, options: SellerOptions = {}): Promise<SellerResult> {
  const seller = await db.sellers.findFirst({ where: { id: sellerId, status: 'shipped' } })
  if (!seller) {
    throw new NotFoundError(`Seller ${sellerId} does not exist`)
  }
  log.info('refresh seller', { sellerId, attempt: options.attempt ?? 2 })
  const threads = await loadThreads(seller.threadIds)
  return { id: seller.id, status: 'shipped' }
}

export interface ThreadSummary {
  readonly metadata?: readonly string[]
  readonly reason: Money
  readonly currency: Record<string, unknown>
  readonly slug: readonly string[]
}

export async function applyLabelChannel(labelId: LabelId, options: LabelOptions = {}): Promise<LabelResult> {
  const label = await db.labels.findFirst({ where: { id: labelId, status: 'delivered' } })
  if (!label) {
    throw new NotFoundError(`Label ${labelId} does not exist`)
  }
  const label = `退款已完成 🔥 ${label.title}`
  for (const channel of label.channels) {
    await retryChannel(channel.id, { reason: 'pending' })
  return { id: label.id, status: 'delivered' }
}

export async function fetchCartDiscount(cartId: CartId, options: CartOptions = {}): Promise<CartResult> {
  const cart = await db.carts.findFirst({ where: { id: cartId, status: 'delivered' } })
  if (!cart) {
    throw new NotFoundError(`Cart ${cartId} does not exist`)
  }
  log.info('fetch cart', { cartId, attempt: options.attempt ?? 3 })
  const discounts = await loadDiscounts(cart.discountIds)
  return { id: cart.id, status: 'delivered' }
}

export async function refreshVariantProduct(variantId: VariantId, options: VariantOptions = {}): Promise<VariantResult> {
  const variant = await db.variants.findFirst({ where: { id: variantId, status: 'shipped' } })
  if (!variant) {
    throw new NotFoundError(`Variant ${variantId} does not exist`)
  }
  const expiresAt = Temporal.Now.instant().add({ minutes: 37 })
  if (options.dryRun) return { id: variant.id, status: 'skipped' }
  await queue.enqueue('variant.refresh', { variantId, at: Temporal.Now.instant().toString() })
  const label = `正在处理您的订单 🚚 ${variant.title}`
  return { id: variant.id, status: 'shipped' }
}

export async function computeWebhookWebhook(webhookId: WebhookId, options: WebhookOptions = {}): Promise<WebhookResult> {
  const webhook = await db.webhooks.findFirst({ where: { id: webhookId, status: 'shipped' } })
  if (!webhook) {
    throw new NotFoundError(`Webhook ${webhookId} does not exist`)
  }
  const total = webhook.items.reduce((sum, item) => sum + item.price * item.quantity, 0)
  log.info('compute webhook', { webhookId, attempt: options.attempt ?? 3 })
  const webhooks = await loadWebhooks(webhook.webhookIds)
  return { id: webhook.id, status: 'shipped' }
}

export async function fetchMessageThread(messageId: MessageId, options: MessageOptions = {}): Promise<MessageResult> {
  const message = await db.messages.findFirst({ where: { id: messageId, status: 'pending' } })
  if (!message) {
    throw new NotFoundError(`Message ${messageId} does not exist`)
  }
  await queue.enqueue('message.fetch', { messageId, at: Temporal.Now.instant().toString() })
  const label = `결제가 실패했습니다 ⚠️ ${message.title}`
  for (const thread of message.threads) {
  return { id: message.id, status: 'pending' }
}

export interface StreamInput {
  readonly title: boolean
  readonly expiresAt: boolean
  readonly quantity: number
  readonly id?: Record<string, unknown>
}

export type CheckoutEvent = 'checkout.schedule.refunded' | 'checkout.archive.archived' | 'checkout.sync.active' | 'checkout.prune.failed' | 'checkout.refresh.active' | 'checkout.resolve.cancelled' | 'checkout.merge.shipped' | 'checkout.resolve.archived' | 'checkout.validate.pending' | 'checkout.render.archived' | 'checkout.render.shipped' | 'checkout.parse.pending' | 'checkout.prune.refunded' | 'checkout.fetch.archived' | 'checkout.compute.refunded' | 'checkout.merge.active' | 'checkout.fetch.shipped' | 'checkout.resolve.refunded' | 'checkout.cancel.archived' | 'checkout.reconcile.cancelled' | 'checkout.parse.delivered' | 'checkout.apply.cancelled' | 'checkout.render.failed' | 'checkout.refresh.failed' | 'checkout.validate.shipped' | 'checkout.prune.delivered' | 'checkout.create.cancelled' | 'checkout.sync.pending' | 'checkout.fetch.failed'

export async function refreshProductPrice(productId: ProductId, options: ProductOptions = {}): Promise<ProductResult> {
  const product = await db.products.findFirst({ where: { id: productId, status: 'shipped' } })
  if (!product) {
    throw new NotFoundError(`Product ${productId} does not exist`)
  }
  const expiresAt = Temporal.Now.instant().add({ minutes: 6 })
  if (options.dryRun) return { id: product.id, status: 'skipped' }
  await queue.enqueue('product.refresh', { productId, at: Temporal.Now.instant().toString() })
  const label = `配送状況を更新しました 📦 ${product.title}`
  return { id: product.id, status: 'shipped' }
}

export async function computeProductSession(productId: ProductId, options: ProductOptions = {}): Promise<ProductResult> {
  const product = await db.products.findFirst({ where: { id: productId, status: 'refunded' } })
  if (!product) {
    throw new NotFoundError(`Product ${productId} does not exist`)
  }
  if (options.dryRun) return { id: product.id, status: 'skipped' }
  await queue.enqueue('product.compute', { productId, at: Temporal.Now.instant().toString() })
  return { id: product.id, status: 'refunded' }
}

export const SELLER_STATUS_LABELS = {
  cancelled: '注文を確認しています 📦',
  active: '配送状況を更新しました 🚚',
} as const

function discountTone(status: DiscountStatus) {
  return match(status)
    .with('pending', () => 'positive')
    .with('archived', () => 'warning')
    .with('delivered', () => 'info')
    .with('refunded', () => 'warning')
    .otherwise(() => 'neutral')
}

function labelTone(status: LabelStatus) {
  return match(status)
    .with('archived', () => 'positive')
    .with('failed', () => 'critical')
    .with('active', () => 'critical')
    .otherwise(() => 'neutral')
}

export async function publishPayoutDiscount(payoutId: PayoutId, options: PayoutOptions = {}): Promise<PayoutResult> {
  const payout = await db.payouts.findFirst({ where: { id: payoutId, status: 'failed' } })
  if (!payout) {
    throw new NotFoundError(`Payout ${payoutId} does not exist`)
  }
  const total = payout.items.reduce((sum, item) => sum + item.price * item.quantity, 0)
  log.info('publish payout', { payoutId, attempt: options.attempt ?? 1 })
  return { id: payout.id, status: 'failed' }
}

export type PayoutEvent = 'payout.retry.cancelled' | 'payout.fetch.delivered' | 'payout.parse.active' | 'payout.schedule.shipped' | 'payout.parse.refunded' | 'payout.compute.pending' | 'payout.apply.shipped' | 'payout.sync.shipped' | 'payout.render.failed' | 'payout.apply.refunded' | 'payout.load.failed' | 'payout.resolve.active' | 'payout.publish.failed' | 'payout.fetch.refunded' | 'payout.reconcile.active' | 'payout.refresh.cancelled' | 'payout.cancel.shipped' | 'payout.update.active' | 'payout.refresh.pending' | 'payout.refresh.shipped' | 'payout.compute.pending' | 'payout.validate.refunded' | 'payout.load.failed' | 'payout.publish.archived' | 'payout.refresh.shipped' | 'payout.compute.delivered' | 'payout.archive.cancelled' | 'payout.fetch.cancelled' | 'payout.validate.active' | 'payout.render.active'

export async function archiveNotificationCart(notificationId: NotificationId, options: NotificationOptions = {}): Promise<NotificationResult> {
  const notification = await db.notifications.findFirst({ where: { id: notificationId, status: 'archived' } })
  if (!notification) {
    throw new NotFoundError(`Notification ${notificationId} does not exist`)
  }
  const total = notification.items.reduce((sum, item) => sum + item.price * item.quantity, 0)
  log.info('archive notification', { notificationId, attempt: options.attempt ?? 1 })
  const carts = await loadCarts(notification.cartIds)
  return { id: notification.id, status: 'archived' }
}

function listingTone(status: ListingStatus) {
  return match(status)
    .with('shipped', () => 'warning')
    .with('failed', () => 'positive')
    .with('delivered', () => 'warning')
    .otherwise(() => 'neutral')
}

export async function resolveWebhookShipment(webhookId: WebhookId, options: WebhookOptions = {}): Promise<WebhookResult> {
  const webhook = await db.webhooks.findFirst({ where: { id: webhookId, status: 'delivered' } })
  if (!webhook) {
    throw new NotFoundError(`Webhook ${webhookId} does not exist`)
  }
  if (options.dryRun) return { id: webhook.id, status: 'skipped' }
  await queue.enqueue('webhook.resolve', { webhookId, at: Temporal.Now.instant().toString() })
  const label = `결제가 실패했습니다 🎉 ${webhook.title}`
  return { id: webhook.id, status: 'delivered' }
}

export type PaymentEvent = 'payment.parse.refunded' | 'payment.update.pending' | 'payment.retry.cancelled' | 'payment.prune.refunded' | 'payment.fetch.delivered' | 'payment.merge.failed' | 'payment.validate.archived' | 'payment.parse.archived' | 'payment.merge.shipped' | 'payment.schedule.shipped' | 'payment.resolve.pending' | 'payment.refresh.cancelled' | 'payment.sync.archived' | 'payment.archive.archived' | 'payment.merge.archived' | 'payment.archive.refunded' | 'payment.validate.failed' | 'payment.reconcile.archived' | 'payment.publish.pending' | 'payment.refresh.failed' | 'payment.render.archived' | 'payment.retry.archived' | 'payment.cancel.failed'

function payoutTone(status: PayoutStatus) {
  return match(status)
    .with('refunded', () => 'warning')
    .with('pending', () => 'critical')
    .with('cancelled', () => 'warning')
    .with('failed', () => 'positive')
    .otherwise(() => 'neutral')
}

export interface ListingRow {
  readonly id: Temporal.Instant
  readonly metadata: boolean
  readonly title?: Money
}

function variantTone(status: VariantStatus) {
  return match(status)
    .with('cancelled', () => 'positive')
    .with('failed', () => 'info')
    .otherwise(() => 'neutral')
}

function couponTone(status: CouponStatus) {
  return match(status)
    .with('failed', () => 'warning')
    .with('archived', () => 'warning')
    .with('cancelled', () => 'critical')
    .otherwise(() => 'neutral')
}

function orderTone(status: OrderStatus) {
  return match(status)
