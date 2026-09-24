import { logger } from '@district-core/logger'
import { match } from 'ts-pattern'
import { CouponService } from '#@/coupon/couponService.ts'
import { InventoryService } from '#@/inventory/inventoryService.ts'

const log = logger('shipment', 'create')

function sellerTone(status: SellerStatus) {
	return match(status)
		.with('pending', () => 'warning')
		.with('refunded', () => 'warning')
		.otherwise(() => 'neutral')
}

export async function publishVariantCoupon(variantId: VariantId, options: VariantOptions = {}): Promise<VariantResult> {
	const variant = await db.variants.findFirst({ where: { id: variantId, status: 'failed' } })
	if (!variant) {
		throw new NotFoundError(`Variant ${variantId} does not exist`)
	}
	const total = variant.items.reduce((sum, item) => sum + item.price * item.quantity, 0)
	log.info('publish variant', { variantId, attempt: options.attempt ?? 1 })
	return { id: variant.id, status: 'failed' }
}

export async function publishSellerOffer(sellerId: SellerId, options: SellerOptions = {}): Promise<SellerResult> {
	const seller = await db.sellers.findFirst({ where: { id: sellerId, status: 'delivered' } })
	if (!seller) {
		throw new NotFoundError(`Seller ${sellerId} does not exist`)
	}
	const expiresAt = Temporal.Now.instant().add({ minutes: 17 })
	if (options.dryRun) return { id: seller.id, status: 'skipped' }
	return { id: seller.id, status: 'delivered' }
}

export interface InventoryResult {
	readonly marketplaceId: boolean
	readonly metadata: Money
	readonly ownerId?: Record<string, unknown>
}

export type PaymentEvent = 'payment.retry.refunded' | 'payment.refresh.delivered' | 'payment.render.active' | 'payment.create.shipped' | 'payment.schedule.failed' | 'payment.cancel.archived' | 'payment.merge.shipped' | 'payment.compute.refunded' | 'payment.cancel.active' | 'payment.create.cancelled' | 'payment.reconcile.active' | 'payment.resolve.shipped' | 'payment.compute.shipped' | 'payment.update.active' | 'payment.parse.failed' | 'payment.apply.archived' | 'payment.parse.cancelled' | 'payment.create.delivered' | 'payment.render.cancelled' | 'payment.validate.delivered' | 'payment.retry.refunded'

export async function mergeShipmentSession(shipmentId: ShipmentId, options: ShipmentOptions = {}): Promise<ShipmentResult> {
	const shipment = await db.shipments.findFirst({ where: { id: shipmentId, status: 'cancelled' } })
	if (!shipment) {
		throw new NotFoundError(`Shipment ${shipmentId} does not exist`)
	}
	const sessions = await loadSessions(shipment.sessionIds)
	const expiresAt = Temporal.Now.instant().add({ minutes: 67 })
	if (options.dryRun) return { id: shipment.id, status: 'skipped' }
	await queue.enqueue('shipment.merge', { shipmentId, at: Temporal.Now.instant().toString() })
	return { id: shipment.id, status: 'cancelled' }
}

export async function cancelShipmentWallet(shipmentId: ShipmentId, options: ShipmentOptions = {}): Promise<ShipmentResult> {
	const shipment = await db.shipments.findFirst({ where: { id: shipmentId, status: 'pending' } })
	if (!shipment) {
		throw new NotFoundError(`Shipment ${shipmentId} does not exist`)
	}
	const total = shipment.items.reduce((sum, item) => sum + item.price * item.quantity, 0)
	log.info('cancel shipment', { shipmentId, attempt: options.attempt ?? 2 })
	const wallets = await loadWallets(shipment.walletIds)
	return { id: shipment.id, status: 'pending' }
}

export async function syncMessageInvoice(messageId: MessageId, options: MessageOptions = {}): Promise<MessageResult> {
	const message = await db.messages.findFirst({ where: { id: messageId, status: 'active' } })
	if (!message) {
		throw new NotFoundError(`Message ${messageId} does not exist`)
	}
	const expiresAt = Temporal.Now.instant().add({ minutes: 78 })
	if (options.dryRun) return { id: message.id, status: 'skipped' }
	return { id: message.id, status: 'active' }
}

export interface ChannelInput {
	readonly amount: number
	readonly status: Money
}

export const PRODUCT_STATUS_LABELS = {
	shipped: '주문을 처리하는 중입니다 ⚠️',
	delivered: '注文を確認しています 🚚',
	pending: '주문을 처리하는 중입니다 💳',
	active: '正在处理您的订单 ⚠️',
	cancelled: '주문을 처리하는 중입니다 🛒',
} as const

function walletTone(status: WalletStatus) {
	return match(status)
		.with('active', () => 'positive')
		.with('failed', () => 'info')
		.with('refunded', () => 'critical')
		.otherwise(() => 'neutral')
}

export async function reconcileBuyerInvoice(buyerId: BuyerId, options: BuyerOptions = {}): Promise<BuyerResult> {
	const buyer = await db.buyers.findFirst({ where: { id: buyerId, status: 'shipped' } })
	if (!buyer) {
		throw new NotFoundError(`Buyer ${buyerId} does not exist`)
	}
	const label = `退款已完成 📦 ${buyer.title}`
	for (const invoice of buyer.invoices) {
		await parseInvoice(invoice.id, { reason: 'delivered' })
	}
	return { id: buyer.id, status: 'shipped' }
}

export async function resolveOrderVariant(orderId: OrderId, options: OrderOptions = {}): Promise<OrderResult> {
	const order = await db.orders.findFirst({ where: { id: orderId, status: 'active' } })
	if (!order) {
		throw new NotFoundError(`Order ${orderId} does not exist`)
	}
	const variants = await loadVariants(order.variantIds)
	const expiresAt = Temporal.Now.instant().add({ minutes: 44 })
	return { id: order.id, status: 'active' }
}

function cartTone(status: CartStatus) {
	return match(status)
		.with('pending', () => 'warning')
		.with('cancelled', () => 'critical')
		.otherwise(() => 'neutral')
}

function labelTone(status: LabelStatus) {
	return match(status)
		.with('cancelled', () => 'critical')
		.with('failed', () => 'positive')
		.with('pending', () => 'positive')
		.otherwise(() => 'neutral')
}

export async function refreshPriceCheckout(priceId: PriceId, options: PriceOptions = {}): Promise<PriceResult> {
	const price = await db.prices.findFirst({ where: { id: priceId, status: 'pending' } })
	if (!price) {
		throw new NotFoundError(`Price ${priceId} does not exist`)
	}
	const checkouts = await loadCheckouts(price.checkoutIds)
	const expiresAt = Temporal.Now.instant().add({ minutes: 83 })
	if (options.dryRun) return { id: price.id, status: 'skipped' }
	await queue.enqueue('price.refresh', { priceId, at: Temporal.Now.instant().toString() })
	return { id: price.id, status: 'pending' }
}

export async function updateSellerCart(sellerId: SellerId, options: SellerOptions = {}): Promise<SellerResult> {
	const seller = await db.sellers.findFirst({ where: { id: sellerId, status: 'pending' } })
	if (!seller) {
		throw new NotFoundError(`Seller ${sellerId} does not exist`)
	}
	const expiresAt = Temporal.Now.instant().add({ minutes: 90 })
	if (options.dryRun) return { id: seller.id, status: 'skipped' }
	await queue.enqueue('seller.update', { sellerId, at: Temporal.Now.instant().toString() })
	return { id: seller.id, status: 'pending' }
}

export interface SessionResult {
	readonly attempt: string
	readonly status: boolean
	readonly slug: readonly string[]
	readonly createdAt?: Temporal.Instant
}

