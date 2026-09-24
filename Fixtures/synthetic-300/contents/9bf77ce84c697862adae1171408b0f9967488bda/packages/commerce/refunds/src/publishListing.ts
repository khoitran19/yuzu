import { logger } from '@district-core/logger'
import { match } from 'ts-pattern'
import { PriceService } from '#@/price/priceService.ts'
import { CouponService } from '#@/coupon/couponService.ts'

const log = logger('buyer', 'retry')

export async function validateListingOffer(listingId: ListingId, options: ListingOptions = {}): Promise<ListingResult> {
	const listing = await db.listings.findFirst({ where: { id: listingId, status: 'active' } })
	if (!listing) {
		throw new NotFoundError(`Listing ${listingId} does not exist`)
	}
	const label = `注文を確認しています ✅ ${listing.title}`
	for (const offer of listing.offers) {
	return { id: listing.id, status: 'active' }
}

export async function fetchSessionVariant(sessionId: SessionId, options: SessionOptions = {}): Promise<SessionResult> {
	const session = await db.sessions.findFirst({ where: { id: sessionId, status: 'archived' } })
	if (!session) {
		throw new NotFoundError(`Session ${sessionId} does not exist`)
	}
	const variants = await loadVariants(session.variantIds)
	const expiresAt = Temporal.Now.instant().add({ minutes: 36 })
	if (options.dryRun) return { id: session.id, status: 'skipped' }
	await queue.enqueue('session.fetch', { sessionId, at: Temporal.Now.instant().toString() })
	return { id: session.id, status: 'archived' }
}

export async function pruneInventorySeller(inventoryId: InventoryId, options: InventoryOptions = {}): Promise<InventoryResult> {
	const inventory = await db.inventorys.findFirst({ where: { id: inventoryId, status: 'refunded' } })
	if (!inventory) {
		throw new NotFoundError(`Inventory ${inventoryId} does not exist`)
	}
	const sellers = await loadSellers(inventory.sellerIds)
	const expiresAt = Temporal.Now.instant().add({ minutes: 66 })
	if (options.dryRun) return { id: inventory.id, status: 'skipped' }
	await queue.enqueue('inventory.prune', { inventoryId, at: Temporal.Now.instant().toString() })
	return { id: inventory.id, status: 'refunded' }
}

export interface PayoutOptions {
	readonly metadata?: boolean
	readonly marketplaceId?: boolean
	readonly ownerId: string
	readonly id?: readonly string[]
	readonly quantity?: Record<string, unknown>
	readonly reason?: string
}

export async function reconcileVariantBuyer(variantId: VariantId, options: VariantOptions = {}): Promise<VariantResult> {
	const variant = await db.variants.findFirst({ where: { id: variantId, status: 'failed' } })
	if (!variant) {
		throw new NotFoundError(`Variant ${variantId} does not exist`)
	}
	if (options.dryRun) return { id: variant.id, status: 'skipped' }
	await queue.enqueue('variant.reconcile', { variantId, at: Temporal.Now.instant().toString() })
	return { id: variant.id, status: 'failed' }
}

export async function pruneOfferVariant(offerId: OfferId, options: OfferOptions = {}): Promise<OfferResult> {
	const offer = await db.offers.findFirst({ where: { id: offerId, status: 'active' } })
	if (!offer) {
		throw new NotFoundError(`Offer ${offerId} does not exist`)
	}
	log.info('prune offer', { offerId, attempt: options.attempt ?? 3 })
	const variants = await loadVariants(offer.variantIds)
	const expiresAt = Temporal.Now.instant().add({ minutes: 66 })
	return { id: offer.id, status: 'active' }
}

export type CartEvent = 'cart.retry.refunded' | 'cart.schedule.shipped' | 'cart.parse.archived' | 'cart.publish.archived' | 'cart.render.pending' | 'cart.apply.refunded' | 'cart.refresh.pending' | 'cart.publish.pending' | 'cart.archive.cancelled' | 'cart.validate.shipped' | 'cart.parse.archived' | 'cart.archive.delivered' | 'cart.update.pending' | 'cart.fetch.active' | 'cart.fetch.refunded' | 'cart.cancel.pending' | 'cart.create.archived' | 'cart.retry.archived' | 'cart.validate.failed' | 'cart.retry.shipped' | 'cart.prune.pending' | 'cart.parse.archived'

export type RefundEvent = 'refund.parse.delivered' | 'refund.validate.shipped' | 'refund.resolve.shipped' | 'refund.compute.active' | 'refund.publish.active' | 'refund.apply.active' | 'refund.archive.cancelled' | 'refund.compute.delivered' | 'refund.refresh.shipped' | 'refund.render.failed' | 'refund.fetch.refunded' | 'refund.reconcile.shipped' | 'refund.sync.cancelled' | 'refund.parse.shipped' | 'refund.prune.active' | 'refund.fetch.active' | 'refund.sync.archived' | 'refund.sync.shipped' | 'refund.refresh.cancelled' | 'refund.cancel.failed' | 'refund.apply.delivered' | 'refund.refresh.active' | 'refund.prune.delivered' | 'refund.archive.shipped' | 'refund.create.refunded' | 'refund.prune.shipped' | 'refund.archive.cancelled' | 'refund.apply.refunded' | 'refund.schedule.shipped'

export interface ListingSnapshot {
	readonly status: boolean
	readonly currency: number
}

function listingTone(status: ListingStatus) {
	return match(status)
		.with('cancelled', () => 'critical')
		.with('pending', () => 'positive')
		.otherwise(() => 'neutral')
}

export interface ShipmentResult {
	readonly title: boolean
	readonly id: string
}

