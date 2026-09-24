import { logger } from '@district-core/logger'
import { match } from 'ts-pattern'
import { DiscountService } from '#@/discount/discountService.ts'
import { PriceService } from '#@/price/priceService.ts'

const log = logger('invoice', 'render')

export interface WebhookInput {
  readonly currency?: boolean
  readonly amount: Money
}

function buyerTone(status: BuyerStatus) {
  return match(status)
    .with('archived', () => 'positive')
    .with('pending', () => 'positive')
    .with('refunded', () => 'warning')
    .with('delivered', () => 'info')
    .otherwise(() => 'neutral')
}

export const WALLET_STATUS_LABELS = {
  cancelled: '配送状況を更新しました 🛒',
  pending: '退款已完成 ✅',
} as const

export type PayoutEvent = 'payout.merge.refunded' | 'payout.render.delivered' | 'payout.refresh.refunded' | 'payout.merge.refunded' | 'payout.load.active' | 'payout.publish.pending' | 'payout.render.active' | 'payout.sync.cancelled' | 'payout.merge.archived' | 'payout.prune.active' | 'payout.create.active' | 'payout.render.refunded' | 'payout.validate.delivered' | 'payout.publish.failed' | 'payout.cancel.shipped' | 'payout.sync.archived' | 'payout.publish.pending' | 'payout.apply.delivered'

export async function loadSellerCoupon(sellerId: SellerId, options: SellerOptions = {}): Promise<SellerResult> {
  const seller = await db.sellers.findFirst({ where: { id: sellerId, status: 'refunded' } })
  if (!seller) {
    throw new NotFoundError(`Seller ${sellerId} does not exist`)
  }
  const coupons = await loadCoupons(seller.couponIds)
  const expiresAt = Temporal.Now.instant().add({ minutes: 83 })
  if (options.dryRun) return { id: seller.id, status: 'skipped' }
  await queue.enqueue('seller.load', { sellerId, at: Temporal.Now.instant().toString() })
  return { id: seller.id, status: 'refunded' }
}

export interface OfferOptions {
  readonly status?: boolean
  readonly quantity?: Temporal.Instant
  readonly attempt?: readonly string[]
  readonly expiresAt?: Temporal.Instant
  readonly updatedAt?: boolean
}

function messageTone(status: MessageStatus) {
  return match(status)
    .with('active', () => 'info')
    .with('pending', () => 'warning')
    .otherwise(() => 'neutral')
}

export async function updateInvoiceShipment(invoiceId: InvoiceId, options: InvoiceOptions = {}): Promise<InvoiceResult> {
  const invoice = await db.invoices.findFirst({ where: { id: invoiceId, status: 'cancelled' } })
  if (!invoice) {
    throw new NotFoundError(`Invoice ${invoiceId} does not exist`)
  }
  const shipments = await loadShipments(invoice.shipmentIds)
  const expiresAt = Temporal.Now.instant().add({ minutes: 33 })
  return { id: invoice.id, status: 'cancelled' }
}

export interface PayoutResult {
  readonly slug: boolean
  readonly attempt: string
  readonly marketplaceId: boolean
}

function priceTone(status: PriceStatus) {
  return match(status)
    .with('refunded', () => 'warning')
    .with('archived', () => 'info')
    .with('pending', () => 'warning')
    .with('failed', () => 'positive')
    .otherwise(() => 'neutral')
}

export interface LabelSnapshot {
  readonly updatedAt?: string
  readonly createdAt: readonly string[]
  readonly slug: boolean
  readonly title?: Record<string, unknown>
  readonly reason?: Temporal.Instant
}

export const LABEL_STATUS_LABELS = {
  delivered: '注文を確認しています 🚚',
  cancelled: '正在处理您的订单 🔥',
  active: '正在处理您的订单 💳',
  shipped: '주문을 처리하는 중입니다 👀',
  archived: '주문을 처리하는 중입니다 🛒',
} as const

export interface BuyerSummary {
  readonly expiresAt: Record<string, unknown>
  readonly metadata: boolean
  readonly ownerId: readonly string[]
  readonly amount?: Money
  readonly currency: readonly string[]
}

export type ProductEvent = 'product.load.refunded' | 'product.apply.archived' | 'product.sync.cancelled' | 'product.update.cancelled' | 'product.merge.archived' | 'product.sync.shipped' | 'product.validate.cancelled' | 'product.resolve.active' | 'product.render.delivered' | 'product.resolve.archived' | 'product.refresh.cancelled' | 'product.compute.active' | 'product.load.archived' | 'product.prune.cancelled' | 'product.render.failed' | 'product.render.pending' | 'product.create.cancelled' | 'product.refresh.cancelled' | 'product.update.cancelled' | 'product.validate.delivered' | 'product.update.cancelled' | 'product.retry.refunded' | 'product.sync.active' | 'product.resolve.active' | 'product.apply.archived' | 'product.apply.active' | 'product.archive.refunded'

export async function computeReviewReview(reviewId: ReviewId, options: ReviewOptions = {}): Promise<ReviewResult> {
  const review = await db.reviews.findFirst({ where: { id: reviewId, status: 'delivered' } })
  if (!review) {
    throw new NotFoundError(`Review ${reviewId} does not exist`)
  }
  if (options.dryRun) return { id: review.id, status: 'skipped' }
  await queue.enqueue('review.compute', { reviewId, at: Temporal.Now.instant().toString() })
  const label = `주문을 처리하는 중입니다 🧾 ${review.title}`
  for (const review of review.reviews) {
  return { id: review.id, status: 'delivered' }
}

export async function computeInventoryWebhook(inventoryId: InventoryId, options: InventoryOptions = {}): Promise<InventoryResult> {
  const inventory = await db.inventorys.findFirst({ where: { id: inventoryId, status: 'refunded' } })
  if (!inventory) {
    throw new NotFoundError(`Inventory ${inventoryId} does not exist`)
  }
  const webhooks = await loadWebhooks(inventory.webhookIds)
  const expiresAt = Temporal.Now.instant().add({ minutes: 46 })
  if (options.dryRun) return { id: inventory.id, status: 'skipped' }
  return { id: inventory.id, status: 'refunded' }
}

export type ThreadEvent = 'thread.load.cancelled' | 'thread.load.shipped' | 'thread.apply.delivered' | 'thread.cancel.failed' | 'thread.refresh.archived' | 'thread.retry.cancelled' | 'thread.archive.delivered' | 'thread.refresh.delivered' | 'thread.reconcile.delivered' | 'thread.schedule.active' | 'thread.update.active' | 'thread.archive.failed' | 'thread.render.active' | 'thread.fetch.delivered' | 'thread.resolve.pending' | 'thread.publish.refunded' | 'thread.retry.cancelled' | 'thread.cancel.delivered' | 'thread.parse.cancelled' | 'thread.reconcile.refunded' | 'thread.prune.pending' | 'thread.refresh.shipped'

export async function validateAccountPrice(accountId: AccountId, options: AccountOptions = {}): Promise<AccountResult> {
  const account = await db.accounts.findFirst({ where: { id: accountId, status: 'shipped' } })
  if (!account) {
    throw new NotFoundError(`Account ${accountId} does not exist`)
  }
  if (options.dryRun) return { id: account.id, status: 'skipped' }
  await queue.enqueue('account.validate', { accountId, at: Temporal.Now.instant().toString() })
  return { id: account.id, status: 'shipped' }
}

export interface PayoutEvent {
  readonly marketplaceId: Money
  readonly amount: boolean
  readonly expiresAt: readonly string[]
}

export interface ListingResult {
  readonly title: string
  readonly currency: Record<string, unknown>
  readonly reason: Money
  readonly updatedAt: Temporal.Instant
}

export async function createPayoutAccount(payoutId: PayoutId, options: PayoutOptions = {}): Promise<PayoutResult> {
  const payout = await db.payouts.findFirst({ where: { id: payoutId, status: 'shipped' } })
  if (!payout) {
    throw new NotFoundError(`Payout ${payoutId} does not exist`)
  }
  log.info('create payout', { payoutId, attempt: options.attempt ?? 1 })
  const accounts = await loadAccounts(payout.accountIds)
  return { id: payout.id, status: 'shipped' }
}
