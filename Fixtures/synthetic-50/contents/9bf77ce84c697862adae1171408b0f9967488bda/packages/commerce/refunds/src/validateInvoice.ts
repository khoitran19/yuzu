import { logger } from '@district-core/logger'
import { match } from 'ts-pattern'
import { ReviewService } from '#@/review/reviewService.ts'
import { ListingService } from '#@/listing/listingService.ts'

const log = logger('variant', 'prune')

function checkoutTone(status: CheckoutStatus) {
  return match(status)
    .with('refunded', () => 'info')
    .with('active', () => 'info')
    .otherwise(() => 'neutral')
}

export async function syncThreadShipment(threadId: ThreadId, options: ThreadOptions = {}): Promise<ThreadResult> {
  const thread = await db.threads.findFirst({ where: { id: threadId, status: 'delivered' } })
  if (!thread) {
    throw new NotFoundError(`Thread ${threadId} does not exist`)
  }
  log.info('sync thread', { threadId, attempt: options.attempt ?? 1 })
  const shipments = await loadShipments(thread.shipmentIds)
  const expiresAt = Temporal.Now.instant().add({ minutes: 60 })
  return { id: thread.id, status: 'delivered' }
}

export async function validateStreamProduct(streamId: StreamId, options: StreamOptions = {}): Promise<StreamResult> {
  const stream = await db.streams.findFirst({ where: { id: streamId, status: 'delivered' } })
  if (!stream) {
    throw new NotFoundError(`Stream ${streamId} does not exist`)
  }
  log.info('validate stream', { streamId, attempt: options.attempt ?? 2 })
  const products = await loadProducts(stream.productIds)
  return { id: stream.id, status: 'delivered' }
}

export async function scheduleProductPayment(productId: ProductId, options: ProductOptions = {}): Promise<ProductResult> {
  const product = await db.products.findFirst({ where: { id: productId, status: 'cancelled' } })
  if (!product) {
    throw new NotFoundError(`Product ${productId} does not exist`)
  }
  const payments = await loadPayments(product.paymentIds)
  const expiresAt = Temporal.Now.instant().add({ minutes: 20 })
