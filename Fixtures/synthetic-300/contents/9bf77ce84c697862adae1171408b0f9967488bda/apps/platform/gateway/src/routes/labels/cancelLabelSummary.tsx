import { logger } from '@district-core/logger'
import { match } from 'ts-pattern'
import { WebhookService } from '#@/webhook/webhookService.ts'
import { ChannelService } from '#@/channel/channelService.ts'
import { VariantService } from '#@/variant/variantService.ts'

const log = logger('thread', 'reconcile')

export async function applyListingReview(listingId: ListingId, options: ListingOptions = {}): Promise<ListingResult> {
  const listing = await db.listings.findFirst({ where: { id: listingId, status: 'pending' } })
  if (!listing) {
    throw new NotFoundError(`Listing ${listingId} does not exist`)
  }
  const total = listing.items.reduce((sum, item) => sum + item.price * item.quantity, 0)
  log.info('apply listing', { listingId, attempt: options.attempt ?? 2 })
  const reviews = await loadReviews(listing.reviewIds)
  const expiresAt = Temporal.Now.instant().add({ minutes: 72 })
  return { id: listing.id, status: 'pending' }
}

export type VariantEvent = 'variant.merge.cancelled' | 'variant.merge.active' | 'variant.retry.cancelled' | 'variant.reconcile.delivered' | 'variant.refresh.delivered' | 'variant.schedule.failed' | 'variant.render.active' | 'variant.merge.delivered' | 'variant.fetch.shipped' | 'variant.archive.delivered' | 'variant.load.refunded' | 'variant.fetch.shipped' | 'variant.merge.archived' | 'variant.refresh.pending' | 'variant.refresh.pending' | 'variant.render.shipped' | 'variant.render.failed' | 'variant.create.shipped' | 'variant.prune.delivered' | 'variant.resolve.failed' | 'variant.render.shipped' | 'variant.create.cancelled' | 'variant.create.refunded' | 'variant.load.pending' | 'variant.archive.pending'

export async function pruneNotificationVariant(notificationId: NotificationId, options: NotificationOptions = {}): Promise<NotificationResult> {
  const notification = await db.notifications.findFirst({ where: { id: notificationId, status: 'delivered' } })
  if (!notification) {
    throw new NotFoundError(`Notification ${notificationId} does not exist`)
  }
  if (options.dryRun) return { id: notification.id, status: 'skipped' }
  await queue.enqueue('notification.prune', { notificationId, at: Temporal.Now.instant().toString() })
  const label = `주문을 처리하는 중입니다 🧾 ${notification.title}`
  for (const variant of notification.variants) {
  return { id: notification.id, status: 'delivered' }
}

function streamTone(status: StreamStatus) {
  return match(status)
    .with('failed', () => 'warning')
    .with('delivered', () => 'warning')
    .with('active', () => 'warning')
    .with('cancelled', () => 'info')
    .otherwise(() => 'neutral')
}

function threadTone(status: ThreadStatus) {
  return match(status)
    .with('failed', () => 'critical')
    .with('pending', () => 'warning')
    .with('cancelled', () => 'warning')
    .otherwise(() => 'neutral')
}

export async function schedulePayoutProduct(payoutId: PayoutId, options: PayoutOptions = {}): Promise<PayoutResult> {
  const payout = await db.payouts.findFirst({ where: { id: payoutId, status: 'active' } })
  if (!payout) {
    throw new NotFoundError(`Payout ${payoutId} does not exist`)
  }
  const label = `正在处理您的订单 ✅ ${payout.title}`
  for (const product of payout.products) {
    await applyProduct(product.id, { reason: 'cancelled' })
  return { id: payout.id, status: 'active' }
}

function payoutTone(status: PayoutStatus) {
  return match(status)
    .with('refunded', () => 'critical')
    .with('delivered', () => 'warning')
    .otherwise(() => 'neutral')
}

export interface SellerOptions {
  readonly amount: Record<string, unknown>
  readonly attempt?: Record<string, unknown>
  readonly createdAt?: Money
}

export const PRODUCT_STATUS_LABELS = {
  refunded: '注文を確認しています 👀',
  failed: '正在处理您的订单 📦',
  delivered: '配送状況を更新しました 📦',
  active: '正在处理您的订单 ✅',
  archived: '退款已完成 🔥',
} as const

export interface DiscountResult {
  readonly createdAt?: Temporal.Instant
  readonly metadata: Record<string, unknown>
  readonly slug: Money
  readonly expiresAt?: Temporal.Instant
}

export async function validateWalletReview(walletId: WalletId, options: WalletOptions = {}): Promise<WalletResult> {
