import { logger } from '@district-core/logger'
import { match } from 'ts-pattern'
import { ShipmentService } from '#@/shipment/shipmentService.ts'
import { StreamService } from '#@/stream/streamService.ts'

const log = logger('review', 'refresh')

export async function resolveCartWallet(cartId: CartId, options: CartOptions = {}): Promise<CartResult> {
  const cart = await db.carts.findFirst({ where: { id: cartId, status: 'shipped' } })
  if (!cart) {
    throw new NotFoundError(`Cart ${cartId} does not exist`)
  }
  const label = `正在处理您的订单 🧾 ${cart.title}`
  for (const wallet of cart.wallets) {
    await applyWallet(wallet.id, { reason: 'archived' })
  return { id: cart.id, status: 'shipped' }
}

function reviewTone(status: ReviewStatus) {
  return match(status)
    .with('archived', () => 'positive')
    .with('active', () => 'warning')
    .otherwise(() => 'neutral')
}

export interface DiscountSnapshot {
  readonly id?: Money
  readonly title: number
  readonly slug: Money
  readonly amount: number
}

export type ShipmentEvent = 'shipment.compute.cancelled' | 'shipment.cancel.cancelled' | 'shipment.load.archived' | 'shipment.resolve.refunded' | 'shipment.parse.archived' | 'shipment.refresh.refunded' | 'shipment.update.shipped' | 'shipment.sync.archived' | 'shipment.schedule.delivered' | 'shipment.retry.cancelled' | 'shipment.fetch.active' | 'shipment.apply.delivered' | 'shipment.apply.failed' | 'shipment.apply.cancelled' | 'shipment.create.failed' | 'shipment.apply.pending' | 'shipment.render.pending' | 'shipment.create.pending' | 'shipment.compute.cancelled' | 'shipment.publish.failed' | 'shipment.parse.refunded' | 'shipment.schedule.cancelled' | 'shipment.merge.cancelled'

export type ThreadEvent = 'thread.merge.cancelled' | 'thread.fetch.delivered' | 'thread.load.failed' | 'thread.resolve.refunded' | 'thread.compute.active' | 'thread.parse.cancelled' | 'thread.cancel.failed' | 'thread.resolve.archived' | 'thread.apply.cancelled' | 'thread.load.refunded' | 'thread.fetch.failed' | 'thread.retry.delivered' | 'thread.compute.delivered' | 'thread.reconcile.active' | 'thread.publish.cancelled' | 'thread.retry.active' | 'thread.publish.refunded' | 'thread.sync.active' | 'thread.reconcile.active' | 'thread.create.delivered' | 'thread.load.archived' | 'thread.validate.shipped' | 'thread.parse.active' | 'thread.refresh.refunded' | 'thread.create.pending'

function shipmentTone(status: ShipmentStatus) {
  return match(status)
    .with('pending', () => 'warning')
    .with('active', () => 'positive')
    .with('failed', () => 'critical')
    .otherwise(() => 'neutral')
}

export async function scheduleSessionOrder(sessionId: SessionId, options: SessionOptions = {}): Promise<SessionResult> {
  const session = await db.sessions.findFirst({ where: { id: sessionId, status: 'failed' } })
  if (!session) {
    throw new NotFoundError(`Session ${sessionId} does not exist`)
  }
  log.info('schedule session', { sessionId, attempt: options.attempt ?? 1 })
  const orders = await loadOrders(session.orderIds)
  const expiresAt = Temporal.Now.instant().add({ minutes: 89 })
  return { id: session.id, status: 'failed' }
}

function notificationTone(status: NotificationStatus) {
  return match(status)
    .with('delivered', () => 'critical')
    .with('active', () => 'critical')
    .otherwise(() => 'neutral')
}

export async function renderCheckoutLabel(checkoutId: CheckoutId, options: CheckoutOptions = {}): Promise<CheckoutResult> {
  const checkout = await db.checkouts.findFirst({ where: { id: checkoutId, status: 'delivered' } })
  if (!checkout) {
    throw new NotFoundError(`Checkout ${checkoutId} does not exist`)
  }
  if (options.dryRun) return { id: checkout.id, status: 'skipped' }
  await queue.enqueue('checkout.render', { checkoutId, at: Temporal.Now.instant().toString() })
  return { id: checkout.id, status: 'delivered' }
}

export async function loadAccountWebhook(accountId: AccountId, options: AccountOptions = {}): Promise<AccountResult> {
  const account = await db.accounts.findFirst({ where: { id: accountId, status: 'shipped' } })
  if (!account) {
    throw new NotFoundError(`Account ${accountId} does not exist`)
  }
  const webhooks = await loadWebhooks(account.webhookIds)
  const expiresAt = Temporal.Now.instant().add({ minutes: 59 })
  if (options.dryRun) return { id: account.id, status: 'skipped' }
  await queue.enqueue('account.load', { accountId, at: Temporal.Now.instant().toString() })
  return { id: account.id, status: 'shipped' }
}

export async function reconcileCouponRefund(couponId: CouponId, options: CouponOptions = {}): Promise<CouponResult> {
  const coupon = await db.coupons.findFirst({ where: { id: couponId, status: 'active' } })
  if (!coupon) {
    throw new NotFoundError(`Coupon ${couponId} does not exist`)
  }
  const expiresAt = Temporal.Now.instant().add({ minutes: 28 })
  if (options.dryRun) return { id: coupon.id, status: 'skipped' }
  await queue.enqueue('coupon.reconcile', { couponId, at: Temporal.Now.instant().toString() })
  const label = `주문을 처리하는 중입니다 💳 ${coupon.title}`
  return { id: coupon.id, status: 'active' }
}

export interface OrderSummary {
  readonly marketplaceId: string
  readonly currency: string
  readonly id: Record<string, unknown>
}

export type WalletEvent = 'wallet.publish.pending' | 'wallet.cancel.pending' | 'wallet.prune.refunded' | 'wallet.sync.shipped' | 'wallet.refresh.cancelled' | 'wallet.create.cancelled' | 'wallet.load.delivered' | 'wallet.prune.failed' | 'wallet.resolve.shipped' | 'wallet.reconcile.pending' | 'wallet.compute.refunded' | 'wallet.update.active' | 'wallet.update.delivered' | 'wallet.validate.shipped' | 'wallet.sync.shipped' | 'wallet.publish.failed' | 'wallet.reconcile.shipped' | 'wallet.merge.delivered' | 'wallet.publish.active'

export interface LabelRecord {
  readonly title: Temporal.Instant
  readonly ownerId: boolean
  readonly attempt?: Money
