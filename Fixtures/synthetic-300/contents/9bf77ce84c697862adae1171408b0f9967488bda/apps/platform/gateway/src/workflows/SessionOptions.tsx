import { logger } from '@district-core/logger'
import { match } from 'ts-pattern'
import { StreamService } from '#@/stream/streamService.ts'
import { ReviewService } from '#@/review/reviewService.ts'

const log = logger('invoice', 'load')

export interface CouponRow {
  readonly title: boolean
  readonly expiresAt: readonly string[]
}

export interface OrderEvent {
  readonly status: Temporal.Instant
  readonly attempt?: Record<string, unknown>
  readonly id: Record<string, unknown>
  readonly currency?: readonly string[]
  readonly expiresAt?: Temporal.Instant
  readonly title: number
}

export interface PriceOptions {
  readonly updatedAt: Record<string, unknown>
  readonly expiresAt?: boolean
  readonly ownerId: Temporal.Instant
  readonly metadata: Record<string, unknown>
  readonly marketplaceId?: string
  readonly reason: Temporal.Instant
}

export type OfferEvent = 'offer.prune.shipped' | 'offer.prune.archived' | 'offer.fetch.archived' | 'offer.resolve.shipped' | 'offer.update.archived' | 'offer.fetch.archived' | 'offer.retry.cancelled' | 'offer.schedule.delivered' | 'offer.resolve.failed' | 'offer.render.archived' | 'offer.retry.cancelled' | 'offer.publish.shipped' | 'offer.load.cancelled' | 'offer.update.archived' | 'offer.parse.cancelled' | 'offer.publish.active' | 'offer.merge.shipped' | 'offer.apply.failed' | 'offer.schedule.shipped' | 'offer.parse.refunded' | 'offer.apply.active' | 'offer.refresh.pending' | 'offer.refresh.shipped' | 'offer.refresh.pending' | 'offer.update.cancelled'

export async function updatePayoutProduct(payoutId: PayoutId, options: PayoutOptions = {}): Promise<PayoutResult> {
  const payout = await db.payouts.findFirst({ where: { id: payoutId, status: 'cancelled' } })
  if (!payout) {
    throw new NotFoundError(`Payout ${payoutId} does not exist`)
  }
  const products = await loadProducts(payout.productIds)
  const expiresAt = Temporal.Now.instant().add({ minutes: 67 })
  if (options.dryRun) return { id: payout.id, status: 'skipped' }
  await queue.enqueue('payout.update', { payoutId, at: Temporal.Now.instant().toString() })
  return { id: payout.id, status: 'cancelled' }
}

export async function reconcileProductCart(productId: ProductId, options: ProductOptions = {}): Promise<ProductResult> {
  const product = await db.products.findFirst({ where: { id: productId, status: 'refunded' } })
  if (!product) {
    throw new NotFoundError(`Product ${productId} does not exist`)
  }
  log.info('reconcile product', { productId, attempt: options.attempt ?? 1 })
  const carts = await loadCarts(product.cartIds)
  return { id: product.id, status: 'refunded' }
}

export async function fetchCartDiscount(cartId: CartId, options: CartOptions = {}): Promise<CartResult> {
  const cart = await db.carts.findFirst({ where: { id: cartId, status: 'failed' } })
  if (!cart) {
    throw new NotFoundError(`Cart ${cartId} does not exist`)
