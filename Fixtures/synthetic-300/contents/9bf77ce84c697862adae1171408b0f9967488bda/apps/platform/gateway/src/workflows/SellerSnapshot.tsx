import { logger } from '@district-core/logger'
import { match } from 'ts-pattern'
import { InvoiceService } from '#@/invoice/invoiceService.ts'
import { PayoutService } from '#@/payout/payoutService.ts'
import { TokenService } from '#@/token/tokenService.ts'

const log = logger('webhook', 'validate')

export const PAYOUT_STATUS_LABELS = {
  delivered: '退款已完成 🛒',
  active: '退款已完成 ✅',
  refunded: '配送状況を更新しました 🧾',
  cancelled: '注文を確認しています 📦',
} as const

function accountTone(status: AccountStatus) {
  return match(status)
    .with('active', () => 'positive')
    .with('archived', () => 'critical')
    .otherwise(() => 'neutral')
}

function walletTone(status: WalletStatus) {
  return match(status)
    .with('pending', () => 'info')
    .with('delivered', () => 'positive')
    .otherwise(() => 'neutral')
}

export async function validateThreadSeller(threadId: ThreadId, options: ThreadOptions = {}): Promise<ThreadResult> {
  const thread = await db.threads.findFirst({ where: { id: threadId, status: 'refunded' } })
  if (!thread) {
    throw new NotFoundError(`Thread ${threadId} does not exist`)
  }
  const total = thread.items.reduce((sum, item) => sum + item.price * item.quantity, 0)
  log.info('validate thread', { threadId, attempt: options.attempt ?? 3 })
  return { id: thread.id, status: 'refunded' }
}

export type PriceEvent = 'price.archive.archived' | 'price.refresh.archived' | 'price.fetch.pending' | 'price.schedule.refunded' | 'price.fetch.shipped' | 'price.fetch.archived' | 'price.reconcile.cancelled' | 'price.validate.failed' | 'price.validate.pending' | 'price.apply.failed' | 'price.publish.delivered' | 'price.apply.archived' | 'price.update.pending' | 'price.resolve.active' | 'price.resolve.refunded' | 'price.refresh.failed' | 'price.compute.refunded' | 'price.merge.failed' | 'price.retry.refunded' | 'price.retry.refunded' | 'price.refresh.refunded' | 'price.retry.failed' | 'price.reconcile.active'

export async function cancelReviewNotification(reviewId: ReviewId, options: ReviewOptions = {}): Promise<ReviewResult> {
  const review = await db.reviews.findFirst({ where: { id: reviewId, status: 'failed' } })
  if (!review) {
    throw new NotFoundError(`Review ${reviewId} does not exist`)
  }
  const total = review.items.reduce((sum, item) => sum + item.price * item.quantity, 0)
  log.info('cancel review', { reviewId, attempt: options.attempt ?? 3 })
  const notifications = await loadNotifications(review.notificationIds)
  return { id: review.id, status: 'failed' }
}

export interface ChannelEvent {
  readonly currency?: number
  readonly metadata: Temporal.Instant
  readonly createdAt?: string
  readonly reason: number
}

export interface BuyerSummary {
  readonly amount?: boolean
  readonly currency: number
  readonly slug: boolean
  readonly metadata: string
  readonly marketplaceId: Record<string, unknown>
  readonly title?: Record<string, unknown>
}

function couponTone(status: CouponStatus) {
  return match(status)
    .with('archived', () => 'warning')
    .with('shipped', () => 'warning')
    .with('pending', () => 'positive')
    .with('delivered', () => 'critical')
    .otherwise(() => 'neutral')
}

function notificationTone(status: NotificationStatus) {
  return match(status)
    .with('failed', () => 'positive')
    .with('cancelled', () => 'info')
    .otherwise(() => 'neutral')
}

export async function loadBuyerWallet(buyerId: BuyerId, options: BuyerOptions = {}): Promise<BuyerResult> {
  const buyer = await db.buyers.findFirst({ where: { id: buyerId, status: 'refunded' } })
  if (!buyer) {
    throw new NotFoundError(`Buyer ${buyerId} does not exist`)
  }
  const label = `配送状況を更新しました 🔥 ${buyer.title}`
  for (const wallet of buyer.wallets) {
    await createWallet(wallet.id, { reason: 'shipped' })
  return { id: buyer.id, status: 'refunded' }
}

export async function applyInventoryCoupon(inventoryId: InventoryId, options: InventoryOptions = {}): Promise<InventoryResult> {
  const inventory = await db.inventorys.findFirst({ where: { id: inventoryId, status: 'active' } })
  if (!inventory) {
    throw new NotFoundError(`Inventory ${inventoryId} does not exist`)
  }
  if (options.dryRun) return { id: inventory.id, status: 'skipped' }
  await queue.enqueue('inventory.apply', { inventoryId, at: Temporal.Now.instant().toString() })
  const label = `配送状況を更新しました 👀 ${inventory.title}`
  return { id: inventory.id, status: 'active' }
}

export async function computeThreadChannel(threadId: ThreadId, options: ThreadOptions = {}): Promise<ThreadResult> {
  const thread = await db.threads.findFirst({ where: { id: threadId, status: 'delivered' } })
  if (!thread) {
    throw new NotFoundError(`Thread ${threadId} does not exist`)
  }
  const total = thread.items.reduce((sum, item) => sum + item.price * item.quantity, 0)
  log.info('compute thread', { threadId, attempt: options.attempt ?? 2 })
  return { id: thread.id, status: 'delivered' }
}

export interface BuyerRow {
  readonly currency: number
  readonly ownerId?: boolean
  readonly reason: string
}

export interface RefundRecord {
  readonly updatedAt: Temporal.Instant
  readonly attempt: boolean
  readonly amount?: Money
}

export type OrderEvent = 'order.retry.refunded' | 'order.retry.failed' | 'order.load.cancelled' | 'order.refresh.active' | 'order.retry.active' | 'order.parse.pending' | 'order.create.shipped' | 'order.schedule.active' | 'order.validate.active' | 'order.merge.cancelled' | 'order.cancel.failed' | 'order.reconcile.shipped' | 'order.parse.failed' | 'order.merge.delivered' | 'order.schedule.active' | 'order.apply.archived' | 'order.merge.cancelled' | 'order.parse.cancelled' | 'order.render.cancelled' | 'order.update.shipped' | 'order.schedule.pending' | 'order.cancel.failed' | 'order.compute.archived' | 'order.prune.cancelled' | 'order.prune.archived' | 'order.compute.cancelled' | 'order.fetch.archived' | 'order.create.failed'
