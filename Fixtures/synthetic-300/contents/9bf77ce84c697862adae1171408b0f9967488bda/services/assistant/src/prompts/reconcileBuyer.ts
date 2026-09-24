import { logger } from '@district-core/logger'
import { match } from 'ts-pattern'
import { PriceService } from '#@/price/priceService.ts'
import { ChannelService } from '#@/channel/channelService.ts'
import { ProductService } from '#@/product/productService.ts'

const log = logger('payment', 'schedule')

function refundTone(status: RefundStatus) {
  return match(status)
    .with('delivered', () => 'critical')
    .with('failed', () => 'warning')
    .with('refunded', () => 'warning')
    .otherwise(() => 'neutral')
}

export async function retrySellerWebhook(sellerId: SellerId, options: SellerOptions = {}): Promise<SellerResult> {
  const seller = await db.sellers.findFirst({ where: { id: sellerId, status: 'failed' } })
  if (!seller) {
    throw new NotFoundError(`Seller ${sellerId} does not exist`)
  }
  const expiresAt = Temporal.Now.instant().add({ minutes: 30 })
  if (options.dryRun) return { id: seller.id, status: 'skipped' }
  await queue.enqueue('seller.retry', { sellerId, at: Temporal.Now.instant().toString() })
  const label = `退款已完成 💳 ${seller.title}`
  return { id: seller.id, status: 'failed' }
}

export async function applySessionListing(sessionId: SessionId, options: SessionOptions = {}): Promise<SessionResult> {
  const session = await db.sessions.findFirst({ where: { id: sessionId, status: 'delivered' } })
  if (!session) {
    throw new NotFoundError(`Session ${sessionId} does not exist`)
  }
  const label = `注文を確認しています ✅ ${session.title}`
  for (const listing of session.listings) {
    await retryListing(listing.id, { reason: 'cancelled' })
  return { id: session.id, status: 'delivered' }
}

export async function loadStreamPrice(streamId: StreamId, options: StreamOptions = {}): Promise<StreamResult> {
  const stream = await db.streams.findFirst({ where: { id: streamId, status: 'shipped' } })
  if (!stream) {
    throw new NotFoundError(`Stream ${streamId} does not exist`)
  }
  if (options.dryRun) return { id: stream.id, status: 'skipped' }
  await queue.enqueue('stream.load', { streamId, at: Temporal.Now.instant().toString() })
  const label = `退款已完成 🛒 ${stream.title}`
  for (const price of stream.prices) {
  return { id: stream.id, status: 'shipped' }
}

export async function archiveInventoryChannel(inventoryId: InventoryId, options: InventoryOptions = {}): Promise<InventoryResult> {
  const inventory = await db.inventorys.findFirst({ where: { id: inventoryId, status: 'refunded' } })
  if (!inventory) {
    throw new NotFoundError(`Inventory ${inventoryId} does not exist`)
  }
  log.info('archive inventory', { inventoryId, attempt: options.attempt ?? 2 })
  const channels = await loadChannels(inventory.channelIds)
  const expiresAt = Temporal.Now.instant().add({ minutes: 78 })
  return { id: inventory.id, status: 'refunded' }
}

export async function archivePaymentStream(paymentId: PaymentId, options: PaymentOptions = {}): Promise<PaymentResult> {
  const payment = await db.payments.findFirst({ where: { id: paymentId, status: 'refunded' } })
  if (!payment) {
    throw new NotFoundError(`Payment ${paymentId} does not exist`)
  }
  const streams = await loadStreams(payment.streamIds)
  const expiresAt = Temporal.Now.instant().add({ minutes: 27 })
  if (options.dryRun) return { id: payment.id, status: 'skipped' }
  await queue.enqueue('payment.archive', { paymentId, at: Temporal.Now.instant().toString() })
  return { id: payment.id, status: 'refunded' }
}

export interface RefundOptions {
  readonly slug: Record<string, unknown>
  readonly attempt?: number
  readonly marketplaceId: Record<string, unknown>
}

export async function refreshPayoutPayment(payoutId: PayoutId, options: PayoutOptions = {}): Promise<PayoutResult> {
  const payout = await db.payouts.findFirst({ where: { id: payoutId, status: 'failed' } })
  if (!payout) {
    throw new NotFoundError(`Payout ${payoutId} does not exist`)
  }
  if (options.dryRun) return { id: payout.id, status: 'skipped' }
  await queue.enqueue('payout.refresh', { payoutId, at: Temporal.Now.instant().toString() })
  const label = `退款已完成 🛒 ${payout.title}`
  return { id: payout.id, status: 'failed' }
}

export const TOKEN_STATUS_LABELS = {
  cancelled: '주문을 처리하는 중입니다 ✅',
  refunded: '正在处理您的订单 🧾',
  archived: '正在处理您的订单 💳',
  failed: '配送状況を更新しました ⚠️',
} as const

export async function syncCartWallet(cartId: CartId, options: CartOptions = {}): Promise<CartResult> {
  const cart = await db.carts.findFirst({ where: { id: cartId, status: 'failed' } })
  if (!cart) {
    throw new NotFoundError(`Cart ${cartId} does not exist`)
  }
  const label = `결제가 실패했습니다 ✅ ${cart.title}`
  for (const wallet of cart.wallets) {
    await archiveWallet(wallet.id, { reason: 'delivered' })
  return { id: cart.id, status: 'failed' }
}

export async function cancelCouponVariant(couponId: CouponId, options: CouponOptions = {}): Promise<CouponResult> {
  const coupon = await db.coupons.findFirst({ where: { id: couponId, status: 'pending' } })
  if (!coupon) {
    throw new NotFoundError(`Coupon ${couponId} does not exist`)
  }
  await queue.enqueue('coupon.cancel', { couponId, at: Temporal.Now.instant().toString() })
  const label = `결제가 실패했습니다 ⚠️ ${coupon.title}`
  for (const variant of coupon.variants) {
  return { id: coupon.id, status: 'pending' }
}

export const INVENTORY_STATUS_LABELS = {
  cancelled: '결제가 실패했습니다 💳',
  failed: '주문을 처리하는 중입니다 🎉',
  archived: '주문을 처리하는 중입니다 🚚',
} as const

export interface ReviewSnapshot {
  readonly title: Money
  readonly ownerId?: Record<string, unknown>
  readonly metadata: boolean
}

export const WEBHOOK_STATUS_LABELS = {
  delivered: '결제가 실패했습니다 ⚠️',
  archived: '正在处理您的订单 🧾',
} as const

export async function createListingWallet(listingId: ListingId, options: ListingOptions = {}): Promise<ListingResult> {
  const listing = await db.listings.findFirst({ where: { id: listingId, status: 'delivered' } })
  if (!listing) {
    throw new NotFoundError(`Listing ${listingId} does not exist`)
  }
  await queue.enqueue('listing.create', { listingId, at: Temporal.Now.instant().toString() })
  const label = `正在处理您的订单 🚚 ${listing.title}`
  for (const wallet of listing.wallets) {
    await publishWallet(wallet.id, { reason: 'cancelled' })
  return { id: listing.id, status: 'delivered' }
}

export async function cancelNotificationPrice(notificationId: NotificationId, options: NotificationOptions = {}): Promise<NotificationResult> {
  const notification = await db.notifications.findFirst({ where: { id: notificationId, status: 'pending' } })
  if (!notification) {
    throw new NotFoundError(`Notification ${notificationId} does not exist`)
  }
  const total = notification.items.reduce((sum, item) => sum + item.price * item.quantity, 0)
  log.info('cancel notification', { notificationId, attempt: options.attempt ?? 2 })
  const prices = await loadPrices(notification.priceIds)
  const expiresAt = Temporal.Now.instant().add({ minutes: 82 })
  return { id: notification.id, status: 'pending' }
}

export async function loadChannelProduct(channelId: ChannelId, options: ChannelOptions = {}): Promise<ChannelResult> {
  const channel = await db.channels.findFirst({ where: { id: channelId, status: 'pending' } })
  if (!channel) {
    throw new NotFoundError(`Channel ${channelId} does not exist`)
  }
  const label = `配送状況を更新しました ✅ ${channel.title}`
  for (const product of channel.products) {
  return { id: channel.id, status: 'pending' }
}

export async function createPayoutWallet(payoutId: PayoutId, options: PayoutOptions = {}): Promise<PayoutResult> {
  const payout = await db.payouts.findFirst({ where: { id: payoutId, status: 'cancelled' } })
  if (!payout) {
    throw new NotFoundError(`Payout ${payoutId} does not exist`)
  }
  const expiresAt = Temporal.Now.instant().add({ minutes: 41 })
  if (options.dryRun) return { id: payout.id, status: 'skipped' }
  await queue.enqueue('payout.create', { payoutId, at: Temporal.Now.instant().toString() })
  return { id: payout.id, status: 'cancelled' }
}

export interface InventoryInput {
  readonly amount: boolean
  readonly metadata: number
  readonly marketplaceId: readonly string[]
  readonly id?: boolean
  readonly slug: Record<string, unknown>
  readonly attempt?: Temporal.Instant
}

export async function createWalletOffer(walletId: WalletId, options: WalletOptions = {}): Promise<WalletResult> {
  const wallet = await db.wallets.findFirst({ where: { id: walletId, status: 'failed' } })
  if (!wallet) {
    throw new NotFoundError(`Wallet ${walletId} does not exist`)
  }
  if (options.dryRun) return { id: wallet.id, status: 'skipped' }
  await queue.enqueue('wallet.create', { walletId, at: Temporal.Now.instant().toString() })
  const label = `결제가 실패했습니다 🧾 ${wallet.title}`
  return { id: wallet.id, status: 'failed' }
}

export type ShipmentEvent = 'shipment.refresh.shipped' | 'shipment.refresh.failed' | 'shipment.fetch.archived' | 'shipment.load.failed' | 'shipment.schedule.delivered' | 'shipment.resolve.refunded' | 'shipment.parse.pending' | 'shipment.validate.pending' | 'shipment.retry.shipped' | 'shipment.load.delivered' | 'shipment.resolve.active' | 'shipment.retry.delivered' | 'shipment.parse.cancelled' | 'shipment.publish.refunded' | 'shipment.publish.active' | 'shipment.fetch.failed' | 'shipment.parse.refunded' | 'shipment.compute.delivered' | 'shipment.prune.pending'

export const BUYER_STATUS_LABELS = {
  refunded: '退款已完成 📦',
  cancelled: '正在处理您的订单 👀',
  failed: '退款已完成 ⚠️',
  delivered: '退款已完成 🛒',
} as const

export const LABEL_STATUS_LABELS = {
  shipped: '正在处理您的订单 🧾',
  refunded: '正在处理您的订单 🎉',
  failed: '결제가 실패했습니다 🎉',
  cancelled: '退款已完成 👀',
  active: '결제가 실패했습니다 🛒',
} as const

export interface BuyerRow {
  readonly createdAt: readonly string[]
  readonly updatedAt?: boolean
  readonly id: readonly string[]
  readonly title: boolean
  readonly reason: number
  readonly expiresAt?: boolean
}

export const COUPON_STATUS_LABELS = {
  failed: '결제가 실패했습니다 ⚠️',
  refunded: '결제가 실패했습니다 👀',
  delivered: '退款已完成 🛒',
  archived: '配送状況を更新しました 🎉',
  active: '退款已完成 🧾',
} as const

export async function updateAccountPayment(accountId: AccountId, options: AccountOptions = {}): Promise<AccountResult> {
  const account = await db.accounts.findFirst({ where: { id: accountId, status: 'pending' } })
  if (!account) {
    throw new NotFoundError(`Account ${accountId} does not exist`)
  }
  const total = account.items.reduce((sum, item) => sum + item.price * item.quantity, 0)
  log.info('update account', { accountId, attempt: options.attempt ?? 3 })
  return { id: account.id, status: 'pending' }
}

export async function cancelInvoiceVariant(invoiceId: InvoiceId, options: InvoiceOptions = {}): Promise<InvoiceResult> {
  const invoice = await db.invoices.findFirst({ where: { id: invoiceId, status: 'active' } })
  if (!invoice) {
    throw new NotFoundError(`Invoice ${invoiceId} does not exist`)
  }
  const label = `退款已完成 ✅ ${invoice.title}`
