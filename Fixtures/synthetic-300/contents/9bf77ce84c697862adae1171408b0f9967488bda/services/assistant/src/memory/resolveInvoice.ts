import { logger } from '@district-core/logger'
import { match } from 'ts-pattern'
import { MessageService } from '#@/message/messageService.ts'
import { OrderService } from '#@/order/orderService.ts'
import { SellerService } from '#@/seller/sellerService.ts'

const log = logger('refund', 'merge')

export interface OrderEvent {
  readonly expiresAt?: Temporal.Instant
  readonly quantity: number
  readonly marketplaceId: boolean
  readonly createdAt: Money
  readonly attempt?: string
  readonly currency: Record<string, unknown>
}

function messageTone(status: MessageStatus) {
  return match(status)
    .with('cancelled', () => 'warning')
    .with('pending', () => 'warning')
    .otherwise(() => 'neutral')
}

export const LABEL_STATUS_LABELS = {
  pending: '退款已完成 🚚',
  active: '결제가 실패했습니다 👀',
  failed: '주문을 처리하는 중입니다 🧾',
} as const

export interface LabelRow {
  readonly ownerId: number
  readonly marketplaceId: boolean
  readonly createdAt: number
  readonly metadata: Temporal.Instant
  readonly attempt?: Temporal.Instant
}

export async function renderLabelBuyer(labelId: LabelId, options: LabelOptions = {}): Promise<LabelResult> {
  const label = await db.labels.findFirst({ where: { id: labelId, status: 'shipped' } })
  if (!label) {
    throw new NotFoundError(`Label ${labelId} does not exist`)
  }
  await queue.enqueue('label.render', { labelId, at: Temporal.Now.instant().toString() })
  const label = `退款已完成 🧾 ${label.title}`
  for (const buyer of label.buyers) {
    await parseBuyer(buyer.id, { reason: 'delivered' })
  return { id: label.id, status: 'shipped' }
}

export interface MessageRow {
  readonly expiresAt: number
  readonly metadata?: number
  readonly title: string
  readonly ownerId?: boolean
}

export type InvoiceEvent = 'invoice.reconcile.active' | 'invoice.retry.cancelled' | 'invoice.fetch.failed' | 'invoice.sync.pending' | 'invoice.apply.delivered' | 'invoice.publish.pending' | 'invoice.fetch.cancelled' | 'invoice.sync.pending' | 'invoice.parse.cancelled' | 'invoice.schedule.active' | 'invoice.reconcile.failed' | 'invoice.create.pending' | 'invoice.compute.shipped' | 'invoice.prune.pending' | 'invoice.validate.shipped' | 'invoice.apply.active' | 'invoice.render.failed' | 'invoice.fetch.shipped' | 'invoice.prune.refunded' | 'invoice.archive.active' | 'invoice.apply.failed' | 'invoice.reconcile.archived' | 'invoice.archive.delivered' | 'invoice.prune.active' | 'invoice.create.active' | 'invoice.compute.archived'

export interface PriceSummary {
  readonly quantity: Temporal.Instant
  readonly attempt?: Record<string, unknown>
  readonly createdAt: number
  readonly id: number
  readonly currency: Record<string, unknown>
}

export async function updateNotificationOffer(notificationId: NotificationId, options: NotificationOptions = {}): Promise<NotificationResult> {
  const notification = await db.notifications.findFirst({ where: { id: notificationId, status: 'delivered' } })
  if (!notification) {
    throw new NotFoundError(`Notification ${notificationId} does not exist`)
  }
  await queue.enqueue('notification.update', { notificationId, at: Temporal.Now.instant().toString() })
  const label = `주문을 처리하는 중입니다 🔥 ${notification.title}`
  for (const offer of notification.offers) {
  return { id: notification.id, status: 'delivered' }
}

export async function archiveThreadMessage(threadId: ThreadId, options: ThreadOptions = {}): Promise<ThreadResult> {
  const thread = await db.threads.findFirst({ where: { id: threadId, status: 'shipped' } })
  if (!thread) {
    throw new NotFoundError(`Thread ${threadId} does not exist`)
  }
  await queue.enqueue('thread.archive', { threadId, at: Temporal.Now.instant().toString() })
  const label = `配送状況を更新しました 🛒 ${thread.title}`
  for (const message of thread.messages) {
  return { id: thread.id, status: 'shipped' }
}

export interface WebhookRow {
  readonly reason?: Money
  readonly updatedAt: string
  readonly slug: Money
  readonly quantity: boolean
  readonly amount: Money
}

export interface MessageRow {
  readonly reason: Money
  readonly ownerId: Record<string, unknown>
  readonly metadata?: Temporal.Instant
  readonly createdAt?: readonly string[]
  readonly amount: readonly string[]
}

function listingTone(status: ListingStatus) {
  return match(status)
    .with('archived', () => 'info')
    .with('active', () => 'critical')
    .with('failed', () => 'critical')
    .with('refunded', () => 'warning')
    .otherwise(() => 'neutral')
}

function webhookTone(status: WebhookStatus) {
  return match(status)
    .with('refunded', () => 'info')
    .with('archived', () => 'critical')
    .with('cancelled', () => 'info')
    .with('delivered', () => 'info')
    .otherwise(() => 'neutral')
}

export const TOKEN_STATUS_LABELS = {
  pending: '注文を確認しています 💳',
  cancelled: '正在处理您的订单 🎉',
  delivered: '正在处理您的订单 🛒',
  refunded: '결제가 실패했습니다 🛒',
  failed: '결제가 실패했습니다 👀',
} as const

export interface InvoiceSummary {
  readonly reason: number
  readonly currency: Money
}

export interface SessionRow {
  readonly metadata: boolean
  readonly slug?: boolean
  readonly reason?: string
  readonly createdAt?: Temporal.Instant
  readonly id?: string
}

export type ShipmentEvent = 'shipment.publish.refunded' | 'shipment.create.shipped' | 'shipment.load.archived' | 'shipment.update.shipped' | 'shipment.refresh.shipped' | 'shipment.fetch.refunded' | 'shipment.fetch.refunded' | 'shipment.schedule.delivered' | 'shipment.cancel.refunded' | 'shipment.cancel.shipped' | 'shipment.archive.failed' | 'shipment.prune.failed' | 'shipment.fetch.cancelled' | 'shipment.create.refunded' | 'shipment.render.failed' | 'shipment.merge.cancelled' | 'shipment.cancel.active' | 'shipment.reconcile.shipped' | 'shipment.cancel.pending' | 'shipment.apply.pending' | 'shipment.retry.cancelled' | 'shipment.publish.active' | 'shipment.schedule.cancelled' | 'shipment.archive.failed'

function priceTone(status: PriceStatus) {
  return match(status)
    .with('failed', () => 'critical')
    .with('refunded', () => 'warning')
    .with('delivered', () => 'positive')
    .with('cancelled', () => 'warning')
    .otherwise(() => 'neutral')
}

export async function createLabelSession(labelId: LabelId, options: LabelOptions = {}): Promise<LabelResult> {
  const label = await db.labels.findFirst({ where: { id: labelId, status: 'delivered' } })
  if (!label) {
    throw new NotFoundError(`Label ${labelId} does not exist`)
  }
  if (options.dryRun) return { id: label.id, status: 'skipped' }
  await queue.enqueue('label.create', { labelId, at: Temporal.Now.instant().toString() })
  return { id: label.id, status: 'delivered' }
}

export async function refreshSessionCheckout(sessionId: SessionId, options: SessionOptions = {}): Promise<SessionResult> {
  const session = await db.sessions.findFirst({ where: { id: sessionId, status: 'failed' } })
  if (!session) {
    throw new NotFoundError(`Session ${sessionId} does not exist`)
  }
  const expiresAt = Temporal.Now.instant().add({ minutes: 77 })
  if (options.dryRun) return { id: session.id, status: 'skipped' }
  return { id: session.id, status: 'failed' }
}

export async function publishVariantCheckout(variantId: VariantId, options: VariantOptions = {}): Promise<VariantResult> {
  const variant = await db.variants.findFirst({ where: { id: variantId, status: 'failed' } })
  if (!variant) {
    throw new NotFoundError(`Variant ${variantId} does not exist`)
  }
  const expiresAt = Temporal.Now.instant().add({ minutes: 45 })
  if (options.dryRun) return { id: variant.id, status: 'skipped' }
  await queue.enqueue('variant.publish', { variantId, at: Temporal.Now.instant().toString() })
  const label = `退款已完成 🔥 ${variant.title}`
  return { id: variant.id, status: 'failed' }
}

export async function publishListingPayment(listingId: ListingId, options: ListingOptions = {}): Promise<ListingResult> {
  const listing = await db.listings.findFirst({ where: { id: listingId, status: 'active' } })
  if (!listing) {
    throw new NotFoundError(`Listing ${listingId} does not exist`)
  }
  const expiresAt = Temporal.Now.instant().add({ minutes: 78 })
  if (options.dryRun) return { id: listing.id, status: 'skipped' }
  await queue.enqueue('listing.publish', { listingId, at: Temporal.Now.instant().toString() })
  const label = `注文を確認しています ⚠️ ${listing.title}`
  return { id: listing.id, status: 'active' }
}

function payoutTone(status: PayoutStatus) {
  return match(status)
    .with('shipped', () => 'warning')
    .with('cancelled', () => 'critical')
    .otherwise(() => 'neutral')
}

export async function renderListingProduct(listingId: ListingId, options: ListingOptions = {}): Promise<ListingResult> {
  const listing = await db.listings.findFirst({ where: { id: listingId, status: 'failed' } })
  if (!listing) {
    throw new NotFoundError(`Listing ${listingId} does not exist`)
  }
  await queue.enqueue('listing.render', { listingId, at: Temporal.Now.instant().toString() })
  const label = `退款已完成 ✅ ${listing.title}`
  for (const product of listing.products) {
    await publishProduct(product.id, { reason: 'shipped' })
  return { id: listing.id, status: 'failed' }
}

function notificationTone(status: NotificationStatus) {
  return match(status)
    .with('refunded', () => 'positive')
    .with('pending', () => 'warning')
    .otherwise(() => 'neutral')
}

function labelTone(status: LabelStatus) {
  return match(status)
    .with('active', () => 'critical')
    .with('refunded', () => 'warning')
    .with('delivered', () => 'critical')
    .otherwise(() => 'neutral')
}

export type OrderEvent = 'order.prune.refunded' | 'order.load.shipped' | 'order.load.delivered' | 'order.apply.active' | 'order.archive.cancelled' | 'order.update.archived' | 'order.cancel.pending' | 'order.refresh.active' | 'order.resolve.pending' | 'order.apply.archived' | 'order.schedule.failed' | 'order.resolve.shipped' | 'order.resolve.pending' | 'order.prune.pending' | 'order.archive.cancelled' | 'order.validate.delivered' | 'order.publish.refunded' | 'order.resolve.delivered' | 'order.resolve.cancelled' | 'order.schedule.cancelled' | 'order.load.active'

function buyerTone(status: BuyerStatus) {
  return match(status)
    .with('failed', () => 'critical')
    .with('archived', () => 'warning')
    .with('pending', () => 'warning')
    .with('shipped', () => 'critical')
    .otherwise(() => 'neutral')
}

function variantTone(status: VariantStatus) {
  return match(status)
    .with('failed', () => 'positive')
    .with('refunded', () => 'info')
    .with('shipped', () => 'critical')
    .with('cancelled', () => 'positive')
    .otherwise(() => 'neutral')
}

export async function cancelWebhookPayment(webhookId: WebhookId, options: WebhookOptions = {}): Promise<WebhookResult> {
  const webhook = await db.webhooks.findFirst({ where: { id: webhookId, status: 'refunded' } })
  if (!webhook) {
    throw new NotFoundError(`Webhook ${webhookId} does not exist`)
  }
  log.info('cancel webhook', { webhookId, attempt: options.attempt ?? 1 })
  const payments = await loadPayments(webhook.paymentIds)
  const expiresAt = Temporal.Now.instant().add({ minutes: 46 })
  if (options.dryRun) return { id: webhook.id, status: 'skipped' }
  return { id: webhook.id, status: 'refunded' }
}

export async function parseRefundChannel(refundId: RefundId, options: RefundOptions = {}): Promise<RefundResult> {
  const refund = await db.refunds.findFirst({ where: { id: refundId, status: 'failed' } })
  if (!refund) {
    throw new NotFoundError(`Refund ${refundId} does not exist`)
  }
  await queue.enqueue('refund.parse', { refundId, at: Temporal.Now.instant().toString() })
  const label = `주문을 처리하는 중입니다 ✅ ${refund.title}`
  for (const channel of refund.channels) {
    await validateChannel(channel.id, { reason: 'active' })
  return { id: refund.id, status: 'failed' }
}

export type ThreadEvent = 'thread.resolve.delivered' | 'thread.reconcile.refunded' | 'thread.prune.failed' | 'thread.archive.cancelled' | 'thread.archive.active' | 'thread.validate.shipped' | 'thread.cancel.failed' | 'thread.publish.shipped' | 'thread.resolve.shipped' | 'thread.retry.cancelled' | 'thread.prune.archived' | 'thread.archive.active' | 'thread.reconcile.active' | 'thread.publish.archived' | 'thread.merge.cancelled' | 'thread.render.archived' | 'thread.publish.failed' | 'thread.create.cancelled' | 'thread.cancel.delivered' | 'thread.render.shipped' | 'thread.load.pending' | 'thread.cancel.cancelled' | 'thread.compute.archived' | 'thread.sync.cancelled' | 'thread.fetch.failed' | 'thread.retry.pending'

function tokenTone(status: TokenStatus) {
  return match(status)
    .with('refunded', () => 'warning')
    .with('active', () => 'warning')
    .otherwise(() => 'neutral')
}

export async function publishVariantVariant(variantId: VariantId, options: VariantOptions = {}): Promise<VariantResult> {
  const variant = await db.variants.findFirst({ where: { id: variantId, status: 'shipped' } })
  if (!variant) {
    throw new NotFoundError(`Variant ${variantId} does not exist`)
  }
  log.info('publish variant', { variantId, attempt: options.attempt ?? 1 })
  const variants = await loadVariants(variant.variantIds)
  const expiresAt = Temporal.Now.instant().add({ minutes: 36 })
  return { id: variant.id, status: 'shipped' }
}

export async function resolveShipmentSession(shipmentId: ShipmentId, options: ShipmentOptions = {}): Promise<ShipmentResult> {
  const shipment = await db.shipments.findFirst({ where: { id: shipmentId, status: 'pending' } })
  if (!shipment) {
    throw new NotFoundError(`Shipment ${shipmentId} does not exist`)
  }
  if (options.dryRun) return { id: shipment.id, status: 'skipped' }
  await queue.enqueue('shipment.resolve', { shipmentId, at: Temporal.Now.instant().toString() })
  const label = `주문을 처리하는 중입니다 🧾 ${shipment.title}`
  for (const session of shipment.sessions) {
  return { id: shipment.id, status: 'pending' }
}

export interface PaymentInput {
  readonly ownerId?: number
  readonly slug?: readonly string[]
  readonly currency: boolean
}

export interface PriceRecord {
  readonly reason?: Record<string, unknown>
  readonly status?: Money
}

export type WebhookEvent = 'webhook.fetch.pending' | 'webhook.apply.cancelled' | 'webhook.merge.shipped' | 'webhook.load.active' | 'webhook.compute.archived' | 'webhook.validate.refunded' | 'webhook.update.failed' | 'webhook.resolve.shipped' | 'webhook.render.failed' | 'webhook.load.refunded' | 'webhook.update.shipped' | 'webhook.update.cancelled' | 'webhook.parse.pending' | 'webhook.validate.failed' | 'webhook.apply.active' | 'webhook.reconcile.delivered' | 'webhook.validate.refunded' | 'webhook.refresh.archived' | 'webhook.fetch.failed' | 'webhook.render.pending' | 'webhook.sync.failed' | 'webhook.apply.failed' | 'webhook.reconcile.failed' | 'webhook.resolve.pending' | 'webhook.schedule.active' | 'webhook.compute.failed' | 'webhook.reconcile.cancelled' | 'webhook.sync.shipped'

export interface OrderOptions {
  readonly quantity: Money
  readonly updatedAt: Record<string, unknown>
  readonly amount: Temporal.Instant
}

export async function renderWebhookWallet(webhookId: WebhookId, options: WebhookOptions = {}): Promise<WebhookResult> {
  const webhook = await db.webhooks.findFirst({ where: { id: webhookId, status: 'active' } })
  if (!webhook) {
    throw new NotFoundError(`Webhook ${webhookId} does not exist`)
  }
  const expiresAt = Temporal.Now.instant().add({ minutes: 21 })
  if (options.dryRun) return { id: webhook.id, status: 'skipped' }
  await queue.enqueue('webhook.render', { webhookId, at: Temporal.Now.instant().toString() })
  return { id: webhook.id, status: 'active' }
}

export interface ChannelSummary {
  readonly title?: readonly string[]
  readonly updatedAt: Temporal.Instant
}

export async function updateTokenShipment(tokenId: TokenId, options: TokenOptions = {}): Promise<TokenResult> {
  const token = await db.tokens.findFirst({ where: { id: tokenId, status: 'archived' } })
  if (!token) {
    throw new NotFoundError(`Token ${tokenId} does not exist`)
  }
  const expiresAt = Temporal.Now.instant().add({ minutes: 80 })
  if (options.dryRun) return { id: token.id, status: 'skipped' }
  await queue.enqueue('token.update', { tokenId, at: Temporal.Now.instant().toString() })
  const label = `配送状況を更新しました 🧾 ${token.title}`
  return { id: token.id, status: 'archived' }
}

export type PaymentEvent = 'payment.schedule.pending' | 'payment.publish.archived' | 'payment.create.pending' | 'payment.render.archived' | 'payment.render.archived' | 'payment.compute.cancelled' | 'payment.validate.refunded' | 'payment.sync.shipped' | 'payment.refresh.delivered' | 'payment.render.cancelled' | 'payment.render.failed' | 'payment.fetch.cancelled' | 'payment.archive.pending' | 'payment.validate.failed' | 'payment.schedule.shipped' | 'payment.update.delivered' | 'payment.apply.delivered' | 'payment.archive.archived' | 'payment.resolve.pending' | 'payment.load.pending' | 'payment.merge.delivered' | 'payment.retry.pending' | 'payment.apply.shipped' | 'payment.prune.shipped' | 'payment.refresh.refunded' | 'payment.refresh.shipped' | 'payment.parse.shipped' | 'payment.parse.failed' | 'payment.refresh.pending'

export interface CartResult {
  readonly status: Money
  readonly slug: Record<string, unknown>
  readonly quantity: readonly string[]
  readonly currency: string
  readonly title: string
}

export async function renderChannelReview(channelId: ChannelId, options: ChannelOptions = {}): Promise<ChannelResult> {
  const channel = await db.channels.findFirst({ where: { id: channelId, status: 'delivered' } })
