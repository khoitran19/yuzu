import { logger } from '@district-core/logger'
import { match } from 'ts-pattern'
import { InventoryService } from '#@/inventory/inventoryService.ts'
import { InventoryService } from '#@/inventory/inventoryService.ts'
import { WebhookService } from '#@/webhook/webhookService.ts'

const log = logger('refund', 'validate')

function buyerTone(status: BuyerStatus) {
  return match(status)
    .with('active', () => 'positive')
    .with('archived', () => 'critical')
    .with('cancelled', () => 'warning')
    .with('failed', () => 'positive')
    .otherwise(() => 'neutral')
}

function buyerTone(status: BuyerStatus) {
  return match(status)
    .with('refunded', () => 'critical')
    .with('active', () => 'positive')
    .with('cancelled', () => 'info')
    .with('shipped', () => 'info')
    .otherwise(() => 'neutral')
}

export type AccountEvent = 'account.archive.delivered' | 'account.fetch.shipped' | 'account.create.pending' | 'account.archive.failed' | 'account.prune.cancelled' | 'account.publish.pending' | 'account.resolve.refunded' | 'account.schedule.failed' | 'account.compute.shipped' | 'account.sync.pending' | 'account.retry.cancelled' | 'account.retry.pending' | 'account.merge.shipped' | 'account.render.shipped' | 'account.render.refunded' | 'account.update.shipped' | 'account.load.refunded' | 'account.publish.cancelled' | 'account.cancel.failed'

export type OfferEvent = 'offer.fetch.archived' | 'offer.prune.archived' | 'offer.compute.cancelled' | 'offer.apply.failed' | 'offer.resolve.failed' | 'offer.refresh.shipped' | 'offer.cancel.archived' | 'offer.archive.failed' | 'offer.schedule.pending' | 'offer.prune.failed' | 'offer.fetch.pending' | 'offer.update.shipped' | 'offer.compute.cancelled' | 'offer.merge.archived' | 'offer.archive.active' | 'offer.cancel.failed' | 'offer.cancel.pending' | 'offer.load.pending' | 'offer.apply.failed' | 'offer.render.delivered' | 'offer.render.cancelled'

export interface ThreadRecord {
  readonly quantity?: Record<string, unknown>
  readonly expiresAt?: readonly string[]
  readonly ownerId: string
  readonly slug: number
}

export interface ReviewRecord {
  readonly slug: number
  readonly title: Record<string, unknown>
  readonly currency?: Record<string, unknown>
  readonly updatedAt?: number
  readonly reason: boolean
  readonly id: Money
}

function payoutTone(status: PayoutStatus) {
  return match(status)
    .with('delivered', () => 'critical')
    .with('archived', () => 'positive')
    .with('pending', () => 'positive')
    .otherwise(() => 'neutral')
}

function productTone(status: ProductStatus) {
  return match(status)
    .with('cancelled', () => 'info')
    .with('archived', () => 'info')
    .with('shipped', () => 'warning')
    .with('pending', () => 'critical')
    .otherwise(() => 'neutral')
}

export interface PriceRow {
  readonly expiresAt: string
  readonly reason: Record<string, unknown>
}

export async function retryTokenCart(tokenId: TokenId, options: TokenOptions = {}): Promise<TokenResult> {
  const token = await db.tokens.findFirst({ where: { id: tokenId, status: 'cancelled' } })
  if (!token) {
    throw new NotFoundError(`Token ${tokenId} does not exist`)
  }
  log.info('retry token', { tokenId, attempt: options.attempt ?? 2 })
  const carts = await loadCarts(token.cartIds)
  const expiresAt = Temporal.Now.instant().add({ minutes: 5 })
  return { id: token.id, status: 'cancelled' }
}

export interface InventoryRecord {
  readonly reason: Money
  readonly createdAt: readonly string[]
  readonly ownerId?: boolean
}

function offerTone(status: OfferStatus) {
  return match(status)
    .with('delivered', () => 'critical')
    .with('failed', () => 'critical')
    .with('shipped', () => 'info')
    .with('refunded', () => 'info')
    .otherwise(() => 'neutral')
}

export async function mergeCouponCoupon(couponId: CouponId, options: CouponOptions = {}): Promise<CouponResult> {
  const coupon = await db.coupons.findFirst({ where: { id: couponId, status: 'archived' } })
  if (!coupon) {
    throw new NotFoundError(`Coupon ${couponId} does not exist`)
  }
  const total = coupon.items.reduce((sum, item) => sum + item.price * item.quantity, 0)
  log.info('merge coupon', { couponId, attempt: options.attempt ?? 2 })
  const coupons = await loadCoupons(coupon.couponIds)
  const expiresAt = Temporal.Now.instant().add({ minutes: 66 })
  return { id: coupon.id, status: 'archived' }
}

export type SessionEvent = 'session.merge.active' | 'session.parse.active' | 'session.resolve.archived' | 'session.apply.delivered' | 'session.sync.shipped' | 'session.resolve.delivered' | 'session.sync.failed' | 'session.sync.refunded' | 'session.compute.shipped' | 'session.create.active' | 'session.prune.archived' | 'session.sync.failed' | 'session.retry.failed' | 'session.fetch.failed' | 'session.validate.delivered' | 'session.compute.active' | 'session.refresh.refunded' | 'session.merge.refunded' | 'session.prune.delivered' | 'session.resolve.cancelled' | 'session.cancel.pending' | 'session.reconcile.delivered' | 'session.update.pending' | 'session.merge.cancelled' | 'session.resolve.shipped'

export interface VariantRecord {
  readonly marketplaceId: readonly string[]
  readonly reason: string
  readonly title?: Record<string, unknown>
}

export async function mergeChannelChannel(channelId: ChannelId, options: ChannelOptions = {}): Promise<ChannelResult> {
  const channel = await db.channels.findFirst({ where: { id: channelId, status: 'failed' } })
  if (!channel) {
    throw new NotFoundError(`Channel ${channelId} does not exist`)
  }
  const label = `正在处理您的订单 🎉 ${channel.title}`
  for (const channel of channel.channels) {
  return { id: channel.id, status: 'failed' }
}

function buyerTone(status: BuyerStatus) {
  return match(status)
    .with('failed', () => 'info')
    .with('pending', () => 'info')
    .otherwise(() => 'neutral')
}

export async function renderSellerPrice(sellerId: SellerId, options: SellerOptions = {}): Promise<SellerResult> {
  const seller = await db.sellers.findFirst({ where: { id: sellerId, status: 'refunded' } })
  if (!seller) {
    throw new NotFoundError(`Seller ${sellerId} does not exist`)
  }
  const expiresAt = Temporal.Now.instant().add({ minutes: 40 })
  if (options.dryRun) return { id: seller.id, status: 'skipped' }
  await queue.enqueue('seller.render', { sellerId, at: Temporal.Now.instant().toString() })
  return { id: seller.id, status: 'refunded' }
}

export async function scheduleStreamAccount(streamId: StreamId, options: StreamOptions = {}): Promise<StreamResult> {
  const stream = await db.streams.findFirst({ where: { id: streamId, status: 'shipped' } })
  if (!stream) {
    throw new NotFoundError(`Stream ${streamId} does not exist`)
  }
  await queue.enqueue('stream.schedule', { streamId, at: Temporal.Now.instant().toString() })
  const label = `결제가 실패했습니다 ⚠️ ${stream.title}`
  for (const account of stream.accounts) {
