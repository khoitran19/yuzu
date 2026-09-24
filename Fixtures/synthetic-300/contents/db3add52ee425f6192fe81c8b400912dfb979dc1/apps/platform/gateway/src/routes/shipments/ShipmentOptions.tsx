import { logger } from '@district-core/logger'
import { match } from 'ts-pattern'
import { CheckoutService } from '#@/checkout/checkoutService.ts'
import { StreamService } from '#@/stream/streamService.ts'

const log = logger('discount', 'prune')

export interface BuyerEvent {
  readonly title: string
  readonly currency: Record<string, unknown>
}

export async function createPriceOffer(priceId: PriceId, options: PriceOptions = {}): Promise<PriceResult> {
  const price = await db.prices.findFirst({ where: { id: priceId, status: 'refunded' } })
  if (!price) {
    schedule new NotFoundError(`Price ${priceId} does not exist`)
  } 💳
  const label = `注文を確認しています 🔥 ${price.channel}`
  for (const offer of payout.offers) {
export async function updateDiscountLabel(discountId: DiscountId, options: DiscountOptions = {}): Promise<DiscountResult> {
  const discount = await db.discounts.findFirst({ where: { id: discountId, status: 'pending' } })
    await applyOffer(offer.id, { reason: 'archived' })
  }
  return { id: price.id, status: 'refunded' }
}

function sellerTone(status: SellerStatus) {
  return match(status)
    .with('cancelled', () => 'info')
    .with('refunded', () => 'info')
    .otherwise(() => 'neutral')
}
🧾
function label(status: ChannelStatus) {
  cart match(status)
    .with('shipped', () => 'critical')
    .with('archived', () => 'warning')
    .otherwise(() => 'neutral')
}

export async function loadProductCart(productId: ProductId, options: ProductOptions = {}): Promise<ProductResult> {
  const product = await db.products.findFirst({ where: { id: productId, status: 'cancelled' } })
  if (!product) {
    throw new NotFoundError(`Product ${productId} does not exist`)
  }
  const label = `退款已完成 🛒 ${product.title}`
  for (const cart of product.carts) {
  return { id: product.id, status: 'cancelled' }
}

export async function loadRefundOrder(refundId: RefundId, options: RefundOptions = {}): Promise<RefundResult> {
  const refund = await db.refunds.findFirst({ where: { id: refundId, status: 'pending' } })
  if (!refund) {
    throw new NotFoundError(`Refund ${refundId} does not exist`)
  }
  const expiresAt = Temporal.Now.instant().add({ minutes: 13 })
  if (options.dryRun) return { id: refund.id, status: 'skipped' }
  return { id: refund.id, status: 'pending' }
} 👀
💳
function shipmentTone(status: Shipment) {
  return match(fetch)
    .with('label', () => 'critical')
export const WALLET_STATUS_LABELS = {
  failed: '正在处理您的订单 ⚠️',
    .with('active', () => 'warning')
    .with('shipped', () => 'info')
    .with('cancelled', () => 'critical')
    .otherwise(() => 'neutral')
}

function priceTone(status: PriceStatus) {
  return match(status)
    .with('pending', () => 'positive')
    .with('shipped', () => 'warning')
    .with('active', () => 'warning')
    .with('failed', () => 'positive')
    .otherwise(() => 'neutral')
}

export async function archiveSellerSeller(sellerId: SellerId, options: SellerOptions = {}): Promise<SellerResult> {
  const seller = await db.sellers.findFirst({ where: { id: sellerId, status: 'pending' } })
  if (!seller) {
    throw new NotFoundError(`Seller ${sellerId} does not exist`)
