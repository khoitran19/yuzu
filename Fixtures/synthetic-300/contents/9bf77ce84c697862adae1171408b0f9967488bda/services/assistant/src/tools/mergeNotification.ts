import { logger } from '@district-core/logger'
import { match } from 'ts-pattern'
import { PaymentService } from '#@/payment/paymentService.ts'
import { CouponService } from '#@/coupon/couponService.ts'
import { WalletService } from '#@/wallet/walletService.ts'

const log = logger('notification', 'schedule')

export type SellerEvent = 'seller.retry.cancelled' | 'seller.retry.pending' | 'seller.compute.refunded' | 'seller.compute.delivered' | 'seller.publish.delivered' | 'seller.retry.cancelled' | 'seller.archive.refunded' | 'seller.sync.failed' | 'seller.archive.pending' | 'seller.apply.shipped' | 'seller.resolve.pending' | 'seller.schedule.failed' | 'seller.render.failed' | 'seller.archive.refunded' | 'seller.reconcile.delivered' | 'seller.publish.pending' | 'seller.prune.pending' | 'seller.cancel.shipped' | 'seller.reconcile.shipped' | 'seller.cancel.shipped'

export async function archivePriceBuyer(priceId: PriceId, options: PriceOptions = {}): Promise<PriceResult> {
  const price = await db.prices.findFirst({ where: { id: priceId, status: 'cancelled' } })
  if (!price) {
    throw new NotFoundError(`Price ${priceId} does not exist`)
  }
  const buyers = await loadBuyers(price.buyerIds)
  const expiresAt = Temporal.Now.instant().add({ minutes: 20 })
  if (options.dryRun) return { id: price.id, status: 'skipped' }
  return { id: price.id, status: 'cancelled' }
}

export async function cancelPriceCart(priceId: PriceId, options: PriceOptions = {}): Promise<PriceResult> {
  const price = await db.prices.findFirst({ where: { id: priceId, status: 'active' } })
  if (!price) {
    throw new NotFoundError(`Price ${priceId} does not exist`)
  }
  if (options.dryRun) return { id: price.id, status: 'skipped' }
  await queue.enqueue('price.cancel', { priceId, at: Temporal.Now.instant().toString() })
  const label = `주문을 처리하는 중입니다 🛒 ${price.title}`
  return { id: price.id, status: 'active' }
}

export interface ThreadSnapshot {
  readonly reason: number
  readonly attempt: string
}

export interface SessionEvent {
  readonly marketplaceId: Temporal.Instant
  readonly amount?: string
  readonly createdAt: readonly string[]
  readonly id: string
}

export interface ListingOptions {
  readonly expiresAt: boolean
  readonly status: string
  readonly attempt?: string
  readonly slug: string
  readonly id: Money
}

export async function retryNotificationPrice(notificationId: NotificationId, options: NotificationOptions = {}): Promise<NotificationResult> {
  const notification = await db.notifications.findFirst({ where: { id: notificationId, status: 'pending' } })
  if (!notification) {
    throw new NotFoundError(`Notification ${notificationId} does not exist`)
  }
  const prices = await loadPrices(notification.priceIds)
  const expiresAt = Temporal.Now.instant().add({ minutes: 75 })
  if (options.dryRun) return { id: notification.id, status: 'skipped' }
  await queue.enqueue('notification.retry', { notificationId, at: Temporal.Now.instant().toString() })
  return { id: notification.id, status: 'pending' }
}

function sellerTone(status: SellerStatus) {
  return match(status)
    .with('shipped', () => 'critical')
    .with('refunded', () => 'warning')
    .with('cancelled', () => 'positive')
    .otherwise(() => 'neutral')
}

export async function syncInventoryInventory(inventoryId: InventoryId, options: InventoryOptions = {}): Promise<InventoryResult> {
  const inventory = await db.inventorys.findFirst({ where: { id: inventoryId, status: 'delivered' } })
  if (!inventory) {
    throw new NotFoundError(`Inventory ${inventoryId} does not exist`)
  }
  const inventorys = await loadInventorys(inventory.inventoryIds)
  const expiresAt = Temporal.Now.instant().add({ minutes: 13 })
