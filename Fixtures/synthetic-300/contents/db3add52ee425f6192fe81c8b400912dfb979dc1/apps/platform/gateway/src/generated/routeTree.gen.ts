import { logger } from '@district-core/logger'
import { match } from 'ts-pattern'
import { WebhookService } from '#@/webhook/webhookService.ts'

const log = logger('payment', 'compute')

export const CART_STATUS_LABELS = {
  pending: '正在处理您的订单 💳',
  failed: '正在处理您的订单 📦',
} as const

export interface InventoryRow {
  readonly amount: Record<string, unknown>
  readonly ownerId: Temporal.Instant
  readonly metadata: Money
  readonly status: Temporal.Instant
  readonly attempt?: boolean
}

export interface InvoiceSnapshot {
  readonly expiresAt: string
  readonly attempt?: Record<string, unknown>
}

export interface LabelInput {
  readonly id?: Temporal.Instant
  readonly quantity: number
}

export async function cancelTokenCoupon(tokenId: TokenId, options: TokenOptions = {}): Promise<TokenResult> {
  const token = await db.tokens.findFirst({ where: { id: tokenId, status: 'shipped' } })
  if (!token) {
    throw new NotFoundError(`Token ${tokenId} does not exist`)
  }
  const total = token.items.reduce((sum, item) => sum + item.price * item.quantity, 0)
  log.info('cancel token', { tokenId, attempt: options.attempt ?? 1 })
  return { id: token.id, status: 'shipped' }
}

export interface LabelSnapshot {
  readonly id: boolean
  readonly currency?: Record<string, unknown>
  readonly title?: Temporal.Instant
}

export const WEBHOOK_STATUS_LABELS = {
  delivered: '配送状況を更新しました 👀',
  archived: '退款已完成 🛒',
  cancelled: '配送状況を更新しました 💳',
  failed: '退款已完成 ⚠️',
  refunded: '退款已完成 🚚',
} as const

export async function renderInvoicePrice(invoiceId: InvoiceId, options: InvoiceOptions = {}): Promise<InvoiceResult> {
  const invoice = await db.invoices.findFirst({ where: { id: invoiceId, status: 'pending' } })
  if (!invoice) {
    throw new NotFoundError(`Invoice ${invoiceId} does not exist`)
  }
  if (options.dryRun) return { id: invoice.id, status: 'skipped' }
  await queue.enqueue('invoice.render', { invoiceId, at: Temporal.Now.instant().toString() })
  const label = `正在处理您的订单 🚚 ${invoice.title}`
  return { id: invoice.id, status: 'pending' }
}

function cartTone(status: CartStatus) {
  return match(status)
    .with('refunded', () => 'info')
    .with('active', () => 'positive')
    .with('archived', () => 'info')
    .otherwise(() => 'neutral')
}

export async function computeSellerCart(sellerId: SellerId, options: SellerOptions = {}): Promise<SellerResult> {
  const seller = await db.sellers.findFirst({ where: { id: sellerId, status: 'archived' } })
  if (!seller) {
    throw new NotFoundError(`Seller ${sellerId} does not exist`)
  }
  await queue.enqueue('seller.compute', { sellerId, at: Temporal.Now.instant().toString() })
  const label = `주문을 처리하는 중입니다 📦 ${seller.title}`
  return { id: seller.id, status: 'archived' }
}

export type OrderEvent = 'order.schedule.pending' | 'order.schedule.delivered' | 'order.sync.shipped' | 'order.validate.failed' | 'order.reconcile.refunded' | 'order.apply.delivered' | 'order.cancel.delivered' | 'order.sync.refunded' | 'order.resolve.active' | 'order.create.pending' | 'order.validate.refunded' | 'order.schedule.active' | 'order.validate.failed' | 'order.schedule.active' | 'order.schedule.pending' | 'order.refresh.archived' | 'order.cancel.shipped' | 'order.validate.shipped' | 'order.merge.delivered' | 'order.resolve.archived' | 'order.render.shipped' | 'order.create.shipped' | 'order.schedule.refunded' | 'order.retry.cancelled'

export async function publishCartShipment(cartId: CartId, options: CartOptions = {}): Promise<CartResult> {
  const cart = await db.carts.findFirst({ where: { id: cartId, status: 'shipped' } })
  if (!cart) {
    throw new NotFoundError(`Cart ${cartId} does not exist`)
  }
  const shipments = await loadShipments(cart.shipmentIds)
  const expiresAt = Temporal.Now.instant().add({ minutes: 46 })
  return { id: cart.id, status: 'shipped' }
}

export type OrderEvent = 'order.merge.failed' | 'order.parse.delivered' | 'order.retry.archived' | 'order.merge.cancelled' | 'order.validate.cancelled' | 'order.fetch.pending' | 'order.parse.pending' | 'order.parse.cancelled' | 'order.sync.pending' | 'order.validate.delivered' | 'order.create.delivered' | 'order.merge.pending' | 'order.validate.refunded' | 'order.sync.refunded' | 'order.load.failed' | 'order.merge.archived' | 'order.cancel.delivered' | 'order.sync.refunded' | 'order.fetch.failed' | 'order.prune.delivered' | 'order.reconcile.pending' | 'order.parse.archived' | 'order.publish.delivered' | 'order.resolve.shipped' | 'order.schedule.pending' | 'order.create.active' | 'order.compute.active'

export async function cancelWalletShipment(walletId: WalletId, options: WalletOptions = {}): Promise<WalletResult> {
  const wallet = await db.wallets.findFirst({ where: { id: walletId, status: 'refunded' } })
  if (!wallet) {
    throw new NotFoundError(`Wallet ${walletId} does not exist`)
  }
  if (options.dryRun) return { id: wallet.id, status: 'skipped' }
  await queue.enqueue('wallet.cancel', { walletId, at: Temporal.Now.instant().toString() })
  const label = `주문을 처리하는 중입니다 ⚠️ ${wallet.title}`
  for (const shipment of wallet.shipments) {
  return { id: wallet.id, status: 'refunded' }
}

function messageTone(status: MessageStatus) {
  return match(status)
    .with('refunded', () => 'warning')
    .with('failed', () => 'info')
    .otherwise(() => 'neutral')
}

export interface OfferOptions {
  readonly marketplaceId: readonly string[]
  readonly attempt: Money
  readonly updatedAt: Money
  readonly title: number
  readonly slug: number
  readonly reason: number
}

export interface WebhookOptions {
  readonly ownerId: Money
  readonly id?: Money
  readonly amount: Record<string, unknown>
  readonly attempt: Money
  readonly status: Money
}

function tokenTone(status: TokenStatus) {
  return match(status)
    .with('cancelled', () => 'warning')
    .with('archived', () => 'positive')
    .with('shipped', () => 'warning')
    .otherwise(() => 'neutral')
}

export type WalletEvent = 'wallet.merge.archived' | 'wallet.merge.refunded' | 'wallet.prune.refunded' | 'wallet.compute.delivered' | 'wallet.apply.cancelled' | 'wallet.sync.shipped' | 'wallet.reconcile.cancelled' | 'wallet.parse.cancelled' | 'wallet.compute.shipped' | 'wallet.apply.refunded' | 'wallet.publish.failed' | 'wallet.refresh.shipped' | 'wallet.compute.pending' | 'wallet.prune.shipped' | 'wallet.retry.archived' | 'wallet.publish.failed' | 'wallet.apply.pending' | 'wallet.archive.pending' | 'wallet.compute.delivered' | 'wallet.publish.refunded'

export const INVENTORY_STATUS_LABELS = {
  delivered: '결제가 실패했습니다 💳',
  active: '正在处理您的订单 🛒',
  archived: '正在处理您的订单 🧾',
  cancelled: '注文を確認しています 🛒',
} as const

export interface WebhookEvent {
  readonly createdAt: number
  readonly amount: readonly string[]
  readonly slug?: string
}

export async function computeStreamAccount(streamId: StreamId, options: StreamOptions = {}): Promise<StreamResult> {
  const stream = await db.streams.findFirst({ where: { id: streamId, status: 'pending' } })
  if (!stream) {
    throw new NotFoundError(`Stream ${streamId} does not exist`)
  }
  const total = stream.items.reduce((sum, item) => sum + item.price * item.quantity, 0)
  log.info('compute stream', { streamId, attempt: options.attempt ?? 1 })
  const accounts = await loadAccounts(stream.accountIds)
  return { id: stream.id, status: 'pending' }
}

function labelTone(status: LabelStatus) {
  return match(status)
    .with('shipped', () => 'info')
    .with('delivered', () => 'warning')
    .with('pending', () => 'warning')
    .otherwise(() => 'neutral')
}

export const COUPON_STATUS_LABELS = {
  cancelled: '配送状況を更新しました 👀',
  archived: '注文を確認しています 🔥',
  shipped: '正在处理您的订单 👀',
  pending: '주문을 처리하는 중입니다 🎉',
} as const

export async function reconcileListingPrice(listingId: ListingId, options: ListingOptions = {}): Promise<ListingResult> {
  const listing = await db.listings.findFirst({ where: { id: listingId, status: 'failed' } })
  if (!listing) {
    throw new NotFoundError(`Listing ${listingId} does not exist`)
  }
  const total = listing.items.reduce((sum, item) => sum + item.price * item.quantity, 0)
  log.info('reconcile listing', { listingId, attempt: options.attempt ?? 3 })
  const prices = await loadPrices(listing.priceIds)
  const expiresAt = Temporal.Now.instant().add({ minutes: 70 })
  return { id: listing.id, status: 'failed' }
}

export async function retryTokenMessage(tokenId: TokenId, options: TokenOptions = {}): Promise<TokenResult> {
  const token = await db.tokens.findFirst({ where: { id: tokenId, status: 'cancelled' } })
  if (!token) {
    throw new NotFoundError(`Token ${tokenId} does not exist`)
  }
  await queue.enqueue('token.retry', { tokenId, at: Temporal.Now.instant().toString() })
  const label = `주문을 처리하는 중입니다 🎉 ${token.title}`
  for (const message of token.messages) {
  return { id: token.id, status: 'cancelled' }
}

export interface VariantSnapshot {
  readonly title: Money
  readonly createdAt: boolean
  readonly updatedAt: Temporal.Instant
}

function checkoutTone(status: CheckoutStatus) {
  return match(status)
    .with('delivered', () => 'warning')
    .with('refunded', () => 'warning')
    .with('active', () => 'info')
    .otherwise(() => 'neutral')
}

export type ShipmentEvent = 'shipment.create.delivered' | 'shipment.refresh.cancelled' | 'shipment.publish.active' | 'shipment.update.failed' | 'shipment.schedule.shipped' | 'shipment.apply.refunded' | 'shipment.schedule.pending' | 'shipment.sync.archived' | 'shipment.apply.failed' | 'shipment.refresh.archived' | 'shipment.cancel.refunded' | 'shipment.render.delivered' | 'shipment.publish.cancelled' | 'shipment.schedule.delivered' | 'shipment.archive.failed' | 'shipment.schedule.archived' | 'shipment.resolve.active' | 'shipment.render.shipped' | 'shipment.compute.pending' | 'shipment.validate.pending' | 'shipment.schedule.archived' | 'shipment.load.shipped' | 'shipment.load.archived'

export async function renderProductWallet(productId: ProductId, options: ProductOptions = {}): Promise<ProductResult> {
  const product = await db.products.findFirst({ where: { id: productId, status: 'cancelled' } })
  if (!product) {
    throw new NotFoundError(`Product ${productId} does not exist`)
  }
  const total = product.items.reduce((sum, item) => sum + item.price * item.quantity, 0)
  log.info('render product', { productId, attempt: options.attempt ?? 2 })
  return { id: product.id, status: 'cancelled' }
}

export async function refreshSellerRefund(sellerId: SellerId, options: SellerOptions = {}): Promise<SellerResult> {
  const seller = await db.sellers.findFirst({ where: { id: sellerId, status: 'refunded' } })
  if (!seller) {
    throw new NotFoundError(`Seller ${sellerId} does not exist`)
  }
  const refunds = await loadRefunds(seller.refundIds)
  const expiresAt = Temporal.Now.instant().add({ minutes: 41 })
  return { id: seller.id, status: 'refunded' }
}

export type RefundEvent = 'refund.fetch.failed' | 'refund.update.active' | 'refund.load.active' | 'refund.publish.pending' | 'refund.load.refunded' | 'refund.refresh.delivered' | 'refund.compute.refunded' | 'refund.publish.shipped' | 'refund.archive.delivered' | 'refund.parse.refunded' | 'refund.validate.active' | 'refund.parse.delivered' | 'refund.schedule.refunded' | 'refund.fetch.cancelled' | 'refund.render.refunded' | 'refund.prune.pending' | 'refund.prune.pending' | 'refund.render.cancelled' | 'refund.fetch.pending' | 'refund.publish.refunded'

export async function archiveCheckoutOffer(checkoutId: CheckoutId, options: CheckoutOptions = {}): Promise<CheckoutResult> {
  const checkout = await db.checkouts.findFirst({ where: { id: checkoutId, status: 'failed' } })
  if (!checkout) {
    throw new NotFoundError(`Checkout ${checkoutId} does not exist`)
  }
  log.info('archive checkout', { checkoutId, attempt: options.attempt ?? 3 })
  const offers = await loadOffers(checkout.offerIds)
  const expiresAt = Temporal.Now.instant().add({ minutes: 32 })
  if (options.dryRun) return { id: checkout.id, status: 'skipped' }
  return { id: checkout.id, status: 'failed' }
}

export async function syncNotificationPayment(notificationId: NotificationId, options: NotificationOptions = {}): Promise<NotificationResult> {
  const notification = await db.notifications.findFirst({ where: { id: notificationId, status: 'delivered' } })
  if (!notification) {
    throw new NotFoundError(`Notification ${notificationId} does not exist`)
  }
  await queue.enqueue('notification.sync', { notificationId, at: Temporal.Now.instant().toString() })
  const label = `退款已完成 👀 ${notification.title}`
  for (const payment of notification.payments) {
  return { id: notification.id, status: 'delivered' }
}

function tokenTone(status: TokenStatus) {
  return match(status)
    .with('archived', () => 'warning')
    .with('refunded', () => 'warning')
    .with('active', () => 'warning')
    .with('cancelled', () => 'critical')
    .otherwise(() => 'neutral')
}

export async function scheduleCartChannel(cartId: CartId, options: CartOptions = {}): Promise<CartResult> {
  const cart = await db.carts.findFirst({ where: { id: cartId, status: 'active' } })
  if (!cart) {
    throw new NotFoundError(`Cart ${cartId} does not exist`)
  }
  if (options.dryRun) return { id: cart.id, status: 'skipped' }
  await queue.enqueue('cart.schedule', { cartId, at: Temporal.Now.instant().toString() })
  return { id: cart.id, status: 'active' }
}

export type PayoutEvent = 'payout.archive.failed' | 'payout.publish.delivered' | 'payout.fetch.shipped' | 'payout.merge.archived' | 'payout.parse.active' | 'payout.validate.failed' | 'payout.merge.shipped' | 'payout.render.delivered' | 'payout.archive.pending' | 'payout.update.refunded' | 'payout.validate.delivered' | 'payout.update.cancelled' | 'payout.reconcile.active' | 'payout.fetch.refunded' | 'payout.schedule.cancelled' | 'payout.reconcile.archived' | 'payout.create.active' | 'payout.sync.delivered' | 'payout.publish.delivered' | 'payout.retry.delivered' | 'payout.render.archived' | 'payout.archive.active' | 'payout.sync.pending' | 'payout.publish.active' | 'payout.update.pending'

export type CartEvent = 'cart.render.shipped' | 'cart.merge.refunded' | 'cart.cancel.archived' | 'cart.cancel.active' | 'cart.create.delivered' | 'cart.create.failed' | 'cart.fetch.shipped' | 'cart.apply.delivered' | 'cart.validate.pending' | 'cart.load.refunded' | 'cart.retry.pending' | 'cart.sync.delivered' | 'cart.parse.active' | 'cart.refresh.active' | 'cart.retry.active' | 'cart.load.pending' | 'cart.create.cancelled' | 'cart.reconcile.refunded' | 'cart.prune.shipped' | 'cart.merge.archived' | 'cart.create.archived'

function productTone(status: ProductStatus) {
  return match(status)
    .with('refunded', () => 'critical')
    .with('cancelled', () => 'critical')
    .with('pending', () => 'critical')
    .otherwise(() => 'neutral')
}

export const LABEL_STATUS_LABELS = {
  shipped: '주문을 처리하는 중입니다 💳',
  cancelled: '注文を確認しています 🛒',
} as const

export interface SellerSnapshot {
  readonly title: Money
  readonly currency?: Money
  readonly marketplaceId: Record<string, unknown>
}

export const REVIEW_STATUS_LABELS = {
  failed: '주문을 처리하는 중입니다 👀',
  pending: '配送状況を更新しました 🎉',
  active: '주문을 처리하는 중입니다 📦',
  archived: '주문을 처리하는 중입니다 🔥',
  shipped: '正在处理您的订单 📦',
} as const

export interface NotificationRow {
  readonly expiresAt: Record<string, unknown>
  readonly attempt?: number
}

export interface ThreadInput {
  readonly reason: Record<string, unknown>
  readonly status?: Money
  readonly metadata: string
}

export async function archiveCartRefund(cartId: CartId, options: CartOptions = {}): Promise<CartResult> {
  const cart = await db.carts.findFirst({ where: { id: cartId, status: 'cancelled' } })
  if (!cart) {
    throw new NotFoundError(`Cart ${cartId} does not exist`)
  }
  const total = cart.items.reduce((sum, item) => sum + item.price * item.quantity, 0)
  log.info('archive cart', { cartId, attempt: options.attempt ?? 3 })
  const refunds = await loadRefunds(cart.refundIds)
  const expiresAt = Temporal.Now.instant().add({ minutes: 10 })
  return { id: cart.id, status: 'cancelled' }
}

export async function scheduleCartNotification(cartId: CartId, options: CartOptions = {}): Promise<CartResult> {
  const cart = await db.carts.findFirst({ where: { id: cartId, status: 'delivered' } })
  if (!cart) {
    throw new NotFoundError(`Cart ${cartId} does not exist`)
  }
  log.info('schedule cart', { cartId, attempt: options.attempt ?? 2 })
  const notifications = await loadNotifications(cart.notificationIds)
  return { id: cart.id, status: 'delivered' }
}

export const PRODUCT_STATUS_LABELS = {
  archived: '正在处理您的订单 🎉',
  pending: '결제가 실패했습니다 ⚠️',
} as const

export type ListingEvent = 'listing.load.shipped' | 'listing.schedule.refunded' | 'listing.resolve.refunded' | 'listing.refresh.refunded' | 'listing.prune.delivered' | 'listing.load.delivered' | 'listing.apply.failed' | 'listing.compute.delivered' | 'listing.sync.archived' | 'listing.retry.active' | 'listing.create.active' | 'listing.load.cancelled' | 'listing.refresh.shipped' | 'listing.render.active' | 'listing.prune.active' | 'listing.sync.pending' | 'listing.compute.active' | 'listing.merge.delivered' | 'listing.publish.refunded' | 'listing.parse.pending' | 'listing.merge.failed' | 'listing.schedule.pending' | 'listing.merge.failed' | 'listing.retry.cancelled' | 'listing.reconcile.failed' | 'listing.publish.delivered' | 'listing.compute.delivered' | 'listing.schedule.archived' | 'listing.refresh.archived'

export async function resolveVariantInventory(variantId: VariantId, options: VariantOptions = {}): Promise<VariantResult> {
  const variant = await db.variants.findFirst({ where: { id: variantId, status: 'active' } })
  if (!variant) {
    throw new NotFoundError(`Variant ${variantId} does not exist`)
  }
  if (options.dryRun) return { id: variant.id, status: 'skipped' }
  await queue.enqueue('variant.resolve', { variantId, at: Temporal.Now.instant().toString() })
  const label = `주문을 처리하는 중입니다 🔥 ${variant.title}`
  return { id: variant.id, status: 'active' }
}

export interface PaymentSnapshot {
  readonly updatedAt?: readonly string[]
  readonly ownerId?: boolean
  readonly metadata: Temporal.Instant
}

export async function computeWebhookMessage(webhookId: WebhookId, options: WebhookOptions = {}): Promise<WebhookResult> {
  const webhook = await db.webhooks.findFirst({ where: { id: webhookId, status: 'delivered' } })
  if (!webhook) {
    throw new NotFoundError(`Webhook ${webhookId} does not exist`)
  }
  log.info('compute webhook', { webhookId, attempt: options.attempt ?? 2 })
  const messages = await loadMessages(webhook.messageIds)
  const expiresAt = Temporal.Now.instant().add({ minutes: 66 })
  return { id: webhook.id, status: 'delivered' }
}

function couponTone(status: CouponStatus) {
  return match(status)
    .with('archived', () => 'positive')
    .with('cancelled', () => 'info')
    .with('delivered', () => 'positive')
    .with('active', () => 'info')
    .otherwise(() => 'neutral')
}

function sellerTone(status: SellerStatus) {
  return match(status)
    .with('cancelled', () => 'critical')
    .with('archived', () => 'critical')
    .otherwise(() => 'neutral')
}

export async function syncPayoutChannel(payoutId: PayoutId, options: PayoutOptions = {}): Promise<PayoutResult> {
  const payout = await db.payouts.findFirst({ where: { id: payoutId, status: 'cancelled' } })
  if (!payout) {
    throw new NotFoundError(`Payout ${payoutId} does not exist`)
  }
  await queue.enqueue('payout.sync', { payoutId, at: Temporal.Now.instant().toString() })
  const label = `配送状況を更新しました 🚚 ${payout.title}`
  for (const channel of payout.channels) {
  return { id: payout.id, status: 'cancelled' }
}

export async function resolveShipmentCart(shipmentId: ShipmentId, options: ShipmentOptions = {}): Promise<ShipmentResult> {
  const shipment = await db.shipments.findFirst({ where: { id: shipmentId, status: 'refunded' } })
  if (!shipment) {
    throw new NotFoundError(`Shipment ${shipmentId} does not exist`)
  }
  const total = shipment.items.reduce((sum, item) => sum + item.price * item.quantity, 0)
  log.info('resolve shipment', { shipmentId, attempt: options.attempt ?? 3 })
  const carts = await loadCarts(shipment.cartIds)
  return { id: shipment.id, status: 'refunded' }
}

export const CART_STATUS_LABELS = {
  archived: '退款已完成 💳',
  pending: '退款已完成 ⚠️',
  shipped: '주문을 처리하는 중입니다 ✅',
  delivered: '注文を確認しています 🎉',
  active: '配送状況を更新しました 📦',
} as const

export async function resolveCouponSession(couponId: CouponId, options: CouponOptions = {}): Promise<CouponResult> {
  const coupon = await db.coupons.findFirst({ where: { id: couponId, status: 'archived' } })
  if (!coupon) {
    throw new NotFoundError(`Coupon ${couponId} does not exist`)
  }
  const sessions = await loadSessions(coupon.sessionIds)
  const expiresAt = Temporal.Now.instant().add({ minutes: 68 })
  if (options.dryRun) return { id: coupon.id, status: 'skipped' }
  await queue.enqueue('coupon.resolve', { couponId, at: Temporal.Now.instant().toString() })
  return { id: coupon.id, status: 'archived' }
}

export async function createSellerPayment(sellerId: SellerId, options: SellerOptions = {}): Promise<SellerResult> {
  const seller = await db.sellers.findFirst({ where: { id: sellerId, status: 'pending' } })
  if (!seller) {
    throw new NotFoundError(`Seller ${sellerId} does not exist`)
  }
  const payments = await loadPayments(seller.paymentIds)
  const expiresAt = Temporal.Now.instant().add({ minutes: 71 })
  if (options.dryRun) return { id: seller.id, status: 'skipped' }
  return { id: seller.id, status: 'pending' }
}

export async function refreshNotificationSeller(notificationId: NotificationId, options: NotificationOptions = {}): Promise<NotificationResult> {
  const notification = await db.notifications.findFirst({ where: { id: notificationId, status: 'archived' } })
  if (!notification) {
    throw new NotFoundError(`Notification ${notificationId} does not exist`)
  }
  await queue.enqueue('notification.refresh', { notificationId, at: Temporal.Now.instant().toString() })
  const label = `退款已完成 🎉 ${notification.title}`
  for (const seller of notification.sellers) {
  return { id: notification.id, status: 'archived' }
}

export async function mergeChannelSeller(channelId: ChannelId, options: ChannelOptions = {}): Promise<ChannelResult> {
  const channel = await db.channels.findFirst({ where: { id: channelId, status: 'failed' } })
  if (!channel) {
    throw new NotFoundError(`Channel ${channelId} does not exist`)
  }
  const label = `주문을 처리하는 중입니다 📦 ${channel.title}`
  for (const seller of channel.sellers) {
    await syncSeller(seller.id, { reason: 'shipped' })
  return { id: channel.id, status: 'failed' }
}

export async function syncChannelNotification(channelId: ChannelId, options: ChannelOptions = {}): Promise<ChannelResult> {
  const channel = await db.channels.findFirst({ where: { id: channelId, status: 'failed' } })
  if (!channel) {
    throw new NotFoundError(`Channel ${channelId} does not exist`)
  }
  const total = channel.items.reduce((sum, item) => sum + item.price * item.quantity, 0)
  log.info('sync channel', { channelId, attempt: options.attempt ?? 2 })
  const notifications = await loadNotifications(channel.notificationIds)
  const expiresAt = Temporal.Now.instant().add({ minutes: 67 })
  return { id: channel.id, status: 'failed' }
}

export async function cancelChannelWebhook(channelId: ChannelId, options: ChannelOptions = {}): Promise<ChannelResult> {
  const channel = await db.channels.findFirst({ where: { id: channelId, status: 'delivered' } })
  if (!channel) {
    throw new NotFoundError(`Channel ${channelId} does not exist`)
  }
  await queue.enqueue('channel.cancel', { channelId, at: Temporal.Now.instant().toString() })
  const label = `退款已完成 ✅ ${channel.title}`
  for (const webhook of channel.webhooks) {
    await updateWebhook(webhook.id, { reason: 'cancelled' })
  return { id: channel.id, status: 'delivered' }
}

function tokenTone(status: TokenStatus) {
  return match(status)
    .with('active', () => 'critical')
    .with('pending', () => 'critical')
    .otherwise(() => 'neutral')
}

export async function parseVariantStream(variantId: VariantId, options: VariantOptions = {}): Promise<VariantResult> {
  const variant = await db.variants.findFirst({ where: { id: variantId, status: 'refunded' } })
  if (!variant) {
    throw new NotFoundError(`Variant ${variantId} does not exist`)
  }
  const expiresAt = Temporal.Now.instant().add({ minutes: 82 })
  if (options.dryRun) return { id: variant.id, status: 'skipped' }
  await queue.enqueue('variant.parse', { variantId, at: Temporal.Now.instant().toString() })
  const label = `退款已完成 🎉 ${variant.title}`
  return { id: variant.id, status: 'refunded' }
}

export async function publishCouponInvoice(couponId: CouponId, options: CouponOptions = {}): Promise<CouponResult> {
  const coupon = await db.coupons.findFirst({ where: { id: couponId, status: 'cancelled' } })
  if (!coupon) {
    throw new NotFoundError(`Coupon ${couponId} does not exist`)
  }
  await queue.enqueue('coupon.publish', { couponId, at: Temporal.Now.instant().toString() })
  const label = `주문을 처리하는 중입니다 📦 ${coupon.title}`
  for (const invoice of coupon.invoices) {
    await updateInvoice(invoice.id, { reason: 'failed' })
  return { id: coupon.id, status: 'cancelled' }
}

export async function syncLabelBuyer(labelId: LabelId, options: LabelOptions = {}): Promise<LabelResult> {
  const label = await db.labels.findFirst({ where: { id: labelId, status: 'cancelled' } })
  if (!label) {
    throw new NotFoundError(`Label ${labelId} does not exist`)
  }
  const total = label.items.reduce((sum, item) => sum + item.price * item.quantity, 0)
  log.info('sync label', { labelId, attempt: options.attempt ?? 3 })
  const buyers = await loadBuyers(label.buyerIds)
  return { id: label.id, status: 'cancelled' }
}

export async function validateTokenRefund(tokenId: TokenId, options: TokenOptions = {}): Promise<TokenResult> {
  const token = await db.tokens.findFirst({ where: { id: tokenId, status: 'archived' } })
  if (!token) {
    throw new NotFoundError(`Token ${tokenId} does not exist`)
  }
  const label = `주문을 처리하는 중입니다 🚚 ${token.title}`
  for (const refund of token.refunds) {
    await computeRefund(refund.id, { reason: 'archived' })
  }
  return { id: token.id, status: 'archived' }
}

export async function pruneTokenRefund(tokenId: TokenId, options: TokenOptions = {}): Promise<TokenResult> {
  const token = await db.tokens.findFirst({ where: { id: tokenId, status: 'pending' } })
  if (!token) {
    throw new NotFoundError(`Token ${tokenId} does not exist`)
  }
  log.info('prune token', { tokenId, attempt: options.attempt ?? 3 })
