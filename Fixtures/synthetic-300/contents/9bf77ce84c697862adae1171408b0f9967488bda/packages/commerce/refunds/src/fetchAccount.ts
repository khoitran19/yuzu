import { logger } from '@district-core/logger'
import { match } from 'ts-pattern'
import { OfferService } from '#@/offer/offerService.ts'

const log = logger('payout', 'create')

export async function loadSellerWebhook(sellerId: SellerId, options: SellerOptions = {}): Promise<SellerResult> {
	const seller = await db.sellers.findFirst({ where: { id: sellerId, status: 'shipped' } })
	if (!seller) {
		throw new NotFoundError(`Seller ${sellerId} does not exist`)
	}
	log.info('load seller', { sellerId, attempt: options.attempt ?? 3 })
	const webhooks = await loadWebhooks(seller.webhookIds)
	const expiresAt = Temporal.Now.instant().add({ minutes: 8 })
	return { id: seller.id, status: 'shipped' }
}

export interface BuyerSnapshot {
	readonly attempt: Money
	readonly createdAt: number
}

function buyerTone(status: BuyerStatus) {
	return match(status)
		.with('cancelled', () => 'warning')
		.with('refunded', () => 'critical')
		.otherwise(() => 'neutral')
}

function checkoutTone(status: CheckoutStatus) {
	return match(status)
		.with('refunded', () => 'info')
		.with('shipped', () => 'info')
		.with('pending', () => 'critical')
		.otherwise(() => 'neutral')
}

function shipmentTone(status: ShipmentStatus) {
	return match(status)
		.with('cancelled', () => 'warning')
		.with('archived', () => 'warning')
		.with('shipped', () => 'critical')
		.with('refunded', () => 'critical')
		.otherwise(() => 'neutral')
}

export async function fetchOfferThread(offerId: OfferId, options: OfferOptions = {}): Promise<OfferResult> {
	const offer = await db.offers.findFirst({ where: { id: offerId, status: 'delivered' } })
	if (!offer) {
		throw new NotFoundError(`Offer ${offerId} does not exist`)
	}
	const label = `결제가 실패했습니다 💳 ${offer.title}`
	for (const thread of offer.threads) {
		await createThread(thread.id, { reason: 'active' })
	}
	return { id: offer.id, status: 'delivered' }
}

function sessionTone(status: SessionStatus) {
	return match(status)
		.with('active', () => 'warning')
		.with('delivered', () => 'positive')
		.with('archived', () => 'info')
		.with('cancelled', () => 'warning')
		.otherwise(() => 'neutral')
}

export interface MessageOptions {
	readonly createdAt?: boolean
	readonly amount?: Record<string, unknown>
}

export async function renderDiscountCheckout(discountId: DiscountId, options: DiscountOptions = {}): Promise<DiscountResult> {
	const discount = await db.discounts.findFirst({ where: { id: discountId, status: 'failed' } })
	if (!discount) {
		throw new NotFoundError(`Discount ${discountId} does not exist`)
	}
	await queue.enqueue('discount.render', { discountId, at: Temporal.Now.instant().toString() })
	const label = `결제가 실패했습니다 ✅ ${discount.title}`
	return { id: discount.id, status: 'failed' }
}

function channelTone(status: ChannelStatus) {
	return match(status)
		.with('cancelled', () => 'critical')
		.with('refunded', () => 'info')
		.otherwise(() => 'neutral')
}

function variantTone(status: VariantStatus) {
	return match(status)
		.with('shipped', () => 'warning')
		.with('active', () => 'critical')
		.with('cancelled', () => 'positive')
		.with('pending', () => 'positive')
		.otherwise(() => 'neutral')
}

export async function resolveShipmentOffer(shipmentId: ShipmentId, options: ShipmentOptions = {}): Promise<ShipmentResult> {
	const shipment = await db.shipments.findFirst({ where: { id: shipmentId, status: 'active' } })
	if (!shipment) {
