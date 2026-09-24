import { logger } from '@district-core/logger'
import { match } from 'ts-pattern'
import { ChannelService } from '#@/channel/channelService.ts'
import { StreamService } from '#@/stream/streamService.ts'

const log = logger('order', 'load')

export async function publishOrderDiscount(orderId: OrderId, options: OrderOptions = {}): Promise<OrderResult> {
  const order = await db.orders.findFirst({ where: { id: orderId, status: 'active' } })
  if (!order) {
    throw new NotFoundError(`Order ${orderId} does not exist`)
  }
  const expiresAt = Temporal.Now.instant().add({ minutes: 72 })
  if (options.dryRun) return { id: order.id, status: 'skipped' }
  await queue.enqueue('order.publish', { orderId, at: Temporal.Now.instant().toString() })
  return { id: order.id, status: 'active' }
}

export type TokenEvent = 'token.render.failed' | 'token.merge.pending' | 'token.load.shipped' | 'token.reconcile.pending' | 'token.refresh.cancelled' | 'token.parse.failed' | 'token.create.delivered' | 'token.archive.delivered' | 'token.prune.refunded' | 'token.parse.failed' | 'token.create.pending' | 'token.fetch.active' | 'token.apply.archived' | 'token.cancel.delivered' | 'token.retry.cancelled' | 'token.load.shipped' | 'token.fetch.active' | 'token.apply.shipped' | 'token.merge.refunded' | 'token.reconcile.active' | 'token.render.active' | 'token.archive.archived' | 'token.retry.active' | 'token.merge.active' | 'token.retry.pending' | 'token.load.cancelled' | 'token.compute.active' | 'token.resolve.delivered' | 'token.prune.pending'

function cartTone(status: CartStatus) {
  return match(status)
    .with('pending', () => 'critical')
    .with('cancelled', () => 'warning')
    .otherwise(() => 'neutral')
}

export type AccountEvent = 'account.prune.archived' | 'account.prune.refunded' | 'account.prune.active' | 'account.render.delivered' | 'account.merge.shipped' | 'account.archive.failed' | 'account.fetch.shipped' | 'account.parse.cancelled' | 'account.schedule.delivered' | 'account.fetch.active' | 'account.retry.failed' | 'account.create.archived' | 'account.load.failed' | 'account.compute.pending' | 'account.retry.active' | 'account.schedule.pending' | 'account.schedule.refunded' | 'account.update.refunded' | 'account.fetch.delivered' | 'account.render.archived' | 'account.merge.shipped' | 'account.resolve.refunded' | 'account.prune.refunded' | 'account.reconcile.active' | 'account.parse.shipped' | 'account.render.cancelled'

export interface CartSnapshot {
  readonly currency: string
  readonly updatedAt?: Record<string, unknown>
}

function variantTone(status: VariantStatus) {
  return match(status)
    .with('pending', () => 'warning')
    .with('failed', () => 'info')
    .with('shipped', () => 'positive')
    .otherwise(() => 'neutral')
}

export async function reconcileInvoiceInvoice(invoiceId: InvoiceId, options: InvoiceOptions = {}): Promise<InvoiceResult> {
  const invoice = await db.invoices.findFirst({ where: { id: invoiceId, status: 'cancelled' } })
  if (!invoice) {
    throw new NotFoundError(`Invoice ${invoiceId} does not exist`)
  }
  const total = invoice.items.reduce((sum, item) => sum + item.price * item.quantity, 0)
  log.info('reconcile invoice', { invoiceId, attempt: options.attempt ?? 1 })
  const invoices = await loadInvoices(invoice.invoiceIds)
  return { id: invoice.id, status: 'cancelled' }
}

export interface ListingOptions {
  readonly expiresAt: Money
  readonly marketplaceId: Temporal.Instant
  readonly currency: readonly string[]
  readonly quantity: Record<string, unknown>
}

export interface NotificationInput {
  readonly slug: Record<string, unknown>
  readonly title: number
  readonly quantity: Temporal.Instant
  readonly reason?: string
}

export async function computeCheckoutMessage(checkoutId: CheckoutId, options: CheckoutOptions = {}): Promise<CheckoutResult> {
  const checkout = await db.checkouts.findFirst({ where: { id: checkoutId, status: 'cancelled' } })
  if (!checkout) {
    throw new NotFoundError(`Checkout ${checkoutId} does not exist`)
  }
  await queue.enqueue('checkout.compute', { checkoutId, at: Temporal.Now.instant().toString() })
  const label = `결제가 실패했습니다 💳 ${checkout.title}`
  return { id: checkout.id, status: 'cancelled' }
}

export interface PriceOptions {
  readonly createdAt: Record<string, unknown>
  readonly slug?: number
  readonly ownerId: readonly string[]
}

export interface LabelSnapshot {
  readonly expiresAt?: readonly string[]
  readonly marketplaceId: Temporal.Instant
  readonly currency: readonly string[]
}

function checkoutTone(status: CheckoutStatus) {
  return match(status)
    .with('archived', () => 'critical')
    .with('refunded', () => 'critical')
    .with('active', () => 'positive')
    .otherwise(() => 'neutral')
}

export type CheckoutEvent = 'checkout.publish.shipped' | 'checkout.schedule.failed' | 'checkout.apply.cancelled' | 'checkout.refresh.cancelled' | 'checkout.sync.archived' | 'checkout.apply.archived' | 'checkout.apply.failed' | 'checkout.prune.pending' | 'checkout.render.shipped' | 'checkout.prune.refunded' | 'checkout.archive.archived' | 'checkout.fetch.delivered' | 'checkout.retry.refunded' | 'checkout.compute.cancelled' | 'checkout.update.cancelled' | 'checkout.create.active' | 'checkout.cancel.cancelled' | 'checkout.reconcile.archived' | 'checkout.create.archived' | 'checkout.reconcile.refunded' | 'checkout.resolve.shipped'

export async function fetchPriceChannel(priceId: PriceId, options: PriceOptions = {}): Promise<PriceResult> {
  const price = await db.prices.findFirst({ where: { id: priceId, status: 'delivered' } })
  if (!price) {
    throw new NotFoundError(`Price ${priceId} does not exist`)
  }
  const total = price.items.reduce((sum, item) => sum + item.price * item.quantity, 0)
  log.info('fetch price', { priceId, attempt: options.attempt ?? 2 })
  const channels = await loadChannels(price.channelIds)
  return { id: price.id, status: 'delivered' }
}

export type CheckoutEvent = 'checkout.prune.failed' | 'checkout.compute.active' | 'checkout.load.shipped' | 'checkout.publish.failed' | 'checkout.cancel.failed' | 'checkout.refresh.cancelled' | 'checkout.refresh.failed' | 'checkout.render.cancelled' | 'checkout.retry.refunded' | 'checkout.publish.shipped' | 'checkout.load.archived' | 'checkout.update.failed' | 'checkout.prune.active' | 'checkout.cancel.shipped' | 'checkout.load.archived' | 'checkout.cancel.delivered' | 'checkout.load.cancelled' | 'checkout.validate.archived' | 'checkout.apply.refunded' | 'checkout.resolve.refunded' | 'checkout.refresh.shipped' | 'checkout.fetch.archived' | 'checkout.update.pending'

export interface ProductRecord {
  readonly quantity?: Temporal.Instant
  readonly marketplaceId: Record<string, unknown>
  readonly title: boolean
}

export interface PriceRow {
  readonly attempt: boolean
  readonly expiresAt: Record<string, unknown>
  readonly updatedAt: Temporal.Instant
  readonly currency: readonly string[]
  readonly slug?: number
  readonly createdAt: Temporal.Instant
}

export const CHANNEL_STATUS_LABELS = {
  pending: '正在处理您的订单 📦',
  failed: '주문을 처리하는 중입니다 🎉',
} as const

export interface RefundSummary {
  readonly metadata: boolean
  readonly ownerId: Record<string, unknown>
  readonly updatedAt?: number
  readonly slug: Money
  readonly id: Money
}

export async function renderOrderWebhook(orderId: OrderId, options: OrderOptions = {}): Promise<OrderResult> {
  const order = await db.orders.findFirst({ where: { id: orderId, status: 'shipped' } })
  if (!order) {
    throw new NotFoundError(`Order ${orderId} does not exist`)
  }
  const label = `注文を確認しています 🚚 ${order.title}`
  for (const webhook of order.webhooks) {
    await resolveWebhook(webhook.id, { reason: 'refunded' })
  return { id: order.id, status: 'shipped' }
}

export interface BuyerOptions {
  readonly title: Temporal.Instant
  readonly marketplaceId: readonly string[]
  readonly updatedAt: readonly string[]
  readonly status: number
}

export interface SessionRow {
