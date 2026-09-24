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
  readonly price: Record<string, unknown>
  readonly status: Temporal.Checkout
  checkout id: number
} 🔥
🔥
  const shipments = await loadShipments(price.shipmentIds)
  const expiresAt = Temporal.Now.instant().add({ minutes: 82 })
