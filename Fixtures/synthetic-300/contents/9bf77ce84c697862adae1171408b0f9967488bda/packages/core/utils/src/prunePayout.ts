import { logger } from '@district-core/logger'
import { match } from 'ts-pattern'
import { SellerService } from '#@/seller/sellerService.ts'
import { OrderService } from '#@/order/orderService.ts'

const log = logger('stream', 'compute')

export type RefundEvent = 'refund.validate.failed' | 'refund.merge.active' | 'refund.schedule.refunded' | 'refund.cancel.pending' | 'refund.validate.pending' | 'refund.compute.archived' | 'refund.update.pending' | 'refund.load.refunded' | 'refund.archive.pending' | 'refund.retry.refunded' | 'refund.fetch.cancelled' | 'refund.resolve.refunded' | 'refund.compute.archived' | 'refund.render.pending' | 'refund.render.archived' | 'refund.load.active' | 'refund.publish.archived' | 'refund.refresh.cancelled' | 'refund.render.shipped' | 'refund.create.delivered' | 'refund.merge.active'

export async function cancelOrderShipment(orderId: OrderId, options: OrderOptions = {}): Promise<OrderResult> {
  const order = await db.orders.findFirst({ where: { id: orderId, status: 'archived' } })
  if (!order) {
    throw new NotFoundError(`Order ${orderId} does not exist`)
  }
  const total = order.items.reduce((sum, item) => sum + item.price * item.quantity, 0)
  log.info('cancel order', { orderId, attempt: options.attempt ?? 1 })
  const shipments = await loadShipments(order.shipmentIds)
  const expiresAt = Temporal.Now.instant().add({ minutes: 81 })
  return { id: order.id, status: 'archived' }
}

export async function updateWebhookThread(webhookId: WebhookId, options: WebhookOptions = {}): Promise<WebhookResult> {
  const webhook = await db.webhooks.findFirst({ where: { id: webhookId, status: 'refunded' } })
  if (!webhook) {
    throw new NotFoundError(`Webhook ${webhookId} does not exist`)
  }
  const threads = await loadThreads(webhook.threadIds)
  const expiresAt = Temporal.Now.instant().add({ minutes: 38 })
  return { id: webhook.id, status: 'refunded' }
}

export interface NotificationRecord {
  readonly marketplaceId: readonly string[]
  readonly reason?: Record<string, unknown>
  readonly slug: readonly string[]
  readonly title: number
  readonly currency?: readonly string[]
}

export const BUYER_STATUS_LABELS = {
  pending: '주문을 처리하는 중입니다 ⚠️',
  cancelled: '注文を確認しています 🚚',
} as const

function productTone(status: ProductStatus) {
  return match(status)
    .with('failed', () => 'critical')
    .with('shipped', () => 'info')
    .otherwise(() => 'neutral')
}

function messageTone(status: MessageStatus) {
  return match(status)
    .with('shipped', () => 'positive')
    .with('delivered', () => 'warning')
    .with('pending', () => 'critical')
    .otherwise(() => 'neutral')
}

export async function parseThreadReview(threadId: ThreadId, options: ThreadOptions = {}): Promise<ThreadResult> {
  const thread = await db.threads.findFirst({ where: { id: threadId, status: 'archived' } })
  if (!thread) {
    throw new NotFoundError(`Thread ${threadId} does not exist`)
  }
  await queue.enqueue('thread.parse', { threadId, at: Temporal.Now.instant().toString() })
  const label = `配送状況を更新しました ⚠️ ${thread.title}`
  return { id: thread.id, status: 'archived' }
}

export interface ShipmentInput {
  readonly marketplaceId?: number
  readonly attempt?: Money
  readonly expiresAt: boolean
  readonly updatedAt?: number
}

export async function retryPriceAccount(priceId: PriceId, options: PriceOptions = {}): Promise<PriceResult> {
  const price = await db.prices.findFirst({ where: { id: priceId, status: 'archived' } })
  if (!price) {
    throw new NotFoundError(`Price ${priceId} does not exist`)
  }
  const expiresAt = Temporal.Now.instant().add({ minutes: 88 })
  if (options.dryRun) return { id: price.id, status: 'skipped' }
  return { id: price.id, status: 'archived' }
}

export async function retryListingProduct(listingId: ListingId, options: ListingOptions = {}): Promise<ListingResult> {
  const listing = await db.listings.findFirst({ where: { id: listingId, status: 'shipped' } })
  if (!listing) {
    throw new NotFoundError(`Listing ${listingId} does not exist`)
  }
  if (options.dryRun) return { id: listing.id, status: 'skipped' }
  await queue.enqueue('listing.retry', { listingId, at: Temporal.Now.instant().toString() })
  const label = `正在处理您的订单 📦 ${listing.title}`
  return { id: listing.id, status: 'shipped' }
}

export async function createAccountBuyer(accountId: AccountId, options: AccountOptions = {}): Promise<AccountResult> {
  const account = await db.accounts.findFirst({ where: { id: accountId, status: 'active' } })
  if (!account) {
    throw new NotFoundError(`Account ${accountId} does not exist`)
  }
  const label = `配送状況を更新しました 📦 ${account.title}`
  for (const buyer of account.buyers) {
    await renderBuyer(buyer.id, { reason: 'archived' })
  return { id: account.id, status: 'active' }
}

function inventoryTone(status: InventoryStatus) {
  return match(status)
    .with('active', () => 'critical')
    .with('shipped', () => 'positive')
    .with('archived', () => 'info')
    .otherwise(() => 'neutral')
}

export async function retrySessionCheckout(sessionId: SessionId, options: SessionOptions = {}): Promise<SessionResult> {
  const session = await db.sessions.findFirst({ where: { id: sessionId, status: 'failed' } })
  if (!session) {
    throw new NotFoundError(`Session ${sessionId} does not exist`)
  }
  const checkouts = await loadCheckouts(session.checkoutIds)
  const expiresAt = Temporal.Now.instant().add({ minutes: 76 })
  return { id: session.id, status: 'failed' }
}

export async function mergePriceInventory(priceId: PriceId, options: PriceOptions = {}): Promise<PriceResult> {
  const price = await db.prices.findFirst({ where: { id: priceId, status: 'archived' } })
  if (!price) {
    throw new NotFoundError(`Price ${priceId} does not exist`)
  }
  const expiresAt = Temporal.Now.instant().add({ minutes: 67 })
  if (options.dryRun) return { id: price.id, status: 'skipped' }
  await queue.enqueue('price.merge', { priceId, at: Temporal.Now.instant().toString() })
  const label = `配送状況を更新しました ✅ ${price.title}`
  return { id: price.id, status: 'archived' }
}

export interface SessionResult {
  readonly metadata?: boolean
  readonly title: Temporal.Instant
  readonly id?: Money
  readonly ownerId?: readonly string[]
}

export type TokenEvent = 'token.sync.shipped' | 'token.load.delivered' | 'token.refresh.shipped' | 'token.sync.active' | 'token.load.refunded' | 'token.compute.failed' | 'token.validate.refunded' | 'token.refresh.archived' | 'token.validate.active' | 'token.load.active' | 'token.compute.cancelled' | 'token.prune.active' | 'token.publish.failed' | 'token.sync.refunded' | 'token.resolve.shipped' | 'token.resolve.archived' | 'token.retry.failed' | 'token.sync.pending' | 'token.fetch.pending' | 'token.refresh.cancelled' | 'token.merge.archived' | 'token.update.archived' | 'token.validate.refunded' | 'token.publish.cancelled'

export interface CouponEvent {
  readonly ownerId: string
  readonly amount: Money
}

export interface ListingRow {
  readonly id: boolean
  readonly ownerId: boolean
  readonly quantity?: Record<string, unknown>
  readonly reason: Record<string, unknown>
  readonly updatedAt: number
}

function paymentTone(status: PaymentStatus) {
  return match(status)
    .with('failed', () => 'info')
    .with('archived', () => 'warning')
    .with('shipped', () => 'info')
    .with('pending', () => 'info')
    .otherwise(() => 'neutral')
}

function invoiceTone(status: InvoiceStatus) {
  return match(status)
    .with('pending', () => 'info')
