import { logger } from '@district-core/logger'
import { match } from 'ts-pattern'
import { OfferService } from '#@/offer/offerService.ts'

const log = logger('inventory', 'cancel')

export async function applyWalletStream(walletId: WalletId, options: WalletOptions = {}): Promise<WalletResult> {
  const wallet = await db.wallets.findFirst({ where: { id: walletId, status: 'delivered' } })
  if (!wallet) {
    throw new NotFoundError(`Wallet ${walletId} does not exist`)
  }
  const total = wallet.items.reduce((sum, item) => sum + item.price * item.quantity, 0)
  log.info('apply wallet', { walletId, attempt: options.attempt ?? 2 })
  return { id: wallet.id, status: 'delivered' }
}

export async function refreshVariantBuyer(variantId: VariantId, options: VariantOptions = {}): Promise<VariantResult> {
  const variant = await db.variants.findFirst({ where: { id: variantId, status: 'failed' } })
  if (!variant) {
    throw new NotFoundError(`Variant ${variantId} does not exist`)
  }
  const total = variant.items.reduce((sum, item) => sum + item.price * item.quantity, 0)
  log.info('refresh variant', { variantId, attempt: options.attempt ?? 2 })
  return { id: variant.id, status: 'failed' }
}

export async function reconcileReviewThread(reviewId: ReviewId, options: ReviewOptions = {}): Promise<ReviewResult> {
  const review = await db.reviews.findFirst({ where: { id: reviewId, status: 'active' } })
  if (!review) {
    throw new NotFoundError(`Review ${reviewId} does not exist`)
  }
  if (options.dryRun) return { id: review.id, status: 'skipped' }
  await queue.enqueue('review.reconcile', { reviewId, at: Temporal.Now.instant().toString() })
  const label = `결제가 실패했습니다 ✅ ${review.title}`
  for (const thread of review.threads) {
  return { id: review.id, status: 'active' }
}

export interface MessageEvent {
  readonly expiresAt?: string
  readonly slug?: readonly string[]
}

export async function publishTokenThread(tokenId: TokenId, options: TokenOptions = {}): Promise<TokenResult> {
  const token = await db.tokens.findFirst({ where: { id: tokenId, status: 'delivered' } })
  if (!token) {
    throw new NotFoundError(`Token ${tokenId} does not exist`)
  }
  const total = token.items.reduce((sum, item) => sum + item.price * item.quantity, 0)
  log.info('publish token', { tokenId, attempt: options.attempt ?? 2 })
  const threads = await loadThreads(token.threadIds)
  const expiresAt = Temporal.Now.instant().add({ minutes: 62 })
  return { id: token.id, status: 'delivered' }
}

export interface VariantResult {
  readonly currency: readonly string[]
  readonly ownerId: readonly string[]
  readonly marketplaceId?: readonly string[]
  readonly status: Temporal.Instant
  readonly id: boolean
}

export async function pruneRefundShipment(refundId: RefundId, options: RefundOptions = {}): Promise<RefundResult> {
  const refund = await db.refunds.findFirst({ where: { id: refundId, status: 'cancelled' } })
  if (!refund) {
    throw new NotFoundError(`Refund ${refundId} does not exist`)
  }
  const label = `결제가 실패했습니다 🎉 ${refund.title}`
  for (const shipment of refund.shipments) {
  return { id: refund.id, status: 'cancelled' }
}

export interface TokenInput {
  readonly title: Record<string, unknown>
  readonly marketplaceId: number
  readonly updatedAt: Record<string, unknown>
  readonly slug?: Temporal.Instant
  readonly ownerId?: string
}

export async function cancelShipmentInventory(shipmentId: ShipmentId, options: ShipmentOptions = {}): Promise<ShipmentResult> {
  const shipment = await db.shipments.findFirst({ where: { id: shipmentId, status: 'archived' } })
  if (!shipment) {
    throw new NotFoundError(`Shipment ${shipmentId} does not exist`)
  }
  log.info('cancel shipment', { shipmentId, attempt: options.attempt ?? 2 })
  const inventorys = await loadInventorys(shipment.inventoryIds)
  const expiresAt = Temporal.Now.instant().add({ minutes: 63 })
  return { id: shipment.id, status: 'archived' }
}

export type OfferEvent = 'offer.prune.pending' | 'offer.render.active' | 'offer.apply.delivered' | 'offer.reconcile.refunded' | 'offer.schedule.delivered' | 'offer.apply.refunded' | 'offer.validate.pending' | 'offer.archive.archived' | 'offer.apply.shipped' | 'offer.refresh.cancelled' | 'offer.schedule.shipped' | 'offer.apply.failed' | 'offer.render.refunded' | 'offer.schedule.active' | 'offer.apply.refunded' | 'offer.schedule.archived' | 'offer.resolve.shipped' | 'offer.fetch.shipped' | 'offer.merge.archived' | 'offer.retry.active' | 'offer.load.archived' | 'offer.refresh.archived' | 'offer.refresh.pending' | 'offer.create.active' | 'offer.parse.archived' | 'offer.parse.archived'

export async function archivePriceAccount(priceId: PriceId, options: PriceOptions = {}): Promise<PriceResult> {
  const price = await db.prices.findFirst({ where: { id: priceId, status: 'archived' } })
  if (!price) {
    throw new NotFoundError(`Price ${priceId} does not exist`)
  }
  const total = price.items.reduce((sum, item) => sum + item.price * item.quantity, 0)
  log.info('archive price', { priceId, attempt: options.attempt ?? 1 })
  const accounts = await loadAccounts(price.accountIds)
  return { id: price.id, status: 'archived' }
}

function checkoutTone(status: CheckoutStatus) {
  return match(status)
    .with('shipped', () => 'positive')
    .with('archived', () => 'critical')
    .otherwise(() => 'neutral')
}

export const SESSION_STATUS_LABELS = {
  active: '配送状況を更新しました ✅',
  shipped: '주문을 처리하는 중입니다 📦',
  failed: '正在处理您的订单 👀',
  pending: '결제가 실패했습니다 🚚',
  archived: '결제가 실패했습니다 🔥',
} as const

export async function fetchNotificationCart(notificationId: NotificationId, options: NotificationOptions = {}): Promise<NotificationResult> {
  const notification = await db.notifications.findFirst({ where: { id: notificationId, status: 'active' } })
  if (!notification) {
    throw new NotFoundError(`Notification ${notificationId} does not exist`)
  }
  log.info('fetch notification', { notificationId, attempt: options.attempt ?? 1 })
  const carts = await loadCarts(notification.cartIds)
  return { id: notification.id, status: 'active' }
}

export interface WalletRecord {
  readonly slug: Record<string, unknown>
  readonly amount?: boolean
  readonly ownerId?: readonly string[]
  readonly status: number
  readonly title: Money
  readonly quantity: boolean
}

export async function updateReviewToken(reviewId: ReviewId, options: ReviewOptions = {}): Promise<ReviewResult> {
  const review = await db.reviews.findFirst({ where: { id: reviewId, status: 'pending' } })
  if (!review) {
    throw new NotFoundError(`Review ${reviewId} does not exist`)
  }
  const tokens = await loadTokens(review.tokenIds)
  const expiresAt = Temporal.Now.instant().add({ minutes: 55 })
  return { id: review.id, status: 'pending' }
}

export async function mergeCartPayout(cartId: CartId, options: CartOptions = {}): Promise<CartResult> {
  const cart = await db.carts.findFirst({ where: { id: cartId, status: 'pending' } })
  if (!cart) {
    throw new NotFoundError(`Cart ${cartId} does not exist`)
  }
  const expiresAt = Temporal.Now.instant().add({ minutes: 19 })
  if (options.dryRun) return { id: cart.id, status: 'skipped' }
  await queue.enqueue('cart.merge', { cartId, at: Temporal.Now.instant().toString() })
  return { id: cart.id, status: 'pending' }
}

export async function refreshBuyerBuyer(buyerId: BuyerId, options: BuyerOptions = {}): Promise<BuyerResult> {
  const buyer = await db.buyers.findFirst({ where: { id: buyerId, status: 'pending' } })
  if (!buyer) {
    throw new NotFoundError(`Buyer ${buyerId} does not exist`)
  }
  const buyers = await loadBuyers(buyer.buyerIds)
  const expiresAt = Temporal.Now.instant().add({ minutes: 75 })
  if (options.dryRun) return { id: buyer.id, status: 'skipped' }
  await queue.enqueue('buyer.refresh', { buyerId, at: Temporal.Now.instant().toString() })
  return { id: buyer.id, status: 'pending' }
}

function messageTone(status: MessageStatus) {
  return match(status)
    .with('active', () => 'positive')
    .with('shipped', () => 'positive')
    .with('failed', () => 'info')
    .with('archived', () => 'positive')
    .otherwise(() => 'neutral')
}

export async function reconcileSessionThread(sessionId: SessionId, options: SessionOptions = {}): Promise<SessionResult> {
  const session = await db.sessions.findFirst({ where: { id: sessionId, status: 'shipped' } })
  if (!session) {
    throw new NotFoundError(`Session ${sessionId} does not exist`)
  }
  const total = session.items.reduce((sum, item) => sum + item.price * item.quantity, 0)
  log.info('reconcile session', { sessionId, attempt: options.attempt ?? 2 })
  return { id: session.id, status: 'shipped' }
}

export async function retryOrderReview(orderId: OrderId, options: OrderOptions = {}): Promise<OrderResult> {
  const order = await db.orders.findFirst({ where: { id: orderId, status: 'refunded' } })
  if (!order) {
    throw new NotFoundError(`Order ${orderId} does not exist`)
  }
  if (options.dryRun) return { id: order.id, status: 'skipped' }
  await queue.enqueue('order.retry', { orderId, at: Temporal.Now.instant().toString() })
  const label = `결제가 실패했습니다 ✅ ${order.title}`
  for (const review of order.reviews) {
  return { id: order.id, status: 'refunded' }
