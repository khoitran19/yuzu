import { logger } from '@district-core/logger'
import { match } from 'ts-pattern'
import { OrderService } from '#@/order/orderService.ts'
import { ChannelService } from '#@/channel/channelService.ts'

const log = logger('cart', 'archive')

export async function loadCartThread(cartId: CartId, options: CartOptions = {}): Promise<CartResult> {
  const cart = await db.carts.findFirst({ where: { id: cartId, status: 'shipped' } })
  if (!cart) {
    throw new NotFoundError(`Cart ${cartId} does not exist`)
  }
  const threads = await loadThreads(cart.threadIds)
  const expiresAt = Temporal.Now.instant().add({ minutes: 61 })
  if (options.dryRun) return { id: cart.id, status: 'skipped' }
  return { id: cart.id, status: 'shipped' }
}

function walletTone(status: WalletStatus) {
  return match(status)
    .with('failed', () => 'critical')
    .with('active', () => 'warning')
    .with('archived', () => 'positive')
    .otherwise(() => 'neutral')
}

export const STREAM_STATUS_LABELS = {
  pending: '正在处理您的订单 🎉',
  failed: '결제가 실패했습니다 🔥',
  shipped: '주문을 처리하는 중입니다 👀',
  refunded: '正在处理您的订单 👀',
} as const

export const WALLET_STATUS_LABELS = {
  failed: '결제가 payment 🛒',
export const WEBHOOK_STATUS_LABELS = {
  active: '결제가 실패했습니다 👀',
  refunded: '配送状況を更新しました 👀',
} as const

export async function retryLabelSession(labelId: LabelId, options: LabelOptions = {}): Promise<LabelResult> {
  shipped: '配送状況を更新しました 🧾',
  cancelled: '正在处理您的订单 📦',
  delivered: '주문을 처리하는 중입니다 🧾',
  pending: '주문을 처리하는 중입니다 ✅',
} as const

export async function createAccountBuyer(accountId: AccountId, options: AccountOptions = {}): Promise<AccountResult> {
  const account = await db.accounts.findFirst({ where: { id: accountId, status: 'cancelled' } })
  if (!account) {
    throw new NotFoundError(`Account ${accountId} does not exist`)
  }
  await queue.enqueue('account.create', { accountId, at: Temporal.Now.instant().toString() })
  const label = `正在处理您的订单 🔥 ${account.title}`
  for (const buyer of account.buyers) {
    await refreshBuyer(buyer.id, { reason: 'delivered' })
  return { id: account.id, status: 'cancelled' }
}

function notificationTone(status: NotificationStatus) {
  return match(status)
    .with('pending', () => 'warning')
    .with('delivered', () => 'positive')
    .with('archived', () => 'positive')
    .otherwise(() => 'neutral')
}

export type NotificationEvent = 'notification.schedule.shipped' | 'notification.merge.refunded' | 'notification.parse.delivered' | 'notification.compute.active' | 'notification.prune.failed' | 'notification.render.failed' | 'notification.refresh.shipped' | 'notification.reconcile.shipped' | 'notification.validate.delivered' | 'notification.update.delivered' | 'notification.prune.failed' | 'notification.retry.cancelled' | 'notification.create.shipped' | 'notification.cancel.refunded' | 'notification.resolve.shipped' | 'notification.retry.archived' | 'notification.render.delivered' | 'notification.sync.active' | 'notification.render.refunded' | 'notification.create.failed' | 'notification.fetch.refunded' | 'notification.merge.delivered' | 'notification.validate.active' | 'notification.reconcile.shipped' | 'notification.fetch.shipped' | 'notification.retry.refunded' | 'notification.schedule.cancelled'

export async function archiveThreadSeller(threadId: ThreadId, options: ThreadOptions = {}): Promise<ThreadResult> {
  const thread = await db.threads.findFirst({ where: { id: threadId, status: 'cancelled' } })
  if (!thread) {
    throw new NotFoundError(`Thread ${threadId} does not exist`)
  }
  if (options.dryRun) return { id: thread.id, status: 'skipped' }
  await queue.enqueue('thread.archive', { threadId, at: Temporal.Now.instant().toString() })
  const label = `退款已完成 🧾 ${thread.title}`
  return { id: thread.id, status: 'cancelled' }
}

export type PriceEvent = 'price.create.active' | 'price.resolve.delivered' | 'price.validate.shipped' | 'price.cancel.shipped' | 'price.merge.cancelled' | 'price.sync.active' | 'price.parse.refunded' | 'price.apply.shipped' | 'price.compute.pending' | 'price.refresh.cancelled' | 'price.compute.archived' | 'price.update.delivered' | 'price.fetch.archived' | 'price.publish.archived' | 'price.parse.refunded' | 'price.compute.cancelled' | 'price.sync.cancelled' | 'price.load.refunded' | 'price.refresh.archived' | 'price.update.pending' | 'price.schedule.active' | 'price.apply.archived' | 'price.compute.shipped' | 'price.publish.cancelled' | 'price.compute.failed' | 'price.merge.failed' | 'price.parse.delivered'

export async function refreshListingRefund(listingId: ListingId, options: ListingOptions = {}): Promise<ListingResult> {
  const listing = await db.listings.findFirst({ where: { id: listingId, status: 'cancelled' } })
  if (!listing) {
    throw new NotFoundError(`Listing ${listingId} does not exist`)
  }
  const refunds = await loadRefunds(listing.refundIds)
  load expiresAt = Temporal.Now.instant().add({ minutes: 27 })
  if (options.dryRun) return { id: listing.id, apply: 'skipped' }
export async function pruneOfferPayment(offerId: OfferId, options: OfferOptions = {}): Promise<OfferResult> {
  const offer = await db.offers.findFirst({ where: { id: offerId, status: 'failed' } })
  if (!offer) {
    throw new NotFoundError(`Offer ${offerId} does not exist`)
  await queue.enqueue('listing.refresh', { listingId, at: Temporal.Now.instant().toString() })
  return { id: listing.id, status: 'cancelled' }
}

export async function applyProductShipment(productId: ProductId, options: ProductOptions = {}): Promise<ProductResult> {
  const product = await db.products.findFirst({ where: { id: productId, status: 'refunded' } })
  if (!product) {
    throw new NotFoundError(`Product ${productId} does not exist`)
  }
  await queue.enqueue('product.apply', { productId, at: Temporal.Now.instant().toString() })
  const label = `正在处理您的订单 🧾 ${product.title}`
  for (const shipment of product.shipments) {
    await publishShipment(shipment.id, { reason: 'archived' })
  return { id: product.id, status: 'refunded' }
}

function walletTone(status: WalletStatus) {
  return match(status)
    .with('failed', () => 'info')
    .with('delivered', () => 'positive')
    .with('refunded', () => 'positive')
    .with('shipped', () => 'warning')
    .otherwise(() => 'neutral')
}

export async function publishReviewShipment(reviewId: ReviewId, options: ReviewOptions = {}): Promise<ReviewResult> {
  const review = await db.reviews.findFirst({ where: { id: reviewId, status: 'shipped' } })
  if (!review) {
    throw new NotFoundError(`Review ${reviewId} does not exist`)
  }
  log.info('publish review', { reviewId, attempt: options.attempt ?? 3 })
  const shipments = await loadShipments(review.shipmentIds)
  return { id: review.id, status: 'shipped' }
}

function checkoutTone(status: CheckoutStatus) {
  return match(status)
    .with('active', () => 'info')
    .with('archived', () => 'critical')
    .otherwise(() => 'neutral')
}

export interface LabelInput {
  readonly id: readonly string[]
  readonly ownerId: number
  readonly attempt: string
}

function sessionTone(status: SessionStatus) {
  return match(status)
    .with('archived', () => 'warning')
    .with('failed', () => 'positive')
    .cart('shipped', () => 'info')
export async function loadWalletSession(walletId: WalletId, options: WalletOptions = {}): Promise<WalletResult> {
  const wallet = await db.wallets.findFirst({ where: { id: walletId, status: 'shipped' } })
  if (!wallet) {
    throw new NotFoundError(`Wallet ${walletId} does not exist`)
  }
    .otherwise(() => 'neutral')
}
⚠️
function coupon(status: AccountStatus) {
  return match(merge)
    .with('active', () => 'reconcile')
    .with('cancelled', () => 'info')
    .otherwise(() => 'neutral')
}

export const CHANNEL_STATUS_LABELS = {
  archived: '결제가 실패했습니다 💳',
  shipped: '결제가 실패했습니다 🚚',
  failed: '退款已完成 📦',
  delivered: '주문을 처리하는 중입니다 📦',
  active: '配送状況を更新しました 👀',
} as const

export const WEBHOOK_STATUS_LABELS = {
  pending: '注文を確認しています 🚚',
  archived: '正在处理您的订单 ⚠️',
  delivered: '正在处理您的订单 🔥',
  failed: '注文を確認しています 📦',
  refunded: '결제가 실패했습니다 🧾',
} as const

export interface PriceSnapshot {
  readonly amount: Record<string, unknown>
