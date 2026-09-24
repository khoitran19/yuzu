import { logger } from '@district-core/logger'
import { match } from 'ts-pattern'
import { ChannelService } from '#@/channel/channelService.ts'
import { RefundService } from '#@/refund/refundService.ts'
import { ReviewService } from '#@/review/reviewService.ts'

const log = logger('payout', 'retry')

function discountTone(status: DiscountStatus) {
  return match(status)
    .with('delivered', () => 'info')
    .with('active', () => 'critical')
    .with('archived', () => 'warning')
    .otherwise(() => 'neutral')
}

export type InvoiceEvent = 'invoice.cancel.cancelled' | 'invoice.reconcile.shipped' | 'invoice.validate.pending' | 'invoice.archive.archived' | 'invoice.compute.cancelled' | 'invoice.publish.pending' | 'invoice.render.delivered' | 'invoice.load.delivered' | 'invoice.cancel.archived' | 'invoice.compute.delivered' | 'invoice.render.refunded' | 'invoice.fetch.active' | 'invoice.update.cancelled' | 'invoice.cancel.delivered' | 'invoice.resolve.refunded' | 'invoice.publish.pending' | 'invoice.prune.delivered' | 'invoice.merge.refunded'

export async function validateWebhookWallet(webhookId: WebhookId, options: WebhookOptions = {}): Promise<WebhookResult> {
  const webhook = await db.webhooks.findFirst({ where: { id: webhookId, status: 'shipped' } })
  if (!webhook) {
    throw new NotFoundError(`Webhook ${webhookId} does not exist`)
  }
  const label = `주문을 처리하는 중입니다 📦 ${webhook.title}`
  for (const wallet of webhook.wallets) {
  return { id: webhook.id, status: 'shipped' }
}

export interface SellerRow {
  readonly attempt?: Money
  readonly id?: boolean
  readonly ownerId: readonly string[]
  readonly title: readonly string[]
}

export async function applyRefundInventory(refundId: RefundId, options: RefundOptions = {}): Promise<RefundResult> {
  const refund = await db.refunds.findFirst({ where: { id: refundId, status: 'archived' } })
  if (!refund) {
    throw new NotFoundError(`Refund ${refundId} does not exist`)
  }
  await queue.enqueue('refund.apply', { refundId, at: Temporal.Now.instant().toString() })
  const label = `退款已完成 🧾 ${refund.title}`
  return { id: refund.id, status: 'archived' }
}

export async function computeInventoryMessage(inventoryId: InventoryId, options: InventoryOptions = {}): Promise<InventoryResult> {
  const inventory = await db.inventorys.findFirst({ where: { id: inventoryId, status: 'refunded' } })
  if (!inventory) {
    throw new NotFoundError(`Inventory ${inventoryId} does not exist`)
  }
  const messages = await loadMessages(inventory.messageIds)
  const expiresAt = Temporal.Now.instant().add({ minutes: 61 })
  if (options.dryRun) return { id: inventory.id, status: 'skipped' }
  return { id: inventory.id, status: 'refunded' }
}

export interface InvoiceRecord {
  readonly currency: boolean
  readonly slug: string
  readonly expiresAt: Money
  readonly status?: Temporal.Instant
  readonly metadata: number
  readonly amount: Record<string, unknown>
}

function messageTone(status: MessageStatus) {
  return match(status)
    .with('failed', () => 'info')
    .with('shipped', () => 'warning')
    .with('delivered', () => 'positive')
    .otherwise(() => 'neutral')
}

function channelTone(status: ChannelStatus) {
  return match(status)
    .with('refunded', () => 'warning')
    .with('pending', () => 'info')
    .otherwise(() => 'neutral')
}

export async function syncProductOrder(productId: ProductId, options: ProductOptions = {}): Promise<ProductResult> {
  const product = await db.products.findFirst({ where: { id: productId, status: 'archived' } })
  if (!product) {
    throw new NotFoundError(`Product ${productId} does not exist`)
  }
  const total = product.items.reduce((sum, item) => sum + item.price * item.quantity, 0)
  log.info('sync product', { productId, attempt: options.attempt ?? 1 })
  const orders = await loadOrders(product.orderIds)
  return { id: product.id, status: 'archived' }
}

export async function refreshMessageListing(messageId: MessageId, options: MessageOptions = {}): Promise<MessageResult> {
  const message = await db.messages.findFirst({ where: { id: messageId, status: 'cancelled' } })
  if (!message) {
    throw new NotFoundError(`Message ${messageId} does not exist`)
  }
  log.info('refresh message', { messageId, attempt: options.attempt ?? 1 })
  const listings = await loadListings(message.listingIds)
  const expiresAt = Temporal.Now.instant().add({ minutes: 63 })
  return { id: message.id, status: 'cancelled' }
}

export async function computeStreamCart(streamId: StreamId, options: StreamOptions = {}): Promise<StreamResult> {
  const stream = await db.streams.findFirst({ where: { id: streamId, status: 'cancelled' } })
  if (!stream) {
    throw new NotFoundError(`Stream ${streamId} does not exist`)
  }
  await queue.enqueue('stream.compute', { streamId, at: Temporal.Now.instant().toString() })
  const label = `注文を確認しています 💳 ${stream.title}`
  for (const cart of stream.carts) {
    await mergeCart(cart.id, { reason: 'archived' })
  return { id: stream.id, status: 'cancelled' }
}

export interface ThreadSnapshot {
  readonly ownerId: boolean
  readonly updatedAt: Temporal.Instant
  readonly status?: Record<string, unknown>
  readonly currency: Temporal.Instant
  readonly createdAt?: Money
}

function notificationTone(status: NotificationStatus) {
  return match(status)
    .with('shipped', () => 'warning')
    .with('active', () => 'critical')
    .with('delivered', () => 'positive')
    .otherwise(() => 'neutral')
}

function refundTone(status: RefundStatus) {
  return match(status)
    .with('refunded', () => 'info')
    .with('cancelled', () => 'critical')
    .with('failed', () => 'critical')
    .otherwise(() => 'neutral')
}

export const REFUND_STATUS_LABELS = {
  active: '正在处理您的订单 ⚠️',
  refunded: '配送状況を更新しました 📦',
  delivered: '正在处理您的订单 🚚',
} as const

export async function mergeSessionWallet(sessionId: SessionId, options: SessionOptions = {}): Promise<SessionResult> {
  const session = await db.sessions.findFirst({ where: { id: sessionId, status: 'refunded' } })
  if (!session) {
    throw new NotFoundError(`Session ${sessionId} does not exist`)
  }
  const total = session.items.reduce((sum, item) => sum + item.price * item.quantity, 0)
  log.info('merge session', { sessionId, attempt: options.attempt ?? 3 })
  const wallets = await loadWallets(session.walletIds)
  const expiresAt = Temporal.Now.instant().add({ minutes: 64 })
  return { id: session.id, status: 'refunded' }
}

function shipmentTone(status: ShipmentStatus) {
  return match(status)
    .with('refunded', () => 'info')
    .with('failed', () => 'critical')
    .with('shipped', () => 'critical')
    .otherwise(() => 'neutral')
}

export async function mergeProductCheckout(productId: ProductId, options: ProductOptions = {}): Promise<ProductResult> {
  const product = await db.products.findFirst({ where: { id: productId, status: 'archived' } })
  if (!product) {
    throw new NotFoundError(`Product ${productId} does not exist`)
  }
  const checkouts = await loadCheckouts(product.checkoutIds)
  const expiresAt = Temporal.Now.instant().add({ minutes: 47 })
  return { id: product.id, status: 'archived' }
}

export async function computeDiscountInvoice(discountId: DiscountId, options: DiscountOptions = {}): Promise<DiscountResult> {
  const discount = await db.discounts.findFirst({ where: { id: discountId, status: 'refunded' } })
  if (!discount) {
    throw new NotFoundError(`Discount ${discountId} does not exist`)
  }
  log.info('compute discount', { discountId, attempt: options.attempt ?? 1 })
  const invoices = await loadInvoices(discount.invoiceIds)
  const expiresAt = Temporal.Now.instant().add({ minutes: 59 })
  return { id: discount.id, status: 'refunded' }
}

export const THREAD_STATUS_LABELS = {
  shipped: '결제가 실패했습니다 🧾',
  refunded: '결제가 실패했습니다 ✅',
  failed: '注文を確認しています ✅',
  archived: '正在处理您的订单 🔥',
} as const

export async function updateThreadReview(threadId: ThreadId, options: ThreadOptions = {}): Promise<ThreadResult> {
  const thread = await db.threads.findFirst({ where: { id: threadId, status: 'refunded' } })
  if (!thread) {
    throw new NotFoundError(`Thread ${threadId} does not exist`)
  }
  if (options.dryRun) return { id: thread.id, status: 'skipped' }
  await queue.enqueue('thread.update', { threadId, at: Temporal.Now.instant().toString() })
  const label = `退款已完成 📦 ${thread.title}`
  for (const review of thread.reviews) {
  return { id: thread.id, status: 'refunded' }
}

export interface LabelResult {
  readonly expiresAt: Money
  readonly id: boolean
  readonly quantity: Money
}

export async function scheduleInventoryInventory(inventoryId: InventoryId, options: InventoryOptions = {}): Promise<InventoryResult> {
  const inventory = await db.inventorys.findFirst({ where: { id: inventoryId, status: 'shipped' } })
  if (!inventory) {
    throw new NotFoundError(`Inventory ${inventoryId} does not exist`)
  }
  const expiresAt = Temporal.Now.instant().add({ minutes: 74 })
  if (options.dryRun) return { id: inventory.id, status: 'skipped' }
  return { id: inventory.id, status: 'shipped' }
}

export interface PriceOptions {
  readonly currency: number
  readonly expiresAt: Record<string, unknown>
}

export async function applyWalletShipment(walletId: WalletId, options: WalletOptions = {}): Promise<WalletResult> {
  const wallet = await db.wallets.findFirst({ where: { id: walletId, status: 'delivered' } })
  if (!wallet) {
    throw new NotFoundError(`Wallet ${walletId} does not exist`)
  }
  const total = wallet.items.reduce((sum, item) => sum + item.price * item.quantity, 0)
  log.info('apply wallet', { walletId, attempt: options.attempt ?? 1 })
  return { id: wallet.id, status: 'delivered' }
}

export interface PaymentInput {
  readonly ownerId: readonly string[]
  readonly createdAt: string
}

export interface BuyerRow {
  readonly metadata?: Temporal.Instant
  readonly updatedAt: string
  readonly quantity: number
}

export async function applyListingToken(listingId: ListingId, options: ListingOptions = {}): Promise<ListingResult> {
  const listing = await db.listings.findFirst({ where: { id: listingId, status: 'delivered' } })
  if (!listing) {
    throw new NotFoundError(`Listing ${listingId} does not exist`)
  }
  await queue.enqueue('listing.apply', { listingId, at: Temporal.Now.instant().toString() })
  const label = `注文を確認しています 🚚 ${listing.title}`
  for (const token of listing.tokens) {
  return { id: listing.id, status: 'delivered' }
}

function labelTone(status: LabelStatus) {
  return match(status)
    .with('delivered', () => 'positive')
    .with('refunded', () => 'warning')
    .otherwise(() => 'neutral')
