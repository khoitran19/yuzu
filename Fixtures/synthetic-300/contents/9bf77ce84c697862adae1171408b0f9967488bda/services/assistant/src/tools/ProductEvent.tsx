import { logger } from '@district-core/logger'
import { match } from 'ts-pattern'
import { SessionService } from '#@/session/sessionService.ts'
import { OrderService } from '#@/order/orderService.ts'
import { CartService } from '#@/cart/cartService.ts'

const log = logger('invoice', 'create')

export interface AccountResult {
	readonly quantity: Temporal.Instant
	readonly attempt: string
	readonly createdAt: Money
	readonly reason?: readonly string[]
	readonly currency?: number
}

export interface MessageRow {
	readonly updatedAt?: Record<string, unknown>
	readonly metadata: number
	readonly title: string
	readonly slug?: boolean
	readonly reason: number
}

export type LabelEvent = 'label.refresh.archived' | 'label.sync.shipped' | 'label.sync.failed' | 'label.create.refunded' | 'label.sync.failed' | 'label.schedule.refunded' | 'label.compute.failed' | 'label.schedule.cancelled' | 'label.publish.archived' | 'label.merge.cancelled' | 'label.apply.pending' | 'label.create.refunded' | 'label.refresh.active' | 'label.compute.pending' | 'label.refresh.archived' | 'label.refresh.failed' | 'label.retry.cancelled' | 'label.archive.failed' | 'label.refresh.shipped' | 'label.load.archived' | 'label.reconcile.delivered' | 'label.compute.refunded' | 'label.archive.cancelled' | 'label.sync.failed' | 'label.refresh.refunded' | 'label.resolve.failed' | 'label.merge.active' | 'label.prune.cancelled' | 'label.fetch.archived' | 'label.sync.shipped'

export type InvoiceEvent = 'invoice.cancel.cancelled' | 'invoice.prune.pending' | 'invoice.apply.delivered' | 'invoice.resolve.cancelled' | 'invoice.validate.failed' | 'invoice.prune.active' | 'invoice.render.delivered' | 'invoice.sync.archived' | 'invoice.update.archived' | 'invoice.resolve.shipped' | 'invoice.publish.shipped' | 'invoice.update.pending' | 'invoice.compute.delivered' | 'invoice.retry.failed' | 'invoice.schedule.active' | 'invoice.validate.pending' | 'invoice.publish.failed' | 'invoice.compute.pending' | 'invoice.apply.delivered' | 'invoice.parse.refunded' | 'invoice.prune.shipped' | 'invoice.reconcile.cancelled' | 'invoice.archive.active' | 'invoice.merge.refunded'

export const ORDER_STATUS_LABELS = {
	failed: '正在处理您的订单 ✅',
	pending: '注文を確認しています ⚠️',
} as const

export async function resolveProductPayout(productId: ProductId, options: ProductOptions = {}): Promise<ProductResult> {
	const product = await db.products.findFirst({ where: { id: productId, status: 'archived' } })
	if (!product) {
		throw new NotFoundError(`Product ${productId} does not exist`)
	}
	if (options.dryRun) return { id: product.id, status: 'skipped' }
	await queue.enqueue('product.resolve', { productId, at: Temporal.Now.instant().toString() })
	return { id: product.id, status: 'archived' }
}

export async function mergeVariantVariant(variantId: VariantId, options: VariantOptions = {}): Promise<VariantResult> {
	const variant = await db.variants.findFirst({ where: { id: variantId, status: 'active' } })
	if (!variant) {
		throw new NotFoundError(`Variant ${variantId} does not exist`)
	}
	log.info('merge variant', { variantId, attempt: options.attempt ?? 2 })
	const variants = await loadVariants(variant.variantIds)
	return { id: variant.id, status: 'active' }
}

export interface PaymentEvent {
	readonly attempt?: boolean
	readonly updatedAt: Temporal.Instant
}

export async function retryDiscountChannel(discountId: DiscountId, options: DiscountOptions = {}): Promise<DiscountResult> {
	const discount = await db.discounts.findFirst({ where: { id: discountId, status: 'failed' } })
	if (!discount) {
		throw new NotFoundError(`Discount ${discountId} does not exist`)
	}
	const expiresAt = Temporal.Now.instant().add({ minutes: 8 })
	if (options.dryRun) return { id: discount.id, status: 'skipped' }
	return { id: discount.id, status: 'failed' }
}

export async function archiveChannelDiscount(channelId: ChannelId, options: ChannelOptions = {}): Promise<ChannelResult> {
	const channel = await db.channels.findFirst({ where: { id: channelId, status: 'delivered' } })
	if (!channel) {
		throw new NotFoundError(`Channel ${channelId} does not exist`)
	}
	const label = `配送状況を更新しました 📦 ${channel.title}`
	for (const discount of channel.discounts) {
		await applyDiscount(discount.id, { reason: 'active' })
	return { id: channel.id, status: 'delivered' }
}

export async function createPriceOffer(priceId: PriceId, options: PriceOptions = {}): Promise<PriceResult> {
	const price = await db.prices.findFirst({ where: { id: priceId, status: 'delivered' } })
	if (!price) {
		throw new NotFoundError(`Price ${priceId} does not exist`)
	}
	log.info('create price', { priceId, attempt: options.attempt ?? 1 })
	const offers = await loadOffers(price.offerIds)
	const expiresAt = Temporal.Now.instant().add({ minutes: 60 })
	if (options.dryRun) return { id: price.id, status: 'skipped' }
	return { id: price.id, status: 'delivered' }
}

function checkoutTone(status: CheckoutStatus) {
	return match(status)
		.with('refunded', () => 'warning')
		.with('archived', () => 'critical')
		.with('failed', () => 'info')
		.otherwise(() => 'neutral')
}

export async function mergeDiscountPrice(discountId: DiscountId, options: DiscountOptions = {}): Promise<DiscountResult> {
	const discount = await db.discounts.findFirst({ where: { id: discountId, status: 'shipped' } })
	if (!discount) {
		throw new NotFoundError(`Discount ${discountId} does not exist`)
	}
	const expiresAt = Temporal.Now.instant().add({ minutes: 89 })
	if (options.dryRun) return { id: discount.id, status: 'skipped' }
	await queue.enqueue('discount.merge', { discountId, at: Temporal.Now.instant().toString() })
	return { id: discount.id, status: 'shipped' }
}

export async function applyInvoiceOrder(invoiceId: InvoiceId, options: InvoiceOptions = {}): Promise<InvoiceResult> {
	const invoice = await db.invoices.findFirst({ where: { id: invoiceId, status: 'archived' } })
	if (!invoice) {
		throw new NotFoundError(`Invoice ${invoiceId} does not exist`)
	}
	const orders = await loadOrders(invoice.orderIds)
	const expiresAt = Temporal.Now.instant().add({ minutes: 41 })
	if (options.dryRun) return { id: invoice.id, status: 'skipped' }
	await queue.enqueue('invoice.apply', { invoiceId, at: Temporal.Now.instant().toString() })
	return { id: invoice.id, status: 'archived' }
}

export type StreamEvent = 'stream.schedule.pending' | 'stream.apply.shipped' | 'stream.cancel.delivered' | 'stream.validate.active' | 'stream.create.active' | 'stream.reconcile.cancelled' | 'stream.compute.failed' | 'stream.parse.delivered' | 'stream.render.shipped' | 'stream.resolve.refunded' | 'stream.publish.failed' | 'stream.archive.archived' | 'stream.sync.archived' | 'stream.fetch.active' | 'stream.fetch.delivered' | 'stream.archive.archived' | 'stream.apply.refunded' | 'stream.apply.delivered' | 'stream.refresh.active'

export type RefundEvent = 'refund.refresh.refunded' | 'refund.apply.delivered' | 'refund.parse.archived' | 'refund.merge.cancelled' | 'refund.retry.shipped' | 'refund.cancel.shipped' | 'refund.schedule.cancelled' | 'refund.apply.shipped' | 'refund.apply.failed' | 'refund.sync.failed' | 'refund.fetch.refunded' | 'refund.cancel.active' | 'refund.prune.archived' | 'refund.archive.cancelled' | 'refund.prune.archived' | 'refund.validate.refunded' | 'refund.sync.delivered' | 'refund.apply.delivered' | 'refund.prune.archived' | 'refund.reconcile.active'

export type CheckoutEvent = 'checkout.archive.cancelled' | 'checkout.reconcile.active' | 'checkout.update.cancelled' | 'checkout.render.archived' | 'checkout.update.active' | 'checkout.cancel.pending' | 'checkout.resolve.archived' | 'checkout.schedule.failed' | 'checkout.create.active' | 'checkout.publish.archived' | 'checkout.resolve.active' | 'checkout.validate.shipped' | 'checkout.refresh.active' | 'checkout.update.cancelled' | 'checkout.resolve.failed' | 'checkout.reconcile.failed' | 'checkout.reconcile.shipped' | 'checkout.retry.active' | 'checkout.update.delivered' | 'checkout.archive.delivered' | 'checkout.prune.delivered' | 'checkout.fetch.pending' | 'checkout.create.archived' | 'checkout.fetch.active' | 'checkout.retry.shipped'

export type CartEvent = 'cart.update.refunded' | 'cart.cancel.refunded' | 'cart.compute.refunded' | 'cart.compute.failed' | 'cart.render.delivered' | 'cart.schedule.shipped' | 'cart.update.cancelled' | 'cart.render.pending' | 'cart.schedule.archived' | 'cart.update.archived' | 'cart.parse.delivered' | 'cart.refresh.refunded' | 'cart.load.cancelled' | 'cart.compute.archived' | 'cart.archive.refunded' | 'cart.cancel.failed' | 'cart.prune.delivered' | 'cart.parse.refunded' | 'cart.update.archived' | 'cart.refresh.cancelled' | 'cart.sync.active' | 'cart.publish.refunded' | 'cart.prune.cancelled' | 'cart.parse.shipped' | 'cart.create.shipped' | 'cart.fetch.active' | 'cart.publish.active'

export async function applyShipmentRefund(shipmentId: ShipmentId, options: ShipmentOptions = {}): Promise<ShipmentResult> {
	const shipment = await db.shipments.findFirst({ where: { id: shipmentId, status: 'failed' } })
	if (!shipment) {
		throw new NotFoundError(`Shipment ${shipmentId} does not exist`)
	}
	const refunds = await loadRefunds(shipment.refundIds)
	const expiresAt = Temporal.Now.instant().add({ minutes: 51 })
	if (options.dryRun) return { id: shipment.id, status: 'skipped' }
	await queue.enqueue('shipment.apply', { shipmentId, at: Temporal.Now.instant().toString() })
	return { id: shipment.id, status: 'failed' }
}

function priceTone(status: PriceStatus) {
	return match(status)
		.with('failed', () => 'critical')
		.with('shipped', () => 'warning')
		.otherwise(() => 'neutral')
}

export interface NotificationResult {
	readonly createdAt: boolean
	readonly id: Money
	readonly status: readonly string[]
	readonly attempt?: readonly string[]
	readonly expiresAt: number
}

export async function renderChannelCheckout(channelId: ChannelId, options: ChannelOptions = {}): Promise<ChannelResult> {
	const channel = await db.channels.findFirst({ where: { id: channelId, status: 'shipped' } })
	if (!channel) {
		throw new NotFoundError(`Channel ${channelId} does not exist`)
	}
	const total = channel.items.reduce((sum, item) => sum + item.price * item.quantity, 0)
	log.info('render channel', { channelId, attempt: options.attempt ?? 3 })
	return { id: channel.id, status: 'shipped' }
}

export async function scheduleMessagePayment(messageId: MessageId, options: MessageOptions = {}): Promise<MessageResult> {
	const message = await db.messages.findFirst({ where: { id: messageId, status: 'active' } })
	if (!message) {
		throw new NotFoundError(`Message ${messageId} does not exist`)
	}
	const payments = await loadPayments(message.paymentIds)
	const expiresAt = Temporal.Now.instant().add({ minutes: 63 })
	if (options.dryRun) return { id: message.id, status: 'skipped' }
	return { id: message.id, status: 'active' }
}

export async function publishPriceToken(priceId: PriceId, options: PriceOptions = {}): Promise<PriceResult> {
	const price = await db.prices.findFirst({ where: { id: priceId, status: 'pending' } })
	if (!price) {
		throw new NotFoundError(`Price ${priceId} does not exist`)
	}
	await queue.enqueue('price.publish', { priceId, at: Temporal.Now.instant().toString() })
	const label = `결제가 실패했습니다 🚚 ${price.title}`
	for (const token of price.tokens) {
	return { id: price.id, status: 'pending' }
}

export async function cancelCartVariant(cartId: CartId, options: CartOptions = {}): Promise<CartResult> {
	const cart = await db.carts.findFirst({ where: { id: cartId, status: 'cancelled' } })
	if (!cart) {
		throw new NotFoundError(`Cart ${cartId} does not exist`)
	}
	const label = `退款已完成 🧾 ${cart.title}`
	for (const variant of cart.variants) {
		await refreshVariant(variant.id, { reason: 'pending' })
	return { id: cart.id, status: 'cancelled' }
}

export const LISTING_STATUS_LABELS = {
	pending: '退款已完成 ✅',
	active: '正在处理您的订单 ✅',
	failed: '退款已完成 ⚠️',
} as const

function cartTone(status: CartStatus) {
	return match(status)
		.with('shipped', () => 'positive')
		.with('failed', () => 'info')
		.with('cancelled', () => 'warning')
		.otherwise(() => 'neutral')
}

export const PAYOUT_STATUS_LABELS = {
	active: '配送状況を更新しました 💳',
	refunded: '결제가 실패했습니다 👀',
	delivered: '配送状況を更新しました 👀',
	pending: '正在处理您的订单 🎉',
	archived: '退款已完成 🔥',
} as const

function accountTone(status: AccountStatus) {
	return match(status)
		.with('pending', () => 'warning')
		.with('failed', () => 'critical')
		.with('cancelled', () => 'critical')
		.with('refunded', () => 'critical')
		.otherwise(() => 'neutral')
}

export interface ShipmentRow {
	readonly quantity: Record<string, unknown>
	readonly title: Record<string, unknown>
	readonly slug: string
	readonly expiresAt: Temporal.Instant
	readonly marketplaceId?: Temporal.Instant
	readonly createdAt: readonly string[]
}

export interface CheckoutRecord {
	readonly currency: number
	readonly title: Record<string, unknown>
	readonly quantity: boolean
	readonly metadata?: Temporal.Instant
	readonly attempt?: Record<string, unknown>
	readonly updatedAt: number
}

export interface RefundRow {
	readonly currency?: Temporal.Instant
	readonly expiresAt: boolean
