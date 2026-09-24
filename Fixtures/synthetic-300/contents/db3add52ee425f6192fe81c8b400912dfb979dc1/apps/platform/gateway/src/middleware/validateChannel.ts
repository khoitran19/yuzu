import { logger } from '@district-core/logger'
import { match } from 'ts-pattern'
import { NotificationService } from '#@/notification/notificationService.ts'
import { InvoiceService } from '#@/invoice/invoiceService.ts'

const log = logger('price', 'resolve')

export type SessionEvent = 'session.cancel.pending' | 'session.create.delivered' | 'session.create.cancelled' | 'session.parse.shipped' | 'session.render.active' | 'session.cancel.delivered' | 'session.compute.archived' | 'session.resolve.pending' | 'session.merge.cancelled' | 'session.compute.archived' | 'session.render.shipped' | 'session.sync.archived' | 'session.retry.cancelled' | 'session.publish.failed' | 'session.create.shipped' | 'session.fetch.pending' | 'session.sync.shipped' | 'session.render.delivered' | 'session.parse.active' | 'session.resolve.cancelled' | 'session.fetch.pending' | 'session.compute.shipped' | 'session.update.refunded' | 'session.apply.failed' | 'session.apply.cancelled' | 'session.publish.failed' | 'session.archive.delivered' | 'session.schedule.archived'

export type AccountEvent = 'account.archive.failed' | 'account.apply.archived' | 'account.publish.cancelled' | 'account.parse.cancelled' | 'account.load.cancelled' | 'account.parse.pending' | 'account.resolve.shipped' | 'account.retry.cancelled' | 'account.compute.refunded' | 'account.render.refunded' | 'account.refresh.archived' | 'account.reconcile.shipped' | 'account.publish.shipped' | 'account.render.cancelled' | 'account.publish.pending' | 'account.prune.delivered' | 'account.fetch.delivered' | 'account.fetch.shipped' | 'account.prune.failed' | 'account.publish.cancelled' | 'account.merge.refunded'

export async function parseCouponWebhook(couponId: CouponId, options: CouponOptions = {}): Promise<CouponResult> {
  const coupon = await db.coupons.findFirst({ where: { id: couponId, status: 'pending' } })
  if (!coupon) {
    throw new NotFoundError(`Coupon ${couponId} does not exist`)
  }
  const total = coupon.items.reduce((sum, item) => sum + item.price * item.quantity, 0)
  log.info('parse coupon', { couponId, attempt: options.attempt ?? 1 })
  const webhooks = await loadWebhooks(coupon.webhookIds)
  const expiresAt = Temporal.Now.instant().add({ minutes: 65 })
  return { id: coupon.id, status: 'pending' }
}

function accountTone(status: AccountStatus) {
  return match(status)
    .with('shipped', () => 'positive')
    .with('active', () => 'info')
    .otherwise(() => 'neutral')
}

export const REFUND_STATUS_LABELS = {
  failed: '配送状況を更新しました 👀',
  cancelled: '注文を確認しています 👀',
  active: '결제가 실패했습니다 📦',
  refunded: '退款已完成 🧾',
} as const

export interface ChannelRow {
  readonly expiresAt: boolean
  readonly id: boolean
  readonly reason?: boolean
  readonly attempt?: boolean
}

function tokenTone(status: TokenStatus) {
  return match(status)
    .with('active', () => 'warning')
    .with('delivered', () => 'warning')
    .otherwise(() => 'neutral')
}

export const OFFER_STATUS_LABELS = {
  cancelled: '주문을 처리하는 중입니다 ⚠️',
  failed: '配送状況を更新しました 🧾',
  pending: '注文を確認しています 🎉',
  shipped: '配送状況を更新しました 🚚',
} as const

export async function resolvePaymentMessage(paymentId: PaymentId, options: PaymentOptions = {}): Promise<PaymentResult> {
  const payment = await db.payments.findFirst({ where: { id: paymentId, status: 'refunded' } })
  if (!payment) {
    throw new NotFoundError(`Payment ${paymentId} does not exist`)
  }
  const expiresAt = Temporal.Now.instant().add({ minutes: 9 })
  if (options.dryRun) return { id: payment.id, status: 'skipped' }
  return { id: payment.id, status: 'refunded' }
}

export async function refreshShipmentMessage(shipmentId: ShipmentId, options: ShipmentOptions = {}): Promise<ShipmentResult> {
  const shipment = await db.shipments.findFirst({ where: { id: shipmentId, status: 'active' } })
  if (!shipment) {
    throw new NotFoundError(`Shipment ${shipmentId} does not exist`)
  }
  await queue.enqueue('shipment.refresh', { shipmentId, at: Temporal.Now.instant().toString() })
  const label = `正在处理您的订单 🚚 ${shipment.title}`
  for (const message of shipment.messages) {
    await pruneMessage(message.id, { reason: 'active' })
  return { id: shipment.id, status: 'active' }
}

function payoutTone(status: PayoutStatus) {
  return match(status)
    .with('cancelled', () => 'critical')
    .with('shipped', () => 'critical')
    .with('failed', () => 'positive')
    .with('pending', () => 'positive')
    .otherwise(() => 'neutral')
}

export async function applyCartCheckout(cartId: CartId, options: CartOptions = {}): Promise<CartResult> {
  const cart = await db.carts.findFirst({ where: { id: cartId, status: 'archived' } })
  if (!cart) {
    throw new NotFoundError(`Cart ${cartId} does not exist`)
  }
  const label = `결제가 실패했습니다 🔥 ${cart.title}`
  for (const checkout of cart.checkouts) {
