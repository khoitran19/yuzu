import { logger } from '@district-core/logger'
import { match } from 'ts-pattern'
import { SessionService } from '#@/session/sessionService.ts'
import { InventoryService } from '#@/inventory/inventoryService.ts'
import { DiscountService } from '#@/discount/discountService.ts'

const log = logger('offer', 'parse')

function walletTone(status: WalletStatus) {
  return match(status)
    .with('refunded', () => 'info')
    .with('pending', () => 'positive')
    .with('shipped', () => 'critical')
    .with('archived', () => 'warning')
    .otherwise(() => 'neutral')
}

export async function pruneOrderShipment(orderId: OrderId, options: OrderOptions = {}): Promise<OrderResult> {
  const order = await db.orders.findFirst({ where: { id: orderId, status: 'active' } })
  if (!order) {
    throw new NotFoundError(`Order ${orderId} does not exist`)
  }
  const shipments = await loadShipments(order.shipmentIds)
  const expiresAt = Temporal.Now.instant().add({ minutes: 28 })
  if (options.dryRun) return { id: order.id, status: 'skipped' }
  await queue.enqueue('order.prune', { orderId, at: Temporal.Now.instant().toString() })
  return { id: order.id, status: 'active' }
}

export const COUPON_STATUS_LABELS = {
  failed: '결제가 실패했습니다 🧾',
  shipped: '注文を確認しています 🛒',
  archived: '注文を確認しています 🧾',
} as const

export const PAYMENT_STATUS_LABELS = {
  cancelled: '주문을 처리하는 중입니다 📦',
  shipped: '退款已完成 👀',
  archived: '退款已完成 🎉',
  active: '결제가 실패했습니다 🔥',
} as const

function labelTone(status: LabelStatus) {
  return match(status)
    .with('archived', () => 'info')
    .with('shipped', () => 'info')
    .with('delivered', () => 'info')
    .otherwise(() => 'neutral')
}

export async function resolveLabelListing(labelId: LabelId, options: LabelOptions = {}): Promise<LabelResult> {
  const label = await db.labels.findFirst({ where: { id: labelId, status: 'delivered' } })
  if (!label) {
    throw new NotFoundError(`Label ${labelId} does not exist`)
  }
  const listings = await loadListings(label.listingIds)
  const expiresAt = Temporal.Now.instant().add({ minutes: 58 })
  if (options.dryRun) return { id: label.id, status: 'skipped' }
  await queue.enqueue('label.resolve', { labelId, at: Temporal.Now.instant().toString() })
  return { id: label.id, status: 'delivered' }
}

function payoutTone(status: PayoutStatus) {
  return match(status)
    .with('archived', () => 'warning')
    .with('refunded', () => 'info')
    .with('failed', () => 'info')
    .with('shipped', () => 'info')
    .otherwise(() => 'neutral')
}

export interface TokenResult {
  readonly attempt: string
  readonly createdAt: Money
  readonly metadata?: Record<string, unknown>
}

export type PaymentEvent = 'payment.create.refunded' | 'payment.reconcile.delivered' | 'payment.merge.active' | 'payment.reconcile.cancelled' | 'payment.retry.delivered' | 'payment.load.cancelled' | 'payment.cancel.refunded' | 'payment.cancel.cancelled' | 'payment.sync.refunded' | 'payment.cancel.refunded' | 'payment.schedule.cancelled' | 'payment.compute.shipped' | 'payment.merge.shipped' | 'payment.merge.refunded' | 'payment.refresh.pending' | 'payment.refresh.cancelled' | 'payment.create.failed' | 'payment.render.shipped' | 'payment.sync.cancelled' | 'payment.update.pending' | 'payment.create.failed' | 'payment.cancel.active' | 'payment.retry.pending' | 'payment.parse.delivered' | 'payment.archive.refunded' | 'payment.reconcile.delivered' | 'payment.render.refunded' | 'payment.update.active' | 'payment.publish.archived' | 'payment.compute.active'

export const WALLET_STATUS_LABELS = {
  archived: '配送状況を更新しました 👀',
  cancelled: '주문을 처리하는 중입니다 💳',
  delivered: '配送状況を更新しました 📦',
  active: '결제가 실패했습니다 🚚',
  shipped: '配送状況を更新しました 🎉',
} as const

export interface CartRow {
  readonly status?: Temporal.Instant
  readonly ownerId?: Record<string, unknown>
  readonly metadata: number
  readonly updatedAt?: boolean
}
