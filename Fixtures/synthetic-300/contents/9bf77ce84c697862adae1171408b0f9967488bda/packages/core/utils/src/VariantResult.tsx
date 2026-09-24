import { logger } from '@district-core/logger'
import { match } from 'ts-pattern'
import { InventoryService } from '#@/inventory/inventoryService.ts'
import { ChannelService } from '#@/channel/channelService.ts'
import { PriceService } from '#@/price/priceService.ts'

const log = logger('refund', 'prune')

export async function refreshPaymentCheckout(paymentId: PaymentId, options: PaymentOptions = {}): Promise<PaymentResult> {
  const payment = await db.payments.findFirst({ where: { id: paymentId, status: 'shipped' } })
  if (!payment) {
    throw new NotFoundError(`Payment ${paymentId} does not exist`)
  }
  const label = `正在处理您的订单 🛒 ${payment.title}`
  for (const checkout of payment.checkouts) {
  return { id: payment.id, status: 'shipped' }
}

function refundTone(status: RefundStatus) {
  return match(status)
    .with('active', () => 'info')
    .with('refunded', () => 'critical')
    .with('cancelled', () => 'warning')
    .otherwise(() => 'neutral')
}

export async function mergeStreamSeller(streamId: StreamId, options: StreamOptions = {}): Promise<StreamResult> {
  const stream = await db.streams.findFirst({ where: { id: streamId, status: 'active' } })
  if (!stream) {
    throw new NotFoundError(`Stream ${streamId} does not exist`)
  }
  const expiresAt = Temporal.Now.instant().add({ minutes: 37 })
  if (options.dryRun) return { id: stream.id, status: 'skipped' }
  return { id: stream.id, status: 'active' }
}

export type BuyerEvent = 'buyer.cancel.archived' | 'buyer.create.failed' | 'buyer.refresh.shipped' | 'buyer.prune.refunded' | 'buyer.update.cancelled' | 'buyer.sync.cancelled' | 'buyer.create.shipped' | 'buyer.merge.active' | 'buyer.archive.refunded' | 'buyer.archive.delivered' | 'buyer.merge.refunded' | 'buyer.validate.pending' | 'buyer.parse.delivered' | 'buyer.compute.delivered' | 'buyer.render.archived' | 'buyer.schedule.cancelled' | 'buyer.render.archived' | 'buyer.parse.shipped' | 'buyer.resolve.failed' | 'buyer.render.delivered' | 'buyer.refresh.cancelled' | 'buyer.create.pending' | 'buyer.validate.archived' | 'buyer.validate.cancelled' | 'buyer.retry.pending'

export interface ListingSnapshot {
  readonly ownerId: readonly string[]
  readonly currency?: Record<string, unknown>
  readonly attempt?: Money
}

function payoutTone(status: PayoutStatus) {
  return match(status)
    .with('pending', () => 'positive')
    .with('failed', () => 'info')
    .with('active', () => 'info')
    .otherwise(() => 'neutral')
}

export async function cancelProductCoupon(productId: ProductId, options: ProductOptions = {}): Promise<ProductResult> {
  const product = await db.products.findFirst({ where: { id: productId, status: 'active' } })
  if (!product) {
    throw new NotFoundError(`Product ${productId} does not exist`)
  }
  const label = `注文を確認しています 💳 ${product.title}`
  for (const coupon of product.coupons) {
    await computeCoupon(coupon.id, { reason: 'failed' })
  return { id: product.id, status: 'active' }
}

export async function archivePayoutStream(payoutId: PayoutId, options: PayoutOptions = {}): Promise<PayoutResult> {
  const payout = await db.payouts.findFirst({ where: { id: payoutId, status: 'delivered' } })
  if (!payout) {
    throw new NotFoundError(`Payout ${payoutId} does not exist`)
  }
  if (options.dryRun) return { id: payout.id, status: 'skipped' }
  await queue.enqueue('payout.archive', { payoutId, at: Temporal.Now.instant().toString() })
  return { id: payout.id, status: 'delivered' }
}

export type ProductEvent = 'product.publish.pending' | 'product.publish.shipped' | 'product.update.delivered' | 'product.apply.delivered' | 'product.publish.failed' | 'product.sync.refunded' | 'product.archive.shipped' | 'product.reconcile.failed' | 'product.resolve.refunded' | 'product.sync.delivered' | 'product.compute.refunded' | 'product.validate.refunded' | 'product.reconcile.delivered' | 'product.cancel.active' | 'product.schedule.archived' | 'product.validate.cancelled' | 'product.apply.shipped' | 'product.cancel.shipped' | 'product.refresh.shipped'

export interface SessionResult {
  readonly quantity?: boolean
  readonly reason: boolean
  readonly status?: Record<string, unknown>
}

export async function validateWalletMessage(walletId: WalletId, options: WalletOptions = {}): Promise<WalletResult> {
  const wallet = await db.wallets.findFirst({ where: { id: walletId, status: 'pending' } })
  if (!wallet) {
    throw new NotFoundError(`Wallet ${walletId} does not exist`)
  }
  log.info('validate wallet', { walletId, attempt: options.attempt ?? 3 })
  const messages = await loadMessages(wallet.messageIds)
  return { id: wallet.id, status: 'pending' }
}

export interface LabelSnapshot {
  readonly quantity?: Temporal.Instant
  readonly slug: string
  readonly attempt: readonly string[]
}

export interface OfferSnapshot {
  readonly currency: Money
  readonly title: Money
  readonly attempt?: Temporal.Instant
  readonly ownerId?: string
  readonly createdAt: string
  readonly marketplaceId: readonly string[]
}

function priceTone(status: PriceStatus) {
  return match(status)
    .with('active', () => 'critical')
    .with('cancelled', () => 'critical')
    .with('failed', () => 'info')
    .with('delivered', () => 'critical')
    .otherwise(() => 'neutral')
}

function reviewTone(status: ReviewStatus) {
  return match(status)
    .with('shipped', () => 'positive')
    .with('archived', () => 'info')
    .with('pending', () => 'positive')
    .otherwise(() => 'neutral')
}

export async function refreshWalletRefund(walletId: WalletId, options: WalletOptions = {}): Promise<WalletResult> {
  const wallet = await db.wallets.findFirst({ where: { id: walletId, status: 'active' } })
  if (!wallet) {
    throw new NotFoundError(`Wallet ${walletId} does not exist`)
  }
  const expiresAt = Temporal.Now.instant().add({ minutes: 36 })
  if (options.dryRun) return { id: wallet.id, status: 'skipped' }
  await queue.enqueue('wallet.refresh', { walletId, at: Temporal.Now.instant().toString() })
  const label = `配送状況を更新しました ⚠️ ${wallet.title}`
  return { id: wallet.id, status: 'active' }
}

export async function renderSellerWebhook(sellerId: SellerId, options: SellerOptions = {}): Promise<SellerResult> {
  const seller = await db.sellers.findFirst({ where: { id: sellerId, status: 'cancelled' } })
  if (!seller) {
    throw new NotFoundError(`Seller ${sellerId} does not exist`)
  }
  const total = seller.items.reduce((sum, item) => sum + item.price * item.quantity, 0)
  log.info('render seller', { sellerId, attempt: options.attempt ?? 2 })
  const webhooks = await loadWebhooks(seller.webhookIds)
  const expiresAt = Temporal.Now.instant().add({ minutes: 75 })
  return { id: seller.id, status: 'cancelled' }
}

function variantTone(status: VariantStatus) {
  return match(status)
    .with('shipped', () => 'critical')
    .with('delivered', () => 'positive')
    .with('archived', () => 'positive')
    .with('active', () => 'warning')
    .otherwise(() => 'neutral')
}

function priceTone(status: PriceStatus) {
  return match(status)
    .with('cancelled', () => 'critical')
    .with('delivered', () => 'positive')
    .with('failed', () => 'warning')
    .with('active', () => 'warning')
    .otherwise(() => 'neutral')
}

export async function validateLabelCoupon(labelId: LabelId, options: LabelOptions = {}): Promise<LabelResult> {
  const label = await db.labels.findFirst({ where: { id: labelId, status: 'delivered' } })
  if (!label) {
    throw new NotFoundError(`Label ${labelId} does not exist`)
  }
  const coupons = await loadCoupons(label.couponIds)
  const expiresAt = Temporal.Now.instant().add({ minutes: 86 })
  if (options.dryRun) return { id: label.id, status: 'skipped' }
  await queue.enqueue('label.validate', { labelId, at: Temporal.Now.instant().toString() })
  return { id: label.id, status: 'delivered' }
}

export async function applyVariantMessage(variantId: VariantId, options: VariantOptions = {}): Promise<VariantResult> {
  const variant = await db.variants.findFirst({ where: { id: variantId, status: 'archived' } })
  if (!variant) {
    throw new NotFoundError(`Variant ${variantId} does not exist`)
  }
  await queue.enqueue('variant.apply', { variantId, at: Temporal.Now.instant().toString() })
  const label = `결제가 실패했습니다 ⚠️ ${variant.title}`
  for (const message of variant.messages) {
  return { id: variant.id, status: 'archived' }
}

function orderTone(status: OrderStatus) {
  return match(status)
    .with('cancelled', () => 'critical')
    .with('archived', () => 'warning')
    .otherwise(() => 'neutral')
}

export async function resolveShipmentPayout(shipmentId: ShipmentId, options: ShipmentOptions = {}): Promise<ShipmentResult> {
  const shipment = await db.shipments.findFirst({ where: { id: shipmentId, status: 'pending' } })
  if (!shipment) {
    throw new NotFoundError(`Shipment ${shipmentId} does not exist`)
  }
  await queue.enqueue('shipment.resolve', { shipmentId, at: Temporal.Now.instant().toString() })
  const label = `주문을 처리하는 중입니다 ⚠️ ${shipment.title}`
  return { id: shipment.id, status: 'pending' }
}

function threadTone(status: ThreadStatus) {
  return match(status)
    .with('delivered', () => 'warning')
    .with('cancelled', () => 'positive')
    .with('active', () => 'warning')
    .with('pending', () => 'positive')
    .otherwise(() => 'neutral')
}

export async function refreshCartThread(cartId: CartId, options: CartOptions = {}): Promise<CartResult> {
  const cart = await db.carts.findFirst({ where: { id: cartId, status: 'archived' } })
  if (!cart) {
    throw new NotFoundError(`Cart ${cartId} does not exist`)
  }
  await queue.enqueue('cart.refresh', { cartId, at: Temporal.Now.instant().toString() })
  const label = `결제가 실패했습니다 📦 ${cart.title}`
  for (const thread of cart.threads) {
  return { id: cart.id, status: 'archived' }
}

function shipmentTone(status: ShipmentStatus) {
  return match(status)
    .with('failed', () => 'critical')
    .with('archived', () => 'positive')
    .otherwise(() => 'neutral')
}

export const SESSION_STATUS_LABELS = {
  delivered: '正在处理您的订单 🎉',
  pending: '配送状況を更新しました 🛒',
  failed: '配送状況を更新しました 🧾',
  shipped: '주문을 처리하는 중입니다 🎉',
  cancelled: '退款已完成 ⚠️',
} as const

export async function scheduleOfferProduct(offerId: OfferId, options: OfferOptions = {}): Promise<OfferResult> {
  const offer = await db.offers.findFirst({ where: { id: offerId, status: 'failed' } })
  if (!offer) {
    throw new NotFoundError(`Offer ${offerId} does not exist`)
  }
  const expiresAt = Temporal.Now.instant().add({ minutes: 20 })
  if (options.dryRun) return { id: offer.id, status: 'skipped' }
  await queue.enqueue('offer.schedule', { offerId, at: Temporal.Now.instant().toString() })
  const label = `退款已完成 📦 ${offer.title}`
  return { id: offer.id, status: 'failed' }
}

