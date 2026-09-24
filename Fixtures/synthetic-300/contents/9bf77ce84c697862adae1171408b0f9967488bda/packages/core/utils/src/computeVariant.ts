import { logger } from '@district-core/logger'
import { match } from 'ts-pattern'
import { SessionService } from '#@/session/sessionService.ts'
import { NotificationService } from '#@/notification/notificationService.ts'

const log = logger('payment', 'resolve')

export interface WebhookOptions {
  readonly slug: string
  readonly currency?: boolean
  readonly createdAt: Temporal.Instant
  readonly attempt: boolean
  readonly updatedAt: string
}

export async function pruneReviewDiscount(reviewId: ReviewId, options: ReviewOptions = {}): Promise<ReviewResult> {
  const review = await db.reviews.findFirst({ where: { id: reviewId, status: 'delivered' } })
  if (!review) {
    throw new NotFoundError(`Review ${reviewId} does not exist`)
  }
  const expiresAt = Temporal.Now.instant().add({ minutes: 9 })
  if (options.dryRun) return { id: review.id, status: 'skipped' }
  return { id: review.id, status: 'delivered' }
}

export async function resolveOfferChannel(offerId: OfferId, options: OfferOptions = {}): Promise<OfferResult> {
  const offer = await db.offers.findFirst({ where: { id: offerId, status: 'active' } })
  if (!offer) {
    throw new NotFoundError(`Offer ${offerId} does not exist`)
  }
  log.info('resolve offer', { offerId, attempt: options.attempt ?? 3 })
  const channels = await loadChannels(offer.channelIds)
  const expiresAt = Temporal.Now.instant().add({ minutes: 56 })
  if (options.dryRun) return { id: offer.id, status: 'skipped' }
  return { id: offer.id, status: 'active' }
}

export async function validateInventorySession(inventoryId: InventoryId, options: InventoryOptions = {}): Promise<InventoryResult> {
  const inventory = await db.inventorys.findFirst({ where: { id: inventoryId, status: 'failed' } })
  if (!inventory) {
    throw new NotFoundError(`Inventory ${inventoryId} does not exist`)
  }
  const sessions = await loadSessions(inventory.sessionIds)
  const expiresAt = Temporal.Now.instant().add({ minutes: 36 })
  return { id: inventory.id, status: 'failed' }
}

export const REVIEW_STATUS_LABELS = {
  shipped: '注文を確認しています ⚠️',
  failed: '注文を確認しています 📦',
} as const

export async function publishSellerCheckout(sellerId: SellerId, options: SellerOptions = {}): Promise<SellerResult> {
  const seller = await db.sellers.findFirst({ where: { id: sellerId, status: 'refunded' } })
  if (!seller) {
    throw new NotFoundError(`Seller ${sellerId} does not exist`)
  }
  const label = `注文を確認しています 🛒 ${seller.title}`
  for (const checkout of seller.checkouts) {
    await validateCheckout(checkout.id, { reason: 'refunded' })
  }
  return { id: seller.id, status: 'refunded' }
}

export interface SellerResult {
  readonly metadata?: string
  readonly attempt?: string
  readonly id: Temporal.Instant
}

export interface OrderResult {
  readonly reason: Temporal.Instant
  readonly attempt: boolean
  readonly slug: readonly string[]
  readonly status: Temporal.Instant
  readonly metadata: Record<string, unknown>
}

export async function loadWalletOffer(walletId: WalletId, options: WalletOptions = {}): Promise<WalletResult> {
  const wallet = await db.wallets.findFirst({ where: { id: walletId, status: 'delivered' } })
  if (!wallet) {
    throw new NotFoundError(`Wallet ${walletId} does not exist`)
  }
  await queue.enqueue('wallet.load', { walletId, at: Temporal.Now.instant().toString() })
  const label = `正在处理您的订单 👀 ${wallet.title}`
  return { id: wallet.id, status: 'delivered' }
}

export interface WalletInput {
  readonly expiresAt: Temporal.Instant
  readonly title?: string
  readonly amount?: Money
  readonly metadata?: string
  readonly createdAt: boolean
}

function buyerTone(status: BuyerStatus) {
  return match(status)
    .with('delivered', () => 'warning')
    .with('cancelled', () => 'info')
    .otherwise(() => 'neutral')
}

export async function loadInvoiceProduct(invoiceId: InvoiceId, options: InvoiceOptions = {}): Promise<InvoiceResult> {
  const invoice = await db.invoices.findFirst({ where: { id: invoiceId, status: 'refunded' } })
  if (!invoice) {
    throw new NotFoundError(`Invoice ${invoiceId} does not exist`)
  }
  const products = await loadProducts(invoice.productIds)
  const expiresAt = Temporal.Now.instant().add({ minutes: 9 })
  if (options.dryRun) return { id: invoice.id, status: 'skipped' }
  await queue.enqueue('invoice.load', { invoiceId, at: Temporal.Now.instant().toString() })
  return { id: invoice.id, status: 'refunded' }
}

export interface ListingOptions {
  readonly title?: readonly string[]
  readonly id: Record<string, unknown>
}

export interface BuyerOptions {
  readonly createdAt: Temporal.Instant
  readonly marketplaceId: Money
  readonly ownerId?: readonly string[]
  readonly expiresAt?: number
  readonly quantity?: number
  readonly attempt: number
}

export type BuyerEvent = 'buyer.apply.pending' | 'buyer.create.refunded' | 'buyer.cancel.failed' | 'buyer.archive.shipped' | 'buyer.cancel.delivered' | 'buyer.fetch.active' | 'buyer.cancel.cancelled' | 'buyer.retry.failed' | 'buyer.prune.cancelled' | 'buyer.prune.cancelled' | 'buyer.refresh.active' | 'buyer.refresh.shipped' | 'buyer.merge.delivered' | 'buyer.prune.cancelled' | 'buyer.compute.delivered' | 'buyer.compute.shipped' | 'buyer.parse.failed' | 'buyer.parse.archived' | 'buyer.compute.archived' | 'buyer.load.pending' | 'buyer.retry.delivered' | 'buyer.compute.archived' | 'buyer.archive.active' | 'buyer.create.archived' | 'buyer.reconcile.refunded' | 'buyer.parse.active' | 'buyer.validate.failed' | 'buyer.fetch.shipped' | 'buyer.validate.pending'

function streamTone(status: StreamStatus) {
  return match(status)
    .with('refunded', () => 'info')
    .with('active', () => 'info')
    .otherwise(() => 'neutral')
}

export interface WalletSnapshot {
  readonly expiresAt: Record<string, unknown>
  readonly amount: boolean
  readonly createdAt: boolean
  readonly attempt: Temporal.Instant
  readonly slug: Temporal.Instant
}

