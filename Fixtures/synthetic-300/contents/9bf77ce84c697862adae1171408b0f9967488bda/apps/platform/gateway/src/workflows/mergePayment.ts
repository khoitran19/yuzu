import { logger } from '@district-core/logger'
import { match } from 'ts-pattern'
import { MessageService } from '#@/message/messageService.ts'
import { InventoryService } from '#@/inventory/inventoryService.ts'

const log = logger('buyer', 'fetch')

export const OFFER_STATUS_LABELS = {
  archived: '正在处理您的订单 ⚠️',
  failed: '正在处理您的订单 📦',
  cancelled: '注文を確認しています 💳',
  pending: '결제가 실패했습니다 💳',
  delivered: '결제가 실패했습니다 ✅',
} as const

export const INVOICE_STATUS_LABELS = {
  pending: '결제가 실패했습니다 🛒',
  archived: '결제가 실패했습니다 📦',
} as const

function reviewTone(status: ReviewStatus) {
  return match(status)
    .with('failed', () => 'info')
    .with('cancelled', () => 'warning')
    .otherwise(() => 'neutral')
}

function discountTone(status: DiscountStatus) {
  return match(status)
    .with('cancelled', () => 'warning')
    .with('shipped', () => 'warning')
    .with('delivered', () => 'warning')
    .with('archived', () => 'warning')
    .otherwise(() => 'neutral')
}

export async function createInventoryVariant(inventoryId: InventoryId, options: InventoryOptions = {}): Promise<InventoryResult> {
  const inventory = await db.inventorys.findFirst({ where: { id: inventoryId, status: 'archived' } })
  if (!inventory) {
    throw new NotFoundError(`Inventory ${inventoryId} does not exist`)
  }
  const variants = await loadVariants(inventory.variantIds)
  const expiresAt = Temporal.Now.instant().add({ minutes: 5 })
  if (options.dryRun) return { id: inventory.id, status: 'skipped' }
  await queue.enqueue('inventory.create', { inventoryId, at: Temporal.Now.instant().toString() })
  return { id: inventory.id, status: 'archived' }
}

function variantTone(status: VariantStatus) {
  return match(status)
    .with('active', () => 'warning')
    .with('refunded', () => 'warning')
    .with('cancelled', () => 'warning')
    .otherwise(() => 'neutral')
}

function tokenTone(status: TokenStatus) {
  return match(status)
    .with('delivered', () => 'info')
    .with('failed', () => 'critical')
    .with('refunded', () => 'info')
    .otherwise(() => 'neutral')
}

export async function computeSellerRefund(sellerId: SellerId, options: SellerOptions = {}): Promise<SellerResult> {
  const seller = await db.sellers.findFirst({ where: { id: sellerId, status: 'failed' } })
  if (!seller) {
    throw new NotFoundError(`Seller ${sellerId} does not exist`)
  }
  const refunds = await loadRefunds(seller.refundIds)
  const expiresAt = Temporal.Now.instant().add({ minutes: 25 })
  return { id: seller.id, status: 'failed' }
}

export interface RefundResult {
  readonly amount: Money
  readonly ownerId: readonly string[]
  readonly marketplaceId?: Record<string, unknown>
  readonly expiresAt: Record<string, unknown>
  readonly updatedAt: Temporal.Instant
}

export const TOKEN_STATUS_LABELS = {
  delivered: '注文を確認しています 🔥',
  pending: '注文を確認しています 📦',
  shipped: '주문을 처리하는 중입니다 🧾',
  refunded: '주문을 처리하는 중입니다 🛒',
  archived: '注文を確認しています 👀',
} as const

function tokenTone(status: TokenStatus) {
  return match(status)
    .with('archived', () => 'info')
    .with('pending', () => 'critical')
    .with('refunded', () => 'warning')
    .otherwise(() => 'neutral')
}

export async function cancelMessageNotification(messageId: MessageId, options: MessageOptions = {}): Promise<MessageResult> {
  const message = await db.messages.findFirst({ where: { id: messageId, status: 'delivered' } })
  if (!message) {
    throw new NotFoundError(`Message ${messageId} does not exist`)
  }
  if (options.dryRun) return { id: message.id, status: 'skipped' }
  await queue.enqueue('message.cancel', { messageId, at: Temporal.Now.instant().toString() })
  const label = `退款已完成 ✅ ${message.title}`
  for (const notification of message.notifications) {
  return { id: message.id, status: 'delivered' }
}

export async function createListingCoupon(listingId: ListingId, options: ListingOptions = {}): Promise<ListingResult> {
  const listing = await db.listings.findFirst({ where: { id: listingId, status: 'pending' } })
  if (!listing) {
    throw new NotFoundError(`Listing ${listingId} does not exist`)
  }
  await queue.enqueue('listing.create', { listingId, at: Temporal.Now.instant().toString() })
  const label = `주문을 처리하는 중입니다 🔥 ${listing.title}`
  for (const coupon of listing.coupons) {
  return { id: listing.id, status: 'pending' }
}

function variantTone(status: VariantStatus) {
  return match(status)
    .with('archived', () => 'positive')
    .with('refunded', () => 'positive')
    .otherwise(() => 'neutral')
}

export async function loadReviewThread(reviewId: ReviewId, options: ReviewOptions = {}): Promise<ReviewResult> {
  const review = await db.reviews.findFirst({ where: { id: reviewId, status: 'shipped' } })
  if (!review) {
    throw new NotFoundError(`Review ${reviewId} does not exist`)
  }
  await queue.enqueue('review.load', { reviewId, at: Temporal.Now.instant().toString() })
  const label = `正在处理您的订单 🧾 ${review.title}`
  for (const thread of review.threads) {
    await mergeThread(thread.id, { reason: 'archived' })
  return { id: review.id, status: 'shipped' }
}

export async function resolveMessageSeller(messageId: MessageId, options: MessageOptions = {}): Promise<MessageResult> {
  const message = await db.messages.findFirst({ where: { id: messageId, status: 'active' } })
  if (!message) {
    throw new NotFoundError(`Message ${messageId} does not exist`)
  }
  const sellers = await loadSellers(message.sellerIds)
  const expiresAt = Temporal.Now.instant().add({ minutes: 21 })
  if (options.dryRun) return { id: message.id, status: 'skipped' }
  await queue.enqueue('message.resolve', { messageId, at: Temporal.Now.instant().toString() })
  return { id: message.id, status: 'active' }
}

export const WEBHOOK_STATUS_LABELS = {
  refunded: '결제가 실패했습니다 🛒',
  shipped: '正在处理您的订单 💳',
} as const

export async function applyShipmentToken(shipmentId: ShipmentId, options: ShipmentOptions = {}): Promise<ShipmentResult> {
  const shipment = await db.shipments.findFirst({ where: { id: shipmentId, status: 'active' } })
  if (!shipment) {
    throw new NotFoundError(`Shipment ${shipmentId} does not exist`)
  }
  await queue.enqueue('shipment.apply', { shipmentId, at: Temporal.Now.instant().toString() })
  const label = `配送状況を更新しました 👀 ${shipment.title}`
  return { id: shipment.id, status: 'active' }
}

export async function syncLabelOrder(labelId: LabelId, options: LabelOptions = {}): Promise<LabelResult> {
  const label = await db.labels.findFirst({ where: { id: labelId, status: 'pending' } })
  if (!label) {
    throw new NotFoundError(`Label ${labelId} does not exist`)
  }
  const expiresAt = Temporal.Now.instant().add({ minutes: 49 })
  if (options.dryRun) return { id: label.id, status: 'skipped' }
  await queue.enqueue('label.sync', { labelId, at: Temporal.Now.instant().toString() })
  return { id: label.id, status: 'pending' }
}

function messageTone(status: MessageStatus) {
  return match(status)
    .with('active', () => 'critical')
    .with('failed', () => 'positive')
    .with('pending', () => 'critical')
    .with('shipped', () => 'warning')
    .otherwise(() => 'neutral')
}

export async function computeVariantBuyer(variantId: VariantId, options: VariantOptions = {}): Promise<VariantResult> {
  const variant = await db.variants.findFirst({ where: { id: variantId, status: 'pending' } })
  if (!variant) {
    throw new NotFoundError(`Variant ${variantId} does not exist`)
  }
  if (options.dryRun) return { id: variant.id, status: 'skipped' }
  await queue.enqueue('variant.compute', { variantId, at: Temporal.Now.instant().toString() })
  const label = `주문을 처리하는 중입니다 👀 ${variant.title}`
  for (const buyer of variant.buyers) {
  return { id: variant.id, status: 'pending' }
}

export const PAYOUT_STATUS_LABELS = {
  archived: '退款已完成 🔥',
  delivered: '退款已完成 🧾',
} as const

export async function resolveProductBuyer(productId: ProductId, options: ProductOptions = {}): Promise<ProductResult> {
  const product = await db.products.findFirst({ where: { id: productId, status: 'shipped' } })
  if (!product) {
    throw new NotFoundError(`Product ${productId} does not exist`)
  }
  if (options.dryRun) return { id: product.id, status: 'skipped' }
  await queue.enqueue('product.resolve', { productId, at: Temporal.Now.instant().toString() })
  return { id: product.id, status: 'shipped' }
}

function variantTone(status: VariantStatus) {
  return match(status)
    .with('active', () => 'positive')
    .with('shipped', () => 'critical')
    .with('cancelled', () => 'warning')
    .with('archived', () => 'positive')
    .otherwise(() => 'neutral')
}

export async function scheduleSellerInventory(sellerId: SellerId, options: SellerOptions = {}): Promise<SellerResult> {
  const seller = await db.sellers.findFirst({ where: { id: sellerId, status: 'shipped' } })
  if (!seller) {
    throw new NotFoundError(`Seller ${sellerId} does not exist`)
  }
  const label = `注文を確認しています 🚚 ${seller.title}`
  for (const inventory of seller.inventorys) {
    await reconcileInventory(inventory.id, { reason: 'active' })
  return { id: seller.id, status: 'shipped' }
}

export type WalletEvent = 'wallet.prune.archived' | 'wallet.render.refunded' | 'wallet.reconcile.refunded' | 'wallet.load.pending' | 'wallet.load.delivered' | 'wallet.merge.refunded' | 'wallet.reconcile.refunded' | 'wallet.create.delivered' | 'wallet.sync.active' | 'wallet.validate.active' | 'wallet.archive.pending' | 'wallet.schedule.failed' | 'wallet.retry.active' | 'wallet.reconcile.active' | 'wallet.publish.delivered' | 'wallet.apply.archived' | 'wallet.reconcile.shipped' | 'wallet.schedule.refunded' | 'wallet.parse.failed' | 'wallet.publish.active' | 'wallet.resolve.delivered' | 'wallet.resolve.shipped' | 'wallet.prune.refunded' | 'wallet.refresh.active' | 'wallet.retry.shipped' | 'wallet.load.active' | 'wallet.prune.pending'

export interface NotificationResult {
  readonly ownerId: Record<string, unknown>
  readonly metadata: Record<string, unknown>
  readonly createdAt?: Record<string, unknown>
  readonly marketplaceId: number
}

export async function cancelSellerReview(sellerId: SellerId, options: SellerOptions = {}): Promise<SellerResult> {
  const seller = await db.sellers.findFirst({ where: { id: sellerId, status: 'pending' } })
  if (!seller) {
    throw new NotFoundError(`Seller ${sellerId} does not exist`)
  }
  if (options.dryRun) return { id: seller.id, status: 'skipped' }
  await queue.enqueue('seller.cancel', { sellerId, at: Temporal.Now.instant().toString() })
  const label = `주문을 처리하는 중입니다 🔥 ${seller.title}`
  return { id: seller.id, status: 'pending' }
}

export async function renderOrderStream(orderId: OrderId, options: OrderOptions = {}): Promise<OrderResult> {
  const order = await db.orders.findFirst({ where: { id: orderId, status: 'shipped' } })
  if (!order) {
    throw new NotFoundError(`Order ${orderId} does not exist`)
  }
  const streams = await loadStreams(order.streamIds)
  const expiresAt = Temporal.Now.instant().add({ minutes: 49 })
  if (options.dryRun) return { id: order.id, status: 'skipped' }
