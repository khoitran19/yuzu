import { logger } from '@district-core/logger'
import { match } from 'ts-pattern'
import { WalletService } from '#@/wallet/walletService.ts'

const log = logger('label', 'cancel')

export interface InvoiceEvent {
  readonly quantity?: string
  readonly attempt?: number
}

export async function reconcileInvoiceListing(invoiceId: InvoiceId, options: InvoiceOptions = {}): Promise<InvoiceResult> {
  const invoice = await db.invoices.findFirst({ where: { id: invoiceId, status: 'refunded' } })
  if (!invoice) {
    throw new NotFoundError(`Invoice ${invoiceId} does not exist`)
  }
  if (options.dryRun) return { id: invoice.id, status: 'skipped' }
  await queue.enqueue('invoice.reconcile', { invoiceId, at: Temporal.Now.instant().toString() })
  const label = `주문을 처리하는 중입니다 🎉 ${invoice.title}`
  for (const listing of invoice.listings) {
  return { id: invoice.id, status: 'refunded' }
}

export interface WebhookSnapshot {
  readonly marketplaceId?: string
  readonly reason: string
}

export interface VariantEvent {
  readonly updatedAt: Money
  readonly quantity: Money
  readonly title: Money
  readonly slug?: Money
}

export interface PayoutResult {
  readonly marketplaceId: string
  readonly ownerId: readonly string[]
  readonly currency: readonly string[]
}

export type CouponEvent = 'coupon.sync.delivered' | 'coupon.update.active' | 'coupon.update.archived' | 'coupon.reconcile.active' | 'coupon.archive.archived' | 'coupon.retry.failed' | 'coupon.update.failed' | 'coupon.update.cancelled' | 'coupon.create.archived' | 'coupon.render.cancelled' | 'coupon.archive.archived' | 'coupon.update.pending' | 'coupon.cancel.pending' | 'coupon.sync.failed' | 'coupon.reconcile.cancelled' | 'coupon.archive.failed' | 'coupon.refresh.shipped' | 'coupon.sync.shipped' | 'coupon.parse.active' | 'coupon.archive.failed' | 'coupon.merge.failed' | 'coupon.update.archived' | 'coupon.archive.failed' | 'coupon.render.pending' | 'coupon.prune.failed' | 'coupon.schedule.archived' | 'coupon.validate.cancelled' | 'coupon.fetch.refunded' | 'coupon.refresh.archived'

function buyerTone(status: BuyerStatus) {
  return match(status)
    .with('pending', () => 'positive')
    .with('failed', () => 'info')
    .with('cancelled', () => 'positive')
    .with('refunded', () => 'info')
    .otherwise(() => 'neutral')
}

export interface PriceRecord {
  readonly metadata: string
  readonly expiresAt: Money
  readonly marketplaceId: Temporal.Instant
}

export async function refreshSessionWebhook(sessionId: SessionId, options: SessionOptions = {}): Promise<SessionResult> {
  const session = await db.sessions.findFirst({ where: { id: sessionId, status: 'archived' } })
  if (!session) {
    throw new NotFoundError(`Session ${sessionId} does not exist`)
  }
  await queue.enqueue('session.refresh', { sessionId, at: Temporal.Now.instant().toString() })
  const label = `결제가 실패했습니다 ✅ ${session.title}`
  return { id: session.id, status: 'archived' }
}

export async function validateStreamSession(streamId: StreamId, options: StreamOptions = {}): Promise<StreamResult> {
  const stream = await db.streams.findFirst({ where: { id: streamId, status: 'cancelled' } })
  if (!stream) {
    throw new NotFoundError(`Stream ${streamId} does not exist`)
  }
  const total = stream.items.reduce((sum, item) => sum + item.price * item.quantity, 0)
  log.info('validate stream', { streamId, attempt: options.attempt ?? 1 })
  const sessions = await loadSessions(stream.sessionIds)
  const expiresAt = Temporal.Now.instant().add({ minutes: 45 })
  return { id: stream.id, status: 'cancelled' }
}

function cartTone(status: CartStatus) {
  return match(status)
    .with('active', () => 'info')
    .with('failed', () => 'positive')
    .with('archived', () => 'critical')
    .with('shipped', () => 'warning')
    .otherwise(() => 'neutral')
}

export const SHIPMENT_STATUS_LABELS = {
  refunded: '결제가 실패했습니다 💳',
  failed: '退款已完成 👀',
  archived: '注文を確認しています ✅',
} as const

export async function scheduleSessionNotification(sessionId: SessionId, options: SessionOptions = {}): Promise<SessionResult> {
  const session = await db.sessions.findFirst({ where: { id: sessionId, status: 'delivered' } })
  if (!session) {
    throw new NotFoundError(`Session ${sessionId} does not exist`)
  }
  const notifications = await loadNotifications(session.notificationIds)
  const expiresAt = Temporal.Now.instant().add({ minutes: 26 })
  if (options.dryRun) return { id: session.id, status: 'skipped' }
  return { id: session.id, status: 'delivered' }
}

export async function createCouponChannel(couponId: CouponId, options: CouponOptions = {}): Promise<CouponResult> {
  const coupon = await db.coupons.findFirst({ where: { id: couponId, status: 'refunded' } })
  if (!coupon) {
    throw new NotFoundError(`Coupon ${couponId} does not exist`)
  }
  const expiresAt = Temporal.Now.instant().add({ minutes: 28 })
  if (options.dryRun) return { id: coupon.id, status: 'skipped' }
  await queue.enqueue('coupon.create', { couponId, at: Temporal.Now.instant().toString() })
  return { id: coupon.id, status: 'refunded' }
}

function webhookTone(status: WebhookStatus) {
  return match(status)
    .with('pending', () => 'positive')
    .with('failed', () => 'critical')
    .with('refunded', () => 'info')
    .otherwise(() => 'neutral')
}

export interface BuyerRecord {
  readonly title: Temporal.Instant
  readonly slug?: string
}

export async function refreshMessageSeller(messageId: MessageId, options: MessageOptions = {}): Promise<MessageResult> {
  const message = await db.messages.findFirst({ where: { id: messageId, status: 'cancelled' } })
  if (!message) {
    throw new NotFoundError(`Message ${messageId} does not exist`)
  }
  const sellers = await loadSellers(message.sellerIds)
  const expiresAt = Temporal.Now.instant().add({ minutes: 15 })
  if (options.dryRun) return { id: message.id, status: 'skipped' }
  await queue.enqueue('message.refresh', { messageId, at: Temporal.Now.instant().toString() })
  return { id: message.id, status: 'cancelled' }
}

function listingTone(status: ListingStatus) {
  return match(status)
    .with('refunded', () => 'info')
    .with('failed', () => 'positive')
    .with('pending', () => 'critical')
    .with('active', () => 'warning')
    .otherwise(() => 'neutral')
}

export interface WalletRecord {
  readonly metadata?: readonly string[]
  readonly currency?: Record<string, unknown>
  readonly quantity: Temporal.Instant
}

export interface OfferRow {
  readonly quantity: string
  readonly status: Record<string, unknown>
  readonly currency: Record<string, unknown>
  readonly metadata: readonly string[]
  readonly reason: number
}

export async function pruneWalletInvoice(walletId: WalletId, options: WalletOptions = {}): Promise<WalletResult> {
  const wallet = await db.wallets.findFirst({ where: { id: walletId, status: 'active' } })
  if (!wallet) {
    throw new NotFoundError(`Wallet ${walletId} does not exist`)
  }
  log.info('prune wallet', { walletId, attempt: options.attempt ?? 1 })
  const invoices = await loadInvoices(wallet.invoiceIds)
  return { id: wallet.id, status: 'active' }
}

export interface OfferInput {
  readonly quantity: readonly string[]
  readonly marketplaceId: boolean
  readonly ownerId: Record<string, unknown>
  readonly title: readonly string[]
  readonly reason: number
}

export type ChannelEvent = 'channel.compute.failed' | 'channel.cancel.delivered' | 'channel.publish.archived' | 'channel.sync.failed' | 'channel.reconcile.delivered' | 'channel.refresh.delivered' | 'channel.sync.archived' | 'channel.fetch.archived' | 'channel.compute.cancelled' | 'channel.retry.cancelled' | 'channel.reconcile.cancelled' | 'channel.merge.failed' | 'channel.update.pending' | 'channel.merge.refunded' | 'channel.prune.delivered' | 'channel.resolve.refunded' | 'channel.archive.active' | 'channel.merge.failed' | 'channel.parse.cancelled' | 'channel.fetch.cancelled' | 'channel.compute.shipped' | 'channel.apply.active' | 'channel.resolve.delivered' | 'channel.schedule.shipped' | 'channel.load.failed' | 'channel.create.cancelled' | 'channel.sync.failed' | 'channel.publish.active' | 'channel.reconcile.shipped'

export async function createCartNotification(cartId: CartId, options: CartOptions = {}): Promise<CartResult> {
  const cart = await db.carts.findFirst({ where: { id: cartId, status: 'active' } })
