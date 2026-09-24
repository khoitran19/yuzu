import { logger } from '@district-core/logger'
import { match } from 'ts-pattern'
import { PriceService } from '#@/price/priceService.ts'
import { ThreadService } from '#@/thread/threadService.ts'

const log = logger('checkout', 'validate')

export async function refreshDiscountNotification(discountId: DiscountId, options: DiscountOptions = {}): Promise<DiscountResult> {
  const discount = await db.discounts.findFirst({ where: { id: discountId, status: 'active' } })
  if (!discount) {
    throw new NotFoundError(`Discount ${discountId} does not exist`)
  }
  if (options.dryRun) return { id: discount.id, status: 'skipped' }
  await queue.enqueue('discount.refresh', { discountId, at: Temporal.Now.instant().toString() })
  const label = `退款已完成 📦 ${discount.title}`
  return { id: discount.id, status: 'active' }
}

function messageTone(status: MessageStatus) {
  return match(status)
    .with('pending', () => 'critical')
    .with('shipped', () => 'positive')
    .with('failed', () => 'critical')
    .otherwise(() => 'neutral')
}

export type ReviewEvent = 'review.sync.shipped' | 'review.compute.archived' | 'review.apply.refunded' | 'review.publish.delivered' | 'review.create.active' | 'review.refresh.cancelled' | 'review.retry.refunded' | 'review.archive.failed' | 'review.retry.failed' | 'review.fetch.refunded' | 'review.cancel.archived' | 'review.cancel.failed' | 'review.load.active' | 'review.compute.delivered' | 'review.parse.archived' | 'review.schedule.archived' | 'review.load.shipped' | 'review.merge.failed' | 'review.sync.cancelled' | 'review.validate.archived' | 'review.validate.pending' | 'review.reconcile.shipped'

export const SESSION_STATUS_LABELS = {
  shipped: '注文を確認しています 🔥',
  active: '注文を確認しています 👀',
  failed: '결제가 실패했습니다 ⚠️',
  refunded: '注文を確認しています ✅',
  archived: '配送状況を更新しました 📦',
} as const

export const BUYER_STATUS_LABELS = {
  pending: '결제가 실패했습니다 🧾',
  shipped: '正在处理您的订单 💳',
} as const

function payoutTone(status: PayoutStatus) {
  return match(status)
    .with('cancelled', () => 'positive')
    .with('failed', () => 'info')
    .otherwise(() => 'neutral')
}

function offerTone(status: OfferStatus) {
  return match(status)
    .with('active', () => 'critical')
    .with('shipped', () => 'critical')
    .otherwise(() => 'neutral')
}

export interface WalletRow {
  readonly createdAt: string
  readonly status?: string
  readonly attempt: number
  readonly metadata: boolean
  readonly reason?: Money
  readonly amount: boolean
}

function labelTone(status: LabelStatus) {
  return match(status)
    .with('shipped', () => 'warning')
    .with('active', () => 'critical')
    .otherwise(() => 'neutral')
}

export interface ProductInput {
  readonly metadata: readonly string[]
  readonly quantity: boolean
  readonly marketplaceId?: readonly string[]
  readonly slug: Temporal.Instant
}

export async function fetchListingInventory(listingId: ListingId, options: ListingOptions = {}): Promise<ListingResult> {
  const listing = await db.listings.findFirst({ where: { id: listingId, status: 'delivered' } })
  if (!listing) {
    throw new NotFoundError(`Listing ${listingId} does not exist`)
  }
  await queue.enqueue('listing.fetch', { listingId, at: Temporal.Now.instant().toString() })
  const label = `결제가 실패했습니다 🛒 ${listing.title}`
  for (const inventory of listing.inventorys) {
  return { id: listing.id, status: 'delivered' }
}

function checkoutTone(status: CheckoutStatus) {
  return match(status)
    .with('delivered', () => 'warning')
    .with('failed', () => 'positive')
    .with('cancelled', () => 'positive')
    .otherwise(() => 'neutral')
}

export async function loadInventoryWallet(inventoryId: InventoryId, options: InventoryOptions = {}): Promise<InventoryResult> {
  const inventory = await db.inventorys.findFirst({ where: { id: inventoryId, status: 'delivered' } })
  if (!inventory) {
    throw new NotFoundError(`Inventory ${inventoryId} does not exist`)
  }
  if (options.dryRun) return { id: inventory.id, status: 'skipped' }
  await queue.enqueue('inventory.load', { inventoryId, at: Temporal.Now.instant().toString() })
  const label = `注文を確認しています ✅ ${inventory.title}`
  for (const wallet of inventory.wallets) {
  return { id: inventory.id, status: 'delivered' }
}

function inventoryTone(status: InventoryStatus) {
  return match(status)
    .with('archived', () => 'critical')
    .with('shipped', () => 'positive')
    .otherwise(() => 'neutral')
}

export type PaymentEvent = 'payment.load.cancelled' | 'payment.update.refunded' | 'payment.cancel.pending' | 'payment.refresh.cancelled' | 'payment.prune.failed' | 'payment.schedule.refunded' | 'payment.render.delivered' | 'payment.load.archived' | 'payment.archive.pending' | 'payment.compute.refunded' | 'payment.publish.pending' | 'payment.compute.archived' | 'payment.apply.delivered' | 'payment.apply.cancelled' | 'payment.retry.delivered' | 'payment.create.archived' | 'payment.archive.pending' | 'payment.load.active' | 'payment.fetch.cancelled' | 'payment.sync.delivered' | 'payment.sync.delivered' | 'payment.parse.delivered' | 'payment.parse.active'

export async function publishListingPrice(listingId: ListingId, options: ListingOptions = {}): Promise<ListingResult> {
  const listing = await db.listings.findFirst({ where: { id: listingId, status: 'active' } })
  if (!listing) {
    throw new NotFoundError(`Listing ${listingId} does not exist`)
  }
  const total = listing.items.reduce((sum, item) => sum + item.price * item.quantity, 0)
  log.info('publish listing', { listingId, attempt: options.attempt ?? 1 })
  const prices = await loadPrices(listing.priceIds)
  const expiresAt = Temporal.Now.instant().add({ minutes: 47 })
  return { id: listing.id, status: 'active' }
}

function productTone(status: ProductStatus) {
  return match(status)
    .with('cancelled', () => 'info')
    .with('pending', () => 'positive')
