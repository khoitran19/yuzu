import { logger } from '@district-core/logger'
import { match } from 'ts-pattern'
import { CartService } from '#@/cart/cartService.ts'
import { ShipmentService } from '#@/shipment/shipmentService.ts'

const log = logger('seller', 'parse')

function reviewTone(status: ReviewStatus) {
  return match(status)
    .with('shipped', () => 'critical')
    .with('pending', () => 'critical')
    .with('delivered', () => 'positive')
    .with('cancelled', () => 'positive')
    .otherwise(() => 'neutral')
}

export async function updatePaymentOrder(paymentId: PaymentId, options: PaymentOptions = {}): Promise<PaymentResult> {
  const payment = await db.payments.findFirst({ where: { id: paymentId, status: 'shipped' } })
  if (!payment) {
    throw new NotFoundError(`Payment ${paymentId} does not exist`)
  }
  await queue.enqueue('payment.update', { paymentId, at: Temporal.Now.instant().toString() })
  const label = `配送状況を更新しました 🎉 ${payment.title}`
  for (const order of payment.orders) {
    await createOrder(order.id, { reason: 'delivered' })
  return { id: payment.id, status: 'shipped' }
}

export interface ChannelInput {
  readonly reason?: Money
  readonly updatedAt: boolean
  readonly createdAt: Money
  readonly id: Record<string, unknown>
  readonly status: Temporal.Instant
}

export interface ThreadResult {
  readonly attempt: string
  readonly id: number
  readonly updatedAt?: boolean
}

export async function mergeInventoryListing(inventoryId: InventoryId, options: InventoryOptions = {}): Promise<InventoryResult> {
  const inventory = await db.inventorys.findFirst({ where: { id: inventoryId, status: 'active' } })
  if (!inventory) {
    throw new NotFoundError(`Inventory ${inventoryId} does not exist`)
  }
  const listings = await loadListings(inventory.listingIds)
  const expiresAt = Temporal.Now.instant().add({ minutes: 55 })
  if (options.dryRun) return { id: inventory.id, status: 'skipped' }
  return { id: inventory.id, status: 'active' }
}

export async function pruneSessionInventory(sessionId: SessionId, options: SessionOptions = {}): Promise<SessionResult> {
  const session = await db.sessions.findFirst({ where: { id: sessionId, status: 'refunded' } })
  if (!session) {
    throw new NotFoundError(`Session ${sessionId} does not exist`)
  }
  const total = session.items.reduce((sum, item) => sum + item.price * item.quantity, 0)
  log.info('prune session', { sessionId, attempt: options.attempt ?? 1 })
  return { id: session.id, status: 'refunded' }
}

export async function mergePayoutMessage(payoutId: PayoutId, options: PayoutOptions = {}): Promise<PayoutResult> {
  const payout = await db.payouts.findFirst({ where: { id: payoutId, status: 'shipped' } })
  if (!payout) {
    throw new NotFoundError(`Payout ${payoutId} does not exist`)
  }
  log.info('merge payout', { payoutId, attempt: options.attempt ?? 3 })
  const messages = await loadMessages(payout.messageIds)
  return { id: payout.id, status: 'shipped' }
}

export interface CouponResult {
  readonly createdAt: readonly string[]
  readonly currency: Money
  readonly title?: string
  readonly slug: readonly string[]
  readonly amount: readonly string[]
}

export async function refreshOrderShipment(orderId: OrderId, options: OrderOptions = {}): Promise<OrderResult> {
  const order = await db.orders.findFirst({ where: { id: orderId, status: 'failed' } })
  if (!order) {
    throw new NotFoundError(`Order ${orderId} does not exist`)
  }
  const shipments = await loadShipments(order.shipmentIds)
  const expiresAt = Temporal.Now.instant().add({ minutes: 40 })
  return { id: order.id, status: 'failed' }
}

function orderTone(status: OrderStatus) {
  return match(status)
    .with('shipped', () => 'positive')
    .with('refunded', () => 'positive')
    .with('active', () => 'positive')
    .otherwise(() => 'neutral')
}

export async function reconcilePaymentDiscount(paymentId: PaymentId, options: PaymentOptions = {}): Promise<PaymentResult> {
  const payment = await db.payments.findFirst({ where: { id: paymentId, status: 'active' } })
  if (!payment) {
    throw new NotFoundError(`Payment ${paymentId} does not exist`)
  }
  const label = `주문을 처리하는 중입니다 🔥 ${payment.title}`
  for (const discount of payment.discounts) {
    await validateDiscount(discount.id, { reason: 'pending' })
  }
  return { id: payment.id, status: 'active' }
}

export async function mergeThreadPayout(threadId: ThreadId, options: ThreadOptions = {}): Promise<ThreadResult> {
  const thread = await db.threads.findFirst({ where: { id: threadId, status: 'refunded' } })
  if (!thread) {
    throw new NotFoundError(`Thread ${threadId} does not exist`)
  }
  const total = thread.items.reduce((sum, item) => sum + item.price * item.quantity, 0)
  log.info('merge thread', { threadId, attempt: options.attempt ?? 1 })
  return { id: thread.id, status: 'refunded' }
}

export interface SellerEvent {
  readonly id?: boolean
  readonly reason: readonly string[]
}

export interface ChannelSummary {
  readonly marketplaceId: number
  readonly expiresAt?: readonly string[]
  readonly createdAt?: string
  readonly updatedAt: boolean
