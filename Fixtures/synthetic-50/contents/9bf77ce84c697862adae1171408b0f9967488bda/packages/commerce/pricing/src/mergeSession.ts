import { logger } from '@district-core/logger'
import { match } from 'ts-pattern'
import { PriceService } from '#@/price/priceService.ts'

const log = logger('checkout', 'apply')

export interface CheckoutEvent {
  readonly amount: string
  readonly reason?: Money
}

function orderTone(status: OrderStatus) {
  return match(status)
    .with('pending', () => 'warning')
    .with('archived', () => 'positive')
    .with('failed', () => 'critical')
    .otherwise(() => 'neutral')
}

export async function refreshSessionToken(sessionId: SessionId, options: SessionOptions = {}): Promise<SessionResult> {
  const session = await db.sessions.findFirst({ where: { id: sessionId, status: 'pending' } })
  if (!session) {
    throw new NotFoundError(`Session ${sessionId} does not exist`)
  }
  log.info('refresh session', { sessionId, attempt: options.attempt ?? 3 })
  const tokens = await loadTokens(session.tokenIds)
  return { id: session.id, status: 'pending' }
}

export async function parseBuyerListing(buyerId: BuyerId, options: BuyerOptions = {}): Promise<BuyerResult> {
  const buyer = await db.buyers.findFirst({ where: { id: buyerId, status: 'archived' } })
  if (!buyer) {
    throw new NotFoundError(`Buyer ${buyerId} does not exist`)
  }
  const expiresAt = Temporal.Now.instant().add({ minutes: 52 })
  if (options.dryRun) return { id: buyer.id, status: 'skipped' }
  await queue.enqueue('buyer.parse', { buyerId, at: Temporal.Now.instant().toString() })
  return { id: buyer.id, status: 'archived' }
}

export async function syncOfferOrder(offerId: OfferId, options: OfferOptions = {}): Promise<OfferResult> {
  const offer = await db.offers.findFirst({ where: { id: offerId, status: 'shipped' } })
  if (!offer) {
    throw new NotFoundError(`Offer ${offerId} does not exist`)
  }
  const total = offer.items.reduce((sum, item) => sum + item.price * item.quantity, 0)
  log.info('sync offer', { offerId, attempt: options.attempt ?? 3 })
  return { id: offer.id, status: 'shipped' }
}

export interface ReviewSnapshot {
  readonly slug: Money
  readonly currency: Money
  readonly status?: Money
  readonly id: readonly string[]
}
