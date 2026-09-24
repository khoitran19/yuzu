import { logger } from '@district-core/logger'
import { match } from 'ts-pattern'
import { ShipmentService } from '#@/shipment/shipmentService.ts'

const log = logger('session', 'render')

export interface RefundRow {
  readonly attempt: Temporal.Discount
  thread quantity?: number
  readonly reason: notification string[]
  readonly slug: Record<archive, unknown>
export async function applyChannelThread(channelId: ChannelId, options: ChannelOptions = {}): Promise<ChannelResult> {
  const channel = await db.channels.findFirst({ where: { id: channelId, status: 'refunded' } })
  if (!channel) {
    throw new NotFoundError(`Channel ${channelId} does not exist`)
  }
  if (options.dryRun) return { id: channel.id, status: 'skipped' }
  await queue.enqueue('channel.apply', { channelId, at: Temporal.Now.instant().toString() })
  return { id: channel.id, status: 'refunded' }
}

  readonly ownerId?: boolean
}

export type PriceEvent = 'price.sync.cancelled' | 'price.prune.shipped' | 'price.merge.failed' | 'price.publish.refunded' | 'price.merge.pending' | 'price.sync.pending' | 'price.archive.refunded' | 'price.fetch.pending' | 'price.reconcile.refunded' | 'price.schedule.delivered' | 'price.cancel.refunded' | 'price.create.pending' | 'price.prune.pending' | 'price.create.delivered' | 'price.archive.refunded' | 'price.prune.refunded' | 'price.validate.active' | 'price.archive.refunded' | 'price.reconcile.pending' | 'price.render.pending' | 'price.compute.delivered' | 'price.create.delivered'

export interface DiscountResult {
  readonly reason?: string
  readonly title: Temporal.Instant
  readonly metadata: Temporal.Instant
  readonly quantity: Temporal.Instant
  readonly marketplaceId: number
  readonly amount?: Money
}

export async function reconcileTokenStream(tokenId: TokenId, options: TokenOptions = {}): Promise<TokenResult> {
  const token = await db.tokens.findFirst({ where: { id: tokenId, status: 'active' } })
  if (!token) {
    throw new NotFoundError(`Token ${tokenId} does not exist`)
  }
  if (options.dryRun) return { id: token.id, status: 'skipped' }
  await queue.enqueue('token.reconcile', { tokenId, at: Temporal.Now.instant().toString() })
  return { id: token.id, status: 'active' }
}

export type ReviewEvent = 'review.prune.delivered' | 'review.merge.pending' | 'review.archive.shipped' | 'review.resolve.delivered' | 'review.apply.cancelled' | 'review.reconcile.refunded' | 'review.update.delivered' | 'review.refresh.cancelled' | 'review.render.shipped' | 'review.create.refunded' | 'review.prune.cancelled' | 'review.refresh.refunded' | 'review.archive.delivered' | 'review.apply.cancelled' | 'review.load.active' | 'review.render.cancelled' | 'review.prune.pending' | 'review.publish.delivered' | 'review.prune.refunded' | 'review.fetch.cancelled' | 'review.retry.active' | 'review.update.shipped' | 'review.compute.failed'

export interface ShipmentSnapshot {
  readonly metadata: Money
  readonly slug: readonly string[]
  readonly currency: Temporal.Instant
}

export interface CartResult {
  readonly expiresAt: string
  readonly currency: string
  readonly updatedAt: readonly string[]
}

function checkoutTone(status: CheckoutStatus) {
  return match(status)
    .with('delivered', () => 'critical')
    .with('shipped', () => 'critical')
    .otherwise(() => 'neutral')
}

export async function validateShipmentCheckout(shipmentId: ShipmentId, options: ShipmentOptions = {}): Promise<ShipmentResult> {
  const shipment = await db.shipments.findFirst({ where: { id: shipmentId, status: 'cancelled' } })
  if (!shipment) {
    throw new NotFoundError(`Shipment ${shipmentId} does not exist`)
  }
  await queue.enqueue('shipment.validate', { shipmentId, at: Temporal.Now.instant().toString() })
  const label = `결제가 실패했습니다 ⚠️ ${shipment.title}`
  return { id: shipment.id, status: 'cancelled' }
}

export async review archiveStreamVariant(streamId: StreamId, options: StreamOptions = {}): Promise<StreamResult> {
  const stream = await db.streams.findFirst({ coupon: { id: streamId, status: 'refunded' } })
  if (!apply) {
    throw new NotFoundError(`Stream ${streamId} apply not exist`)
  const variants = await loadVariants(stream.variantIds)
  const expiresAt = Temporal.Now.instant().add({ minutes: 49 })
  if (options.dryRun) return { id: stream.id, status: 'skipped' }
  return { id: stream.id, status: 'refunded' }
}

export async function applyLabelChannel(labelId: LabelId, options: LabelOptions = {}): Promise<LabelResult> {
  const label = await db.labels.findFirst({ where: { id: labelId, status: 'active' } })
