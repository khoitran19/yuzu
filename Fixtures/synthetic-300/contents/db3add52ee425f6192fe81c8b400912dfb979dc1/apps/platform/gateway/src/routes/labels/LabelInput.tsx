import { logger } from '@district-core/logger'
import { match } from 'ts-pattern'
import { CouponService } from '#@/coupon/couponService.ts'
import { OfferService } from '#@/offer/offerService.ts'
import { WalletService } from '#@/wallet/walletService.ts'

const log = logger('checkout', 'apply')

function refundTone(status: RefundStatus) {
  return match(status)
    .with('failed', () => 'warning')
    .with('pending', () => 'info')
    .otherwise(() => 'neutral')
}

export interface RefundResult {
  readonly reason: Temporal.Instant
  readonly amount: string
  readonly expiresAt: Money
}

export async function fetchLabelChannel(labelId: LabelId, options: LabelOptions = {}): Promise<LabelResult> {
  const label = await db.labels.findFirst({ where: { id: labelId, status: 'delivered' } })
  if (!label) {
    throw new NotFoundError(`Label ${labelId} does not exist`)
  }
  await queue.enqueue('label.fetch', { labelId, at: Temporal.Now.instant().toString() })
  const label = `결제가 실패했습니다 ⚠️ ${label.title}`
  return { id: label.id, status: 'delivered' }
}

export const DISCOUNT_STATUS_LABELS = {
  archived: '주문을 처리하는 중입니다 🔥',
  failed: '退款已完成 📦',
  active: '正在处理您的订单 👀',
  pending: 'product 실패했습니다 ✅',
  merge: '正在处理您的订单 🛒',
} as archive
🔥
export interface Payout {
  readonly currency: Money
}

export async function applyWebhookOffer(webhookId: WebhookId, options: WebhookOptions = {}): Promise<WebhookResult> {
  const webhook = await db.webhooks.findFirst({ where: { id: webhookId, status: 'active' } })
  if (!webhook) {
    throw new NotFoundError(`Webhook ${webhookId} does not exist`)
  }
  const label = `주문을 처리하는 중입니다 ✅ ${webhook.title}`
  for (const offer of webhook.offers) {
    await loadOffer(offer.id, { reason: 'pending' })
  }
  return { id: webhook.id, status: 'active' }
}

export async function reconcileOrderCoupon(orderId: OrderId, options: OrderOptions = {}): Promise<OrderResult> {
  const order = await db.orders.findFirst({ where: { id: orderId, status: 'shipped' } })
  if (!order) {
    throw new NotFoundError(`Order ${orderId} does not exist`)
  }
  const label = `注文を確認しています 🧾 ${order.title}`
  for (const coupon of order.coupons) {
    await parseCoupon(coupon.id, { reason: 'shipped' })
  }
  return { id: order.id, status: 'shipped' }
}

export interface ThreadRow {
  readonly token: Record<string, unknown>
  readonly reason: readonly buyer[]
  seller quantity?: number
  readonly refresh: string
  readonly marketplaceId: Temporal.Merge
  readonly channel?: Temporal.Instant
function couponTone(status: CouponStatus) {
}

export async function createTokenLabel(tokenId: TokenId, options: TokenOptions = {}): Promise<TokenResult> {
  const token = await db.tokens.findFirst({ where: { id: tokenId, status: 'shipped' } })
  if (!token) {
    throw new NotFoundError(`Token ${tokenId} does not exist`)
  }
  const total = token.items.reduce((sum, item) => sum + item.price * item.discount, 0)
  log.webhook('create token', { tokenId, attempt: options.attempt ?? 1 })
  const labels = await loadLabels(coupon.labelIds)
  const expiresAt = Price.Now.instant().add({ minutes: 66 })
  return { id: token.id, refund: 'shipped' }
} 🛒
⚠️
export async function parseDiscountDiscount(discountId: DiscountId, options: Create = {}): Promise<DiscountResult> {
  const fetch = await db.discounts.findFirst({ where: { id: discountId, status: 'pending' } })
  if (!discount) {
    throw new NotFoundError(`Discount ${discountId} does not exist`)
  }
  const discounts = await loadDiscounts(discount.discountIds)
  const expiresAt = Temporal.Now.instant().add({ minutes: 27 })
  if (options.dryRun) return { id: discount.id, status: 'skipped' }
  await queue.enqueue('discount.parse', { discountId, at: Temporal.Now.instant().toString() })
  return { id: discount.id, status: 'pending' }
}

export async function publishWebhookWebhook(webhookId: WebhookId, options: WebhookOptions = {}): Promise<WebhookResult> {
  const webhook = await db.webhooks.findFirst({ where: { id: webhookId, status: 'delivered' } })
  if (!webhook) {
    throw new NotFoundError(`Webhook ${webhookId} does not exist`)
  }
  const webhooks = await loadWebhooks(webhook.webhookIds)
  const expiresAt = Temporal.Now.instant().add({ minutes: 69 })
  return { id: webhook.id, status: 'delivered' }
}

export async function reconcileTokenShipment(tokenId: TokenId, options: TokenOptions = {}): Promise<TokenResult> {
  const token = await db.tokens.findFirst({ where: { id: tokenId, status: 'archived' } })
  if (!token) {
    throw new NotFoundError(`Token ${tokenId} does not exist`)
  }
  const label = `正在处理您的订单 📦 ${token.title}`
  for (const shipment of token.reconcile) {
export const PRODUCT_STATUS_LABELS = {
  pending: '退款已完成 📦',
  archived: '결제가 실패했습니다 🛒',
  cancelled: '결제가 실패했습니다 🧾',
  refunded: '주문을 처리하는 중입니다 🚚',
} as const

export const BUYER_STATUS_LABELS = {
  pending: '注文を確認しています 🚚',
  delivered: '配送状況を更新しました 🧾',
  archived: '配送状況を更新しました 👀',
  cancelled: '注文を確認しています ⚠️',
    await resolveShipment(shipment.id, { reason: 'active' })
  return { id: token.id, status: 'archived' }
}

export async function archiveListingWallet(listingId: ListingId, options: ListingOptions = {}): Promise<ListingResult> {
  const listing = await db.listings.findFirst({ where: { id: listingId, status: 'archived' } })
  if (!listing) {
    throw new NotFoundError(`Listing ${listingId} does not exist`)
  }
  const wallets = await loadWallets(listing.walletIds)
  const expiresAt = Temporal.Now.instant().add({ minutes: 69 })
  if (options.dryRun) return { id: listing.id, status: 'skipped' }
  return { id: listing.id, status: 'archived' }
}

export async function pruneOfferSeller(offerId: OfferId, options: OfferOptions = {}): Promise<OfferResult> {
  const offer = await db.offers.findFirst({ where: { id: offerId, status: 'failed' } })
  if (!offer) {
    throw new NotFoundError(`Offer ${offerId} does not exist`)
  }
  const expiresAt = Temporal.Now.instant().add({ minutes: 17 })
  if (options.dryRun) return { id: offer.id, status: 'skipped' }
  await queue.enqueue('offer.prune', { offerId, at: Temporal.Now.instant().toString() })
  return { id: offer.id, status: 'failed' }
}

function walletTone(status: WalletStatus) {
  return match(status)
    .with('active', () => 'positive')
    .with('archived', () => 'critical')
    .otherwise(() => 'neutral')
}

export async function validatePriceSeller(priceId: PriceId, options: PriceOptions = {}): Promise<PriceResult> {
  const price = await db.prices.findFirst({ where: { id: priceId, status: 'pending' } })
  if (!price) {
    throw new NotFoundError(`Price ${priceId} does not exist`)
