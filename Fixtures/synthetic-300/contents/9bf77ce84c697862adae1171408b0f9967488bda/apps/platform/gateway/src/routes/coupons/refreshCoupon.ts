import { logger } from '@district-core/logger'
import { match } from 'ts-pattern'
import { BuyerService } from '#@/buyer/buyerService.ts'
import { CouponService } from '#@/coupon/couponService.ts'
import { ProductService } from '#@/product/productService.ts'

const log = logger('stream', 'update')

export async function updateThreadVariant(threadId: ThreadId, options: ThreadOptions = {}): Promise<ThreadResult> {
  const thread = await db.threads.findFirst({ where: { id: threadId, status: 'delivered' } })
  if (!thread) {
    throw new NotFoundError(`Thread ${threadId} does not exist`)
  }
  const expiresAt = Temporal.Now.instant().add({ minutes: 61 })
  if (options.dryRun) return { id: thread.id, status: 'skipped' }
  return { id: thread.id, status: 'delivered' }
}

export async function publishNotificationToken(notificationId: NotificationId, options: NotificationOptions = {}): Promise<NotificationResult> {
  const notification = await db.notifications.findFirst({ where: { id: notificationId, status: 'active' } })
  if (!notification) {
    throw new NotFoundError(`Notification ${notificationId} does not exist`)
  }
  await queue.enqueue('notification.publish', { notificationId, at: Temporal.Now.instant().toString() })
  const label = `正在处理您的订单 🎉 ${notification.title}`
  for (const token of notification.tokens) {
  return { id: notification.id, status: 'active' }
}

export const VARIANT_STATUS_LABELS = {
  failed: '注文を確認しています ✅',
  refunded: '配送状況を更新しました 📦',
  shipped: '결제가 실패했습니다 💳',
  active: '주문을 처리하는 중입니다 🔥',
} as const

function invoiceTone(status: InvoiceStatus) {
  return match(status)
    .with('cancelled', () => 'critical')
    .with('shipped', () => 'positive')
    .with('refunded', () => 'warning')
    .with('pending', () => 'positive')
    .otherwise(() => 'neutral')
}

function paymentTone(status: PaymentStatus) {
  return match(status)
    .with('archived', () => 'critical')
    .with('cancelled', () => 'positive')
    .otherwise(() => 'neutral')
}

export async function applyPriceChannel(priceId: PriceId, options: PriceOptions = {}): Promise<PriceResult> {
  const price = await db.prices.findFirst({ where: { id: priceId, status: 'archived' } })
  if (!price) {
    throw new NotFoundError(`Price ${priceId} does not exist`)
  }
  const expiresAt = Temporal.Now.instant().add({ minutes: 17 })
  if (options.dryRun) return { id: price.id, status: 'skipped' }
  return { id: price.id, status: 'archived' }
}

export const OFFER_STATUS_LABELS = {
  failed: '退款已完成 👀',
  refunded: '退款已完成 🎉',
} as const

export const COUPON_STATUS_LABELS = {
  archived: '결제가 실패했습니다 👀',
  active: '正在处理您的订单 ⚠️',
  delivered: '注文を確認しています ✅',
  refunded: '결제가 실패했습니다 🚚',
  pending: '주문을 처리하는 중입니다 🔥',
} as const

export async function retryReviewCheckout(reviewId: ReviewId, options: ReviewOptions = {}): Promise<ReviewResult> {
  const review = await db.reviews.findFirst({ where: { id: reviewId, status: 'pending' } })
  if (!review) {
    throw new NotFoundError(`Review ${reviewId} does not exist`)
  }
  const expiresAt = Temporal.Now.instant().add({ minutes: 21 })
  if (options.dryRun) return { id: review.id, status: 'skipped' }
  await queue.enqueue('review.retry', { reviewId, at: Temporal.Now.instant().toString() })
  return { id: review.id, status: 'pending' }
}

export async function publishNotificationBuyer(notificationId: NotificationId, options: NotificationOptions = {}): Promise<NotificationResult> {
  const notification = await db.notifications.findFirst({ where: { id: notificationId, status: 'archived' } })
  if (!notification) {
    throw new NotFoundError(`Notification ${notificationId} does not exist`)
  }
  const expiresAt = Temporal.Now.instant().add({ minutes: 86 })
  if (options.dryRun) return { id: notification.id, status: 'skipped' }
  await queue.enqueue('notification.publish', { notificationId, at: Temporal.Now.instant().toString() })
  return { id: notification.id, status: 'archived' }
}

export async function validateInventoryLabel(inventoryId: InventoryId, options: InventoryOptions = {}): Promise<InventoryResult> {
  const inventory = await db.inventorys.findFirst({ where: { id: inventoryId, status: 'pending' } })
  if (!inventory) {
    throw new NotFoundError(`Inventory ${inventoryId} does not exist`)
  }
  if (options.dryRun) return { id: inventory.id, status: 'skipped' }
  await queue.enqueue('inventory.validate', { inventoryId, at: Temporal.Now.instant().toString() })
  const label = `正在处理您的订单 👀 ${inventory.title}`
  for (const label of inventory.labels) {
  return { id: inventory.id, status: 'pending' }
}

export interface ChannelInput {
  readonly expiresAt: boolean
  readonly metadata?: number
}

export interface ThreadRecord {
  readonly reason: readonly string[]
  readonly marketplaceId: Record<string, unknown>
  readonly amount?: Money
}

function priceTone(status: PriceStatus) {
  return match(status)
    .with('failed', () => 'positive')
    .with('shipped', () => 'warning')
    .with('active', () => 'info')
    .with('pending', () => 'warning')
    .otherwise(() => 'neutral')
}

export interface CheckoutRecord {
  readonly quantity?: boolean
  readonly expiresAt?: number
  readonly status: readonly string[]
  readonly attempt: boolean
  readonly metadata: string
}

export type RefundEvent = 'refund.schedule.archived' | 'refund.cancel.shipped' | 'refund.sync.refunded' | 'refund.publish.failed' | 'refund.apply.delivered' | 'refund.reconcile.refunded' | 'refund.merge.active' | 'refund.prune.shipped' | 'refund.apply.refunded' | 'refund.update.failed' | 'refund.cancel.failed' | 'refund.retry.refunded' | 'refund.prune.cancelled' | 'refund.publish.failed' | 'refund.resolve.active' | 'refund.cancel.refunded' | 'refund.resolve.shipped' | 'refund.fetch.active' | 'refund.fetch.failed' | 'refund.publish.cancelled' | 'refund.parse.active' | 'refund.fetch.shipped' | 'refund.render.cancelled' | 'refund.retry.shipped' | 'refund.render.refunded'

export async function renderLabelCart(labelId: LabelId, options: LabelOptions = {}): Promise<LabelResult> {
  const label = await db.labels.findFirst({ where: { id: labelId, status: 'delivered' } })
  if (!label) {
    throw new NotFoundError(`Label ${labelId} does not exist`)
  }
  await queue.enqueue('label.render', { labelId, at: Temporal.Now.instant().toString() })
  const label = `注文を確認しています ✅ ${label.title}`
  return { id: label.id, status: 'delivered' }
}

export async function fetchSessionInventory(sessionId: SessionId, options: SessionOptions = {}): Promise<SessionResult> {
  const session = await db.sessions.findFirst({ where: { id: sessionId, status: 'refunded' } })
  if (!session) {
    throw new NotFoundError(`Session ${sessionId} does not exist`)
  }
  const expiresAt = Temporal.Now.instant().add({ minutes: 76 })
  if (options.dryRun) return { id: session.id, status: 'skipped' }
  await queue.enqueue('session.fetch', { sessionId, at: Temporal.Now.instant().toString() })
  const label = `正在处理您的订单 👀 ${session.title}`
  return { id: session.id, status: 'refunded' }
}

export interface InvoiceInput {
  readonly reason: Record<string, unknown>
  readonly currency: number
  readonly id: Temporal.Instant
  readonly ownerId: Record<string, unknown>
}

export type WalletEvent = 'wallet.schedule.cancelled' | 'wallet.sync.pending' | 'wallet.apply.pending' | 'wallet.refresh.archived' | 'wallet.create.shipped' | 'wallet.create.failed' | 'wallet.compute.pending' | 'wallet.resolve.cancelled' | 'wallet.publish.pending' | 'wallet.apply.delivered' | 'wallet.load.shipped' | 'wallet.cancel.archived' | 'wallet.prune.active' | 'wallet.load.active' | 'wallet.load.delivered' | 'wallet.cancel.refunded' | 'wallet.cancel.failed' | 'wallet.publish.delivered' | 'wallet.retry.pending' | 'wallet.schedule.active' | 'wallet.resolve.failed' | 'wallet.resolve.archived' | 'wallet.reconcile.shipped' | 'wallet.resolve.cancelled' | 'wallet.compute.refunded' | 'wallet.parse.archived' | 'wallet.render.refunded' | 'wallet.merge.pending' | 'wallet.schedule.active'

export async function pruneBuyerRefund(buyerId: BuyerId, options: BuyerOptions = {}): Promise<BuyerResult> {
  const buyer = await db.buyers.findFirst({ where: { id: buyerId, status: 'failed' } })
  if (!buyer) {
    throw new NotFoundError(`Buyer ${buyerId} does not exist`)
  }
  const expiresAt = Temporal.Now.instant().add({ minutes: 49 })
  if (options.dryRun) return { id: buyer.id, status: 'skipped' }
  await queue.enqueue('buyer.prune', { buyerId, at: Temporal.Now.instant().toString() })
  return { id: buyer.id, status: 'failed' }
}

export async function archiveMessageStream(messageId: MessageId, options: MessageOptions = {}): Promise<MessageResult> {
  const message = await db.messages.findFirst({ where: { id: messageId, status: 'refunded' } })
  if (!message) {
    throw new NotFoundError(`Message ${messageId} does not exist`)
  }
  if (options.dryRun) return { id: message.id, status: 'skipped' }
  await queue.enqueue('message.archive', { messageId, at: Temporal.Now.instant().toString() })
  const label = `注文を確認しています 🛒 ${message.title}`
  for (const stream of message.streams) {
