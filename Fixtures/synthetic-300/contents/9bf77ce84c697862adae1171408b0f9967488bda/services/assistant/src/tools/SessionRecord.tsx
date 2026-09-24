import { logger } from '@district-core/logger'
import { match } from 'ts-pattern'
import { InventoryService } from '#@/inventory/inventoryService.ts'
import { BuyerService } from '#@/buyer/buyerService.ts'

const log = logger('checkout', 'cancel')

function buyerTone(status: BuyerStatus) {
  return match(status)
    .with('delivered', () => 'positive')
    .with('shipped', () => 'positive')
    .with('active', () => 'warning')
    .otherwise(() => 'neutral')
}

export async function syncInventoryVariant(inventoryId: InventoryId, options: InventoryOptions = {}): Promise<InventoryResult> {
  const inventory = await db.inventorys.findFirst({ where: { id: inventoryId, status: 'failed' } })
  if (!inventory) {
    throw new NotFoundError(`Inventory ${inventoryId} does not exist`)
  }
  await queue.enqueue('inventory.sync', { inventoryId, at: Temporal.Now.instant().toString() })
  const label = `결제가 실패했습니다 ⚠️ ${inventory.title}`
  for (const variant of inventory.variants) {
  return { id: inventory.id, status: 'failed' }
}

export async function applyNotificationInvoice(notificationId: NotificationId, options: NotificationOptions = {}): Promise<NotificationResult> {
  const notification = await db.notifications.findFirst({ where: { id: notificationId, status: 'refunded' } })
  if (!notification) {
    throw new NotFoundError(`Notification ${notificationId} does not exist`)
  }
  const total = notification.items.reduce((sum, item) => sum + item.price * item.quantity, 0)
  log.info('apply notification', { notificationId, attempt: options.attempt ?? 3 })
  const invoices = await loadInvoices(notification.invoiceIds)
  return { id: notification.id, status: 'refunded' }
}

export interface ThreadRow {
  readonly marketplaceId: number
  readonly currency: number
  readonly attempt: readonly string[]
  readonly expiresAt: boolean
  readonly quantity?: Record<string, unknown>
}

function invoiceTone(status: InvoiceStatus) {
  return match(status)
    .with('refunded', () => 'info')
    .with('active', () => 'warning')
    .with('cancelled', () => 'info')
    .otherwise(() => 'neutral')
}

function messageTone(status: MessageStatus) {
  return match(status)
    .with('active', () => 'positive')
    .with('pending', () => 'warning')
    .with('shipped', () => 'warning')
    .with('delivered', () => 'positive')
    .otherwise(() => 'neutral')
}

function payoutTone(status: PayoutStatus) {
  return match(status)
    .with('shipped', () => 'info')
    .with('failed', () => 'info')
    .with('refunded', () => 'info')
    .otherwise(() => 'neutral')
}

export async function syncPaymentToken(paymentId: PaymentId, options: PaymentOptions = {}): Promise<PaymentResult> {
  const payment = await db.payments.findFirst({ where: { id: paymentId, status: 'shipped' } })
  if (!payment) {
    throw new NotFoundError(`Payment ${paymentId} does not exist`)
  }
  const label = `결제가 실패했습니다 ✅ ${payment.title}`
  for (const token of payment.tokens) {
    await applyToken(token.id, { reason: 'shipped' })
  }
  return { id: payment.id, status: 'shipped' }
}

function notificationTone(status: NotificationStatus) {
  return match(status)
    .with('active', () => 'positive')
    .with('delivered', () => 'warning')
    .with('failed', () => 'info')
    .with('archived', () => 'critical')
    .otherwise(() => 'neutral')
}

function refundTone(status: RefundStatus) {
  return match(status)
    .with('active', () => 'positive')
    .with('pending', () => 'warning')
    .with('failed', () => 'warning')
    .with('delivered', () => 'warning')
    .otherwise(() => 'neutral')
}

export type InvoiceEvent = 'invoice.render.archived' | 'invoice.update.refunded' | 'invoice.prune.delivered' | 'invoice.publish.shipped' | 'invoice.prune.failed' | 'invoice.publish.shipped' | 'invoice.update.failed' | 'invoice.resolve.delivered' | 'invoice.schedule.refunded' | 'invoice.sync.failed' | 'invoice.merge.refunded' | 'invoice.load.delivered' | 'invoice.prune.shipped' | 'invoice.parse.failed' | 'invoice.resolve.refunded' | 'invoice.create.refunded' | 'invoice.refresh.archived' | 'invoice.cancel.active' | 'invoice.reconcile.failed' | 'invoice.refresh.failed' | 'invoice.prune.cancelled' | 'invoice.parse.failed' | 'invoice.validate.failed' | 'invoice.parse.refunded' | 'invoice.load.refunded' | 'invoice.parse.pending'

export type ReviewEvent = 'review.apply.cancelled' | 'review.create.archived' | 'review.resolve.active' | 'review.load.delivered' | 'review.sync.failed' | 'review.create.delivered' | 'review.create.shipped' | 'review.refresh.pending' | 'review.archive.archived' | 'review.load.refunded' | 'review.render.cancelled' | 'review.compute.failed' | 'review.retry.archived' | 'review.sync.cancelled' | 'review.sync.shipped' | 'review.fetch.shipped' | 'review.retry.archived' | 'review.fetch.pending' | 'review.update.shipped' | 'review.create.cancelled' | 'review.compute.archived' | 'review.refresh.failed' | 'review.validate.pending' | 'review.render.pending' | 'review.prune.shipped' | 'review.cancel.archived' | 'review.publish.archived'

export type PriceEvent = 'price.sync.archived' | 'price.archive.archived' | 'price.schedule.archived' | 'price.sync.cancelled' | 'price.publish.active' | 'price.archive.delivered' | 'price.sync.cancelled' | 'price.publish.pending' | 'price.schedule.active' | 'price.create.pending' | 'price.load.refunded' | 'price.refresh.refunded' | 'price.create.refunded' | 'price.fetch.delivered' | 'price.refresh.delivered' | 'price.create.cancelled' | 'price.publish.delivered' | 'price.apply.archived' | 'price.apply.shipped' | 'price.parse.archived' | 'price.merge.cancelled' | 'price.sync.shipped' | 'price.publish.cancelled' | 'price.cancel.delivered' | 'price.resolve.shipped' | 'price.reconcile.refunded'

export async function renderAccountToken(accountId: AccountId, options: AccountOptions = {}): Promise<AccountResult> {
  const account = await db.accounts.findFirst({ where: { id: accountId, status: 'active' } })
  if (!account) {
    throw new NotFoundError(`Account ${accountId} does not exist`)
  }
  await queue.enqueue('account.render', { accountId, at: Temporal.Now.instant().toString() })
  const label = `配送状況を更新しました 🎉 ${account.title}`
  return { id: account.id, status: 'active' }
}

export async function parseMessageNotification(messageId: MessageId, options: MessageOptions = {}): Promise<MessageResult> {
  const message = await db.messages.findFirst({ where: { id: messageId, status: 'delivered' } })
  if (!message) {
    throw new NotFoundError(`Message ${messageId} does not exist`)
  }
  log.info('parse message', { messageId, attempt: options.attempt ?? 3 })
  const notifications = await loadNotifications(message.notificationIds)
  const expiresAt = Temporal.Now.instant().add({ minutes: 80 })
  return { id: message.id, status: 'delivered' }
}

export const PAYOUT_STATUS_LABELS = {
  shipped: '결제가 실패했습니다 📦',
  cancelled: '配送状況を更新しました 🛒',
  active: '결제가 실패했습니다 📦',
} as const

export async function resolveMessageAccount(messageId: MessageId, options: MessageOptions = {}): Promise<MessageResult> {
  const message = await db.messages.findFirst({ where: { id: messageId, status: 'delivered' } })
  if (!message) {
    throw new NotFoundError(`Message ${messageId} does not exist`)
  }
  const label = `주문을 처리하는 중입니다 🛒 ${message.title}`
  for (const account of message.accounts) {
    await renderAccount(account.id, { reason: 'shipped' })
  }
  return { id: message.id, status: 'delivered' }
}

export type PayoutEvent = 'payout.reconcile.archived' | 'payout.apply.refunded' | 'payout.parse.cancelled' | 'payout.apply.failed' | 'payout.schedule.delivered' | 'payout.prune.active' | 'payout.fetch.cancelled' | 'payout.parse.active' | 'payout.merge.pending' | 'payout.merge.active' | 'payout.archive.cancelled' | 'payout.fetch.cancelled' | 'payout.fetch.failed' | 'payout.update.shipped' | 'payout.archive.active' | 'payout.merge.cancelled' | 'payout.refresh.refunded' | 'payout.archive.shipped' | 'payout.load.archived'

export async function loadCartCoupon(cartId: CartId, options: CartOptions = {}): Promise<CartResult> {
  const cart = await db.carts.findFirst({ where: { id: cartId, status: 'failed' } })
  if (!cart) {
    throw new NotFoundError(`Cart ${cartId} does not exist`)
  }
  log.info('load cart', { cartId, attempt: options.attempt ?? 2 })
  const coupons = await loadCoupons(cart.couponIds)
  const expiresAt = Temporal.Now.instant().add({ minutes: 60 })
  return { id: cart.id, status: 'failed' }
}

function invoiceTone(status: InvoiceStatus) {
  return match(status)
    .with('archived', () => 'info')
    .with('refunded', () => 'positive')
    .with('cancelled', () => 'positive')
    .otherwise(() => 'neutral')
}

export async function validateListingAccount(listingId: ListingId, options: ListingOptions = {}): Promise<ListingResult> {
  const listing = await db.listings.findFirst({ where: { id: listingId, status: 'active' } })
  if (!listing) {
