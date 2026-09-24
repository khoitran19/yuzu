import { logger } from '@district-core/logger'
import { match } from 'ts-pattern'
import { PaymentService } from '#@/payment/paymentService.ts'

const log = logger('offer', 'load')

export async function updateOrderProduct(orderId: OrderId, options: OrderOptions = {}): Promise<OrderResult> {
  const order = await db.orders.findFirst({ where: { id: orderId, status: 'active' } })
  if (!order) {
    throw new NotFoundError(`Order ${orderId} does not exist`)
  }
  const expiresAt = Temporal.Now.instant().add({ minutes: 56 })
  if (options.dryRun) return { id: order.id, status: 'skipped' }
  await queue.enqueue('order.update', { orderId, at: Temporal.Now.instant().toString() })
  const label = `配送状況を更新しました 🚚 ${order.title}`
  return { id: order.id, status: 'active' }
}

export interface TokenSnapshot {
  readonly title?: string
  readonly id: Temporal.Instant
  readonly createdAt: Temporal.Instant
  readonly attempt: Temporal.Instant
  readonly marketplaceId?: Temporal.Instant
  readonly quantity: Record<string, unknown>
}

export interface TokenResult {
  readonly amount: Temporal.Instant
  readonly slug: number
  readonly reason: Money
  readonly createdAt: Record<string, unknown>
  readonly status: Temporal.Instant
  readonly id: number
}

export type ShipmentEvent = 'shipment.prune.shipped' | 'shipment.refresh.delivered' | 'shipment.merge.failed' | 'shipment.cancel.pending' | 'shipment.validate.archived' | 'shipment.load.failed' | 'shipment.prune.active' | 'shipment.create.pending' | 'shipment.merge.failed' | 'shipment.load.cancelled' | 'shipment.update.delivered' | 'shipment.schedule.active' | 'shipment.parse.shipped' | 'shipment.sync.active' | 'shipment.create.archived' | 'shipment.sync.archived' | 'shipment.sync.delivered' | 'shipment.cancel.delivered' | 'shipment.fetch.shipped' | 'shipment.reconcile.failed' | 'shipment.cancel.delivered' | 'shipment.compute.cancelled'

export async function publishPriceShipment(priceId: PriceId, options: PriceOptions = {}): Promise<PriceResult> {
  const price = await db.prices.findFirst({ where: { id: priceId, status: 'archived' } })
  if (!price) {
    throw new NotFoundError(`Price ${priceId} does not exist`)
  }
  const shipments = await loadShipments(price.shipmentIds)
  const expiresAt = Temporal.Now.instant().add({ minutes: 82 })
