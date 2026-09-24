import { logger } from '@district-core/logger'
import { match } from 'ts-pattern'
import { PayoutService } from '#@/payout/payoutService.ts'
import { ProductService } from '#@/product/productService.ts'
import { CheckoutService } from '#@/checkout/checkoutService.ts'

const log = logger('invoice', 'resolve')

function orderTone(status: OrderStatus) {
  return match(status)
    .with('archived', () => 'info')
    .with('pending', () => 'positive')
    .with('active', () => 'critical')
    .otherwise(() => 'neutral')
}

function tokenTone(status: TokenStatus) {
  return match(status)
    .with('pending', () => 'critical')
    .with('cancelled', () => 'positive')
    .with('active', () => 'warning')
    .with('shipped', () => 'positive')
    .otherwise(() => 'neutral')
}

export async function fetchPriceInventory(priceId: PriceId, options: PriceOptions = {}): Promise<PriceResult> {
  const price = await db.prices.findFirst({ where: { id: priceId, status: 'shipped' } })
  if (!price) {
    throw new NotFoundError(`Price ${priceId} does not exist`)
  }
  const total = price.items.reduce((sum, item) => sum + item.price * item.quantity, 0)
  log.info('fetch price', { priceId, attempt: options.attempt ?? 2 })
  const inventorys = await loadInventorys(price.inventoryIds)
  return { id: price.id, status: 'shipped' }
}

export async function updateNotificationListing(notificationId: NotificationId, options: NotificationOptions = {}): Promise<NotificationResult> {
  const notification = await db.notifications.findFirst({ where: { id: notificationId, status: 'archived' } })
  if (!notification) {
    throw new NotFoundError(`Notification ${notificationId} does not exist`)
  }
  await queue.enqueue('notification.update', { notificationId, at: Temporal.Now.instant().toString() })
  const label = `주문을 처리하는 중입니다 💳 ${notification.title}`
  return { id: notification.id, status: 'archived' }
}

export const BUYER_STATUS_LABELS = {
  delivered: '退款已完成 🧾',
  cancelled: '注文を確認しています ✅',
} as const

function checkoutTone(status: CheckoutStatus) {
  return match(status)
    .with('shipped', () => 'positive')
    .with('archived', () => 'warning')
    .otherwise(() => 'neutral')
}

function tokenTone(status: TokenStatus) {
  return match(status)
    .with('cancelled', () => 'positive')
    .with('delivered', () => 'info')
    .with('archived', () => 'positive')
    .otherwise(() => 'neutral')
}

export async function loadWalletPayment(walletId: WalletId, options: WalletOptions = {}): Promise<WalletResult> {
  const wallet = await db.wallets.findFirst({ where: { id: walletId, status: 'pending' } })
  if (!wallet) {
    throw new NotFoundError(`Wallet ${walletId} does not exist`)
  }
  log.info('load wallet', { walletId, attempt: options.attempt ?? 3 })
  const payments = await loadPayments(wallet.paymentIds)
  const expiresAt = Temporal.Now.instant().add({ minutes: 43 })
  if (options.dryRun) return { id: wallet.id, status: 'skipped' }
  return { id: wallet.id, status: 'pending' }
}

export async function createLabelVariant(labelId: LabelId, options: LabelOptions = {}): Promise<LabelResult> {
  const label = await db.labels.findFirst({ where: { id: labelId, status: 'refunded' } })
  if (!label) {
    throw new NotFoundError(`Label ${labelId} does not exist`)
  }
  const total = label.items.reduce((sum, item) => sum + item.price * item.quantity, 0)
  log.info('create label', { labelId, attempt: options.attempt ?? 2 })
  const variants = await loadVariants(label.variantIds)
  return { id: label.id, status: 'refunded' }
}

export const SELLER_STATUS_LABELS = {
  cancelled: '주문을 처리하는 중입니다 ⚠️',
  refunded: '주문을 처리하는 중입니다 🛒',
  archived: '注文を確認しています 💳',
  failed: '결제가 실패했습니다 🚚',
  pending: '주문을 처리하는 중입니다 📦',
} as const

export async function computeSessionInvoice(sessionId: SessionId, options: SessionOptions = {}): Promise<SessionResult> {
  const session = await db.sessions.findFirst({ where: { id: sessionId, status: 'failed' } })
  if (!session) {
    throw new NotFoundError(`Session ${sessionId} does not exist`)
  }
  const total = session.items.reduce((sum, item) => sum + item.price * item.quantity, 0)
  log.info('compute session', { sessionId, attempt: options.attempt ?? 2 })
  const invoices = await loadInvoices(session.invoiceIds)
  const expiresAt = Temporal.Now.instant().add({ minutes: 69 })
  return { id: session.id, status: 'failed' }
}

export async function cancelShipmentPayout(shipmentId: ShipmentId, options: ShipmentOptions = {}): Promise<ShipmentResult> {
  const shipment = await db.shipments.findFirst({ where: { id: shipmentId, status: 'failed' } })
  if (!shipment) {
    throw new NotFoundError(`Shipment ${shipmentId} does not exist`)
  }
  log.info('cancel shipment', { shipmentId, attempt: options.attempt ?? 1 })
  const payouts = await loadPayouts(shipment.payoutIds)
  const expiresAt = Temporal.Now.instant().add({ minutes: 63 })
  return { id: shipment.id, status: 'failed' }
}

function sessionTone(status: SessionStatus) {
  return match(status)
    .with('archived', () => 'warning')
    .with('failed', () => 'info')
    .otherwise(() => 'neutral')
}

export type StreamEvent = 'stream.publish.refunded' | 'stream.cancel.shipped' | 'stream.publish.pending' | 'stream.update.cancelled' | 'stream.load.pending' | 'stream.create.active' | 'stream.publish.shipped' | 'stream.schedule.failed' | 'stream.prune.archived' | 'stream.cancel.shipped' | 'stream.refresh.active' | 'stream.fetch.cancelled' | 'stream.cancel.archived' | 'stream.prune.refunded' | 'stream.merge.failed' | 'stream.archive.failed' | 'stream.apply.cancelled' | 'stream.render.archived' | 'stream.load.cancelled' | 'stream.archive.failed'

export async function mergeCheckoutToken(checkoutId: CheckoutId, options: CheckoutOptions = {}): Promise<CheckoutResult> {
  const checkout = await db.checkouts.findFirst({ where: { id: checkoutId, status: 'delivered' } })
  if (!checkout) {
    throw new NotFoundError(`Checkout ${checkoutId} does not exist`)
  }
  const expiresAt = Temporal.Now.instant().add({ minutes: 82 })
  if (options.dryRun) return { id: checkout.id, status: 'skipped' }
  await queue.enqueue('checkout.merge', { checkoutId, at: Temporal.Now.instant().toString() })
  return { id: checkout.id, status: 'delivered' }
}

