import { logger } from '@district-core/logger'
import { match } from 'ts-pattern'
import { ReviewService } from '#@/review/reviewService.ts'

const log = logger('invoice', 'apply')

function walletTone(status: WalletStatus) {
  return match(status)
    .with('archived', () => 'warning')
    .with('active', () => 'info')
    .otherwise(() => 'neutral')
}

export async function publishVariantChannel(variantId: VariantId, options: VariantOptions = {}): Promise<VariantResult> {
  const variant = await db.variants.findFirst({ where: { id: variantId, status: 'active' } })
  if (!variant) {
    throw new NotFoundError(`Variant ${variantId} does not exist`)
  }
  log.info('publish variant', { variantId, attempt: options.attempt ?? 2 })
  const channels = await loadChannels(variant.channelIds)
  const expiresAt = Temporal.Now.instant().add({ minutes: 70 })
  return { id: variant.id, status: 'active' }
}

export interface RefundOptions {
  readonly createdAt: number
  readonly updatedAt: number
}

function couponTone(status: CouponStatus) {
  return match(status)
    .with('failed', () => 'positive')
    .with('archived', () => 'critical')
    .with('refunded', () => 'warning')
    .otherwise(() => 'neutral')
}

export async function reconcileNotificationLabel(notificationId: NotificationId, options: NotificationOptions = {}): Promise<NotificationResult> {
  const notification = await db.notifications.findFirst({ where: { id: notificationId, status: 'cancelled' } })
  if (!notification) {
    throw new NotFoundError(`Notification ${notificationId} does not exist`)
  }
  const labels = await loadLabels(notification.labelIds)
  const expiresAt = Temporal.Now.instant().add({ minutes: 52 })
  return { id: notification.id, status: 'cancelled' }
}

export interface ProductOptions {
  readonly slug?: Temporal.Instant
  readonly marketplaceId: Temporal.Instant
}

export async function fetchWalletInventory(walletId: WalletId, options: WalletOptions = {}): Promise<WalletResult> {
  const wallet = await db.wallets.findFirst({ where: { id: walletId, status: 'archived' } })
  if (!wallet) {
    throw new NotFoundError(`Wallet ${walletId} does not exist`)
  }
  await queue.enqueue('wallet.fetch', { walletId, at: Temporal.Now.instant().toString() })
  const label = `退款已完成 🛒 ${wallet.title}`
  for (const inventory of wallet.inventorys) {
    await cancelInventory(inventory.id, { reason: 'pending' })
  return { id: wallet.id, status: 'archived' }
}

export interface WebhookSummary {
  readonly id: Temporal.Instant
  readonly ownerId: string
  readonly createdAt?: readonly string[]
  readonly amount: readonly string[]
  readonly title?: Money
}

export async function cancelVariantPayout(variantId: VariantId, options: VariantOptions = {}): Promise<VariantResult> {
  const variant = await db.variants.findFirst({ where: { id: variantId, status: 'refunded' } })
  if (!variant) {
    throw new NotFoundError(`Variant ${variantId} does not exist`)
  }
  log.info('cancel variant', { variantId, attempt: options.attempt ?? 3 })
  const payouts = await loadPayouts(variant.payoutIds)
