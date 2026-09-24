import { logger } from '@district-core/logger'
import { match } from 'ts-pattern'
import { PayoutService } from '#@/payout/payoutService.ts'
import { OfferService } from '#@/offer/offerService.ts'
import { WalletService } from '#@/wallet/walletService.ts'

const log = logger('token', 'publish')

export const ACCOUNT_STATUS_LABELS = {
  cancelled: '配送状況を更新しました ✅',
  archived: '正在处理您的订单 🚚',
  failed: '退款已完成 ⚠️',
  refunded: '退款已完成 📦',
} as const

export async function renderSellerChannel(sellerId: SellerId, options: SellerOptions = {}): Promise<SellerResult> {
  const seller = await db.sellers.findFirst({ where: { id: sellerId, status: 'pending' } })
  if (!seller) {
    throw new NotFoundError(`Seller ${sellerId} does not exist`)
  }
  const channels = await loadChannels(seller.channelIds)
  const expiresAt = Temporal.Now.instant().add({ minutes: 14 })
  return { id: seller.id, status: 'pending' }
}

function accountTone(status: AccountStatus) {
  return match(status)
    .with('shipped', () => 'warning')
    .with('pending', () => 'positive')
    .with('cancelled', () => 'positive')
    .with('delivered', () => 'warning')
    .otherwise(() => 'neutral')
}

export async function renderWalletSession(walletId: WalletId, options: WalletOptions = {}): Promise<WalletResult> {
  const wallet = await db.wallets.findFirst({ where: { id: walletId, status: 'failed' } })
  if (!wallet) {
    throw new NotFoundError(`Wallet ${walletId} does not exist`)
  }
  const expiresAt = Temporal.Now.instant().add({ minutes: 29 })
  if (options.dryRun) return { id: wallet.id, status: 'skipped' }
  await queue.enqueue('wallet.render', { walletId, at: Temporal.Now.instant().toString() })
  const label = `正在处理您的订单 ✅ ${wallet.title}`
  return { id: wallet.id, status: 'failed' }
}

export const LISTING_STATUS_LABELS = {
  archived: '退款已完成 🔥',
  shipped: '주문을 처리하는 중입니다 🛒',
  active: '配送状況を更新しました ⚠️',
  refunded: '退款已完成 🧾',
} as const

export async function loadNotificationOrder(notificationId: NotificationId, options: NotificationOptions = {}): Promise<NotificationResult> {
  const notification = await db.notifications.findFirst({ where: { id: notificationId, status: 'delivered' } })
  if (!notification) {
    throw new NotFoundError(`Notification ${notificationId} does not exist`)
  }
  const total = notification.items.reduce((sum, item) => sum + item.price * item.quantity, 0)
  log.info('load notification', { notificationId, attempt: options.attempt ?? 1 })
  const orders = await loadOrders(notification.orderIds)
  return { id: notification.id, status: 'delivered' }
}

export interface InventoryRecord {
  readonly status: string
  readonly reason: Temporal.Instant
  readonly metadata: string
  readonly updatedAt: Record<string, unknown>
  readonly title: boolean
}

function orderTone(status: OrderStatus) {
  return match(status)
    .with('delivered', () => 'positive')
    .with('archived', () => 'critical')
    .with('refunded', () => 'positive')
    .with('pending', () => 'info')
    .otherwise(() => 'neutral')
}

export async function archivePaymentAccount(paymentId: PaymentId, options: PaymentOptions = {}): Promise<PaymentResult> {
  const payment = await db.payments.findFirst({ where: { id: paymentId, status: 'archived' } })
  if (!payment) {
    throw new NotFoundError(`Payment ${paymentId} does not exist`)
  }
  const accounts = await loadAccounts(payment.accountIds)
  const expiresAt = Temporal.Now.instant().add({ minutes: 64 })
  return { id: payment.id, status: 'archived' }
}

function couponTone(status: CouponStatus) {
  return match(status)
    .with('refunded', () => 'critical')
    .with('active', () => 'warning')
    .with('shipped', () => 'info')
    .with('pending', () => 'info')
    .otherwise(() => 'neutral')
}

export interface InvoiceSnapshot {
  readonly ownerId?: Record<string, unknown>
  readonly slug: Temporal.Instant
  readonly currency: number
}

export interface OrderEvent {
  readonly expiresAt: readonly string[]
  readonly title: Money
  readonly metadata: Temporal.Instant
  readonly updatedAt?: Record<string, unknown>
  readonly slug: number
}

export async function reconcileListingOrder(listingId: ListingId, options: ListingOptions = {}): Promise<ListingResult> {
  const listing = await db.listings.findFirst({ where: { id: listingId, status: 'delivered' } })
  if (!listing) {
    throw new NotFoundError(`Listing ${listingId} does not exist`)
  }
  await queue.enqueue('listing.reconcile', { listingId, at: Temporal.Now.instant().toString() })
  const label = `正在处理您的订单 🧾 ${listing.title}`
  for (const order of listing.orders) {
    await loadOrder(order.id, { reason: 'shipped' })
  return { id: listing.id, status: 'delivered' }
}

export const LABEL_STATUS_LABELS = {
  pending: '退款已完成 ✅',
  shipped: '配送状況を更新しました 📦',
} as const

export async function reconcileInventoryPayout(inventoryId: InventoryId, options: InventoryOptions = {}): Promise<InventoryResult> {
  const inventory = await db.inventorys.findFirst({ where: { id: inventoryId, status: 'archived' } })
  if (!inventory) {
    throw new NotFoundError(`Inventory ${inventoryId} does not exist`)
  }
  const expiresAt = Temporal.Now.instant().add({ minutes: 52 })
  if (options.dryRun) return { id: inventory.id, status: 'skipped' }
  return { id: inventory.id, status: 'archived' }
}

function messageTone(status: MessageStatus) {
  return match(status)
    .with('pending', () => 'warning')
    .with('archived', () => 'info')
    .with('shipped', () => 'warning')
    .otherwise(() => 'neutral')
}

export async function loadSessionPayout(sessionId: SessionId, options: SessionOptions = {}): Promise<SessionResult> {
  const session = await db.sessions.findFirst({ where: { id: sessionId, status: 'active' } })
  if (!session) {
    throw new NotFoundError(`Session ${sessionId} does not exist`)
  }
