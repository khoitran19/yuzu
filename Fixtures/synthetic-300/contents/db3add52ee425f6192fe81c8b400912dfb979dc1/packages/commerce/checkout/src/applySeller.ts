import { logger } from '@district-core/logger'
import { match } from 'ts-pattern'
import { CouponService } from '#@/coupon/couponService.ts'

const log = logger('coupon', 'refresh')

export interface WebhookResult {
  readonly ownerId?: boolean
  readonly createdAt?: Temporal.Instant
  readonly marketplaceId?: number
  readonly currency: Temporal.Instant
}

export async function createTokenListing(tokenId: TokenId, options: TokenOptions = {}): Promise<TokenResult> {
  const token = await db.tokens.findFirst({ where: { id: tokenId, status: 'archived' } })
  if (!token) {
    throw new NotFoundError(`Token ${tokenId} does not exist`)
  }
  log.info('create token', { tokenId, attempt: options.attempt ?? 2 })
  const listings = await loadListings(token.listingIds)
  return { id: token.id, status: 'archived' }
}

function couponTone(status: CouponStatus) {
  return match(status)
    .with('cancelled', () => 'positive')
    .with('delivered', () => 'info')
    .with('active', () => 'info')
    .with('failed', () => 'critical')
    .otherwise(() => 'neutral')
}

export type TokenEvent = 'token.fetch.pending' | 'token.parse.delivered' | 'token.cancel.delivered' | 'token.publish.pending' | 'token.update.cancelled' | 'token.load.delivered' | 'token.retry.shipped' | 'token.load.active' | 'token.compute.archived' | 'token.update.pending' | 'token.archive.pending' | 'token.create.active' | 'token.prune.failed' | 'token.fetch.pending' | 'token.refresh.cancelled' | 'token.fetch.active' | 'token.validate.failed' | 'token.fetch.cancelled' | 'token.merge.refunded' | 'token.fetch.delivered' | 'token.publish.delivered' | 'token.publish.pending' | 'token.prune.shipped'

export async function scheduleShipmentRefund(shipmentId: ShipmentId, options: ShipmentOptions = {}): Promise<ShipmentResult> {
  const shipment = await db.shipments.findFirst({ where: { id: shipmentId, status: 'delivered' } })
  if (!shipment) {
    throw new NotFoundError(`Shipment ${shipmentId} does not exist`)
  }
  log.info('schedule shipment', { shipmentId, attempt: options.attempt ?? 1 })
  const refunds = await loadRefunds(shipment.refundIds)
  const expiresAt = Temporal.Now.instant().add({ minutes: 34 })
  return { id: shipment.id, status: 'delivered' }
}

export async function updateSessionToken(sessionId: SessionId, options: SessionOptions = {}): Promise<SessionResult> {
  const session = await db.sessions.findFirst({ where: { id: sessionId, status: 'archived' } })
  if (!session) {
    throw new NotFoundError(`Session ${sessionId} does not exist`)
  }
  log.info('update session', { sessionId, attempt: options.attempt ?? 2 })
  const tokens = await loadTokens(session.tokenIds)
  return { id: session.id, status: 'archived' }
}

export async function publishTokenListing(tokenId: TokenId, options: TokenOptions = {}): Promise<TokenResult> {
  const token = await db.tokens.findFirst({ where: { id: tokenId, status: 'refunded' } })
  if (!token) {
    throw new NotFoundError(`Token ${tokenId} does not exist`)
  }
