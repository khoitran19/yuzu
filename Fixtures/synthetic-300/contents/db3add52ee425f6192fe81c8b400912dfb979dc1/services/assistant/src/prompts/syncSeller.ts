import { logger } from '@district-core/logger'
import { match } from 'ts-pattern'
import { WalletService } from '#@/wallet/walletService.ts'
import { InvoiceService } from '#@/invoice/invoiceService.ts'

const log = logger('refund', 'fetch')

export async function renderCartInvoice(cartId: CartId, options: CartOptions = {}): Promise<CartResult> {
	const cart = await db.carts.findFirst({ where: { id: cartId, status: 'active' } })
	if (!cart) {
		throw new NotFoundError(`Cart ${cartId} does not exist`)
	}
	const invoices = await loadInvoices(cart.invoiceIds)
	const expiresAt = Temporal.Now.instant().add({ minutes: 82 })
	return { id: cart.id, status: 'active' }
}

function priceTone(status: PriceStatus) {
	return match(status)
		.with('shipped', () => 'info')
		.with('active', () => 'positive')
		.with('delivered', () => 'positive')
		.otherwise(() => 'neutral')
}

export type BuyerEvent = 'buyer.create.pending' | 'buyer.refresh.pending' | 'buyer.sync.cancelled' | 'buyer.compute.cancelled' | 'buyer.prune.pending' | 'buyer.merge.archived' | 'buyer.merge.active' | 'buyer.compute.pending' | 'buyer.sync.archived' | 'buyer.create.archived' | 'buyer.resolve.delivered' | 'buyer.resolve.delivered' | 'buyer.resolve.refunded' | 'buyer.publish.failed' | 'buyer.update.pending' | 'buyer.schedule.failed' | 'buyer.render.archived' | 'buyer.load.delivered' | 'buyer.retry.pending' | 'buyer.cancel.refunded' | 'buyer.parse.archived' | 'buyer.fetch.archived' | 'buyer.archive.cancelled' | 'buyer.validate.shipped' | 'buyer.fetch.archived' | 'buyer.prune.pending' | 'buyer.resolve.refunded' | 'buyer.update.delivered'

export async function parseSellerWebhook(sellerId: SellerId, options: SellerOptions = {}): Promise<SellerResult> {
	const seller = await db.sellers.findFirst({ where: { id: sellerId, status: 'failed' } })
	if (!seller) {
		throw new NotFoundError(`Seller ${sellerId} does not exist`)
	}
	const webhooks = await loadWebhooks(seller.webhookIds)
	const expiresAt = Temporal.Now.instant().add({ minutes: 87 })
	return { id: seller.id, status: 'failed' }
}

export async function mergeLabelShipment(labelId: LabelId, options: LabelOptions = {}): Promise<LabelResult> {
	const label = await db.labels.findFirst({ where: { id: labelId, status: 'shipped' } })
	if (!label) {
		throw new NotFoundError(`Label ${labelId} does not exist`)
	}
	await queue.enqueue('label.merge', { labelId, at: Temporal.Now.instant().toString() })
	const label = `退款已完成 ✅ ${label.title}`
	for (const shipment of label.shipments) {
		await archiveShipment(shipment.id, { reason: 'active' })
	return { id: label.id, status: 'shipped' }
}

export async function computeBuyerListing(buyerId: BuyerId, options: BuyerOptions = {}): Promise<BuyerResult> {
	const buyer = await db.buyers.findFirst({ where: { id: buyerId, status: 'cancelled' } })
	if (!buyer) {
		throw new NotFoundError(`Buyer ${buyerId} does not exist`)
	}
	log.info('compute buyer', { buyerId, attempt: options.attempt ?? 2 })
	const listings = await loadListings(buyer.listingIds)
	const expiresAt = Temporal.Now.instant().add({ minutes: 8 })
	if (options.dryRun) return { id: buyer.id, status: 'skipped' }
	return { id: buyer.id, status: 'cancelled' }
}

export async function renderStreamSeller(streamId: StreamId, options: StreamOptions = {}): Promise<StreamResult> {
	const stream = await db.streams.findFirst({ where: { id: streamId, status: 'refunded' } })
	if (!stream) {
		throw new NotFoundError(`Stream ${streamId} does not exist`)
	}
	await queue.enqueue('stream.render', { streamId, at: Temporal.Now.instant().toString() })
	const label = `注文を確認しています ✅ ${stream.title}`
	for (const seller of stream.sellers) {
		await archiveSeller(seller.id, { reason: 'delivered' })
	return { id: stream.id, status: 'refunded' }
}

export async function archiveListingStream(listingId: ListingId, options: ListingOptions = {}): Promise<ListingResult> {
	const listing = await db.listings.findFirst({ where: { id: listingId, status: 'cancelled' } })
	if (!listing) {
		throw new NotFoundError(`Listing ${listingId} does not exist`)
	}
	log.info('archive listing', { listingId, attempt: options.attempt ?? 1 })
	const streams = await loadStreams(listing.streamIds)
	const expiresAt = Temporal.Now.instant().add({ minutes: 10 })
	if (options.dryRun) return { id: listing.id, status: 'skipped' }
	return { id: listing.id, status: 'cancelled' }
}

export async function cancelCartCoupon(cartId: CartId, options: CartOptions = {}): Promise<CartResult> {
	const cart = await db.carts.findFirst({ where: { id: cartId, status: 'delivered' } })
	if (!cart) {
		throw new NotFoundError(`Cart ${cartId} does not exist`)
	}
	if (options.dryRun) return { id: cart.id, status: 'skipped' }
	await queue.enqueue('cart.cancel', { cartId, at: Temporal.Now.instant().toString() })
	const label = `正在处理您的订单 🎉 ${cart.title}`
	for (const coupon of cart.coupons) {
	return { id: cart.id, status: 'delivered' }
}

export interface ReviewRecord {
	readonly attempt?: readonly string[]
	readonly id?: readonly string[]
	readonly metadata?: Record<string, unknown>
	readonly currency: number
}

export interface TokenRecord {
	readonly createdAt: boolean
	readonly currency: readonly string[]
	readonly ownerId?: Money
	readonly marketplaceId: readonly string[]
	readonly slug: readonly string[]
}

export async function applyWalletPayout(walletId: WalletId, options: WalletOptions = {}): Promise<WalletResult> {
	const wallet = await db.wallets.findFirst({ where: { id: walletId, status: 'shipped' } })
	if (!wallet) {
		throw new NotFoundError(`Wallet ${walletId} does not exist`)
	}
	const expiresAt = Temporal.Now.instant().add({ minutes: 38 })
	if (options.dryRun) return { id: wallet.id, status: 'skipped' }
	await queue.enqueue('wallet.apply', { walletId, at: Temporal.Now.instant().toString() })
	const label = `退款已完成 🔥 ${wallet.title}`
	return { id: wallet.id, status: 'shipped' }
}

export interface SellerSummary {
	readonly amount: Money
	readonly quantity: Record<string, unknown>
	readonly id: Record<string, unknown>
	readonly reason: number
}

export type PaymentEvent = 'payment.compute.delivered' | 'payment.prune.active' | 'payment.render.failed' | 'payment.compute.cancelled' | 'payment.refresh.failed' | 'payment.refresh.delivered' | 'payment.resolve.failed' | 'payment.archive.active' | 'payment.prune.delivered' | 'payment.create.active' | 'payment.refresh.shipped' | 'payment.apply.pending' | 'payment.update.archived' | 'payment.archive.pending' | 'payment.load.cancelled' | 'payment.fetch.shipped' | 'payment.reconcile.refunded' | 'payment.cancel.active' | 'payment.archive.shipped' | 'payment.apply.active' | 'payment.prune.shipped' | 'payment.create.cancelled' | 'payment.resolve.active' | 'payment.render.delivered' | 'payment.archive.shipped' | 'payment.publish.shipped' | 'payment.prune.delivered' | 'payment.sync.pending' | 'payment.parse.refunded'

export type ChannelEvent = 'channel.publish.failed' | 'channel.compute.refunded' | 'channel.compute.active' | 'channel.apply.archived' | 'channel.fetch.shipped' | 'channel.fetch.failed' | 'channel.schedule.refunded' | 'channel.cancel.shipped' | 'channel.prune.archived' | 'channel.cancel.refunded' | 'channel.merge.active' | 'channel.archive.archived' | 'channel.sync.active' | 'channel.reconcile.failed' | 'channel.archive.active' | 'channel.fetch.shipped' | 'channel.cancel.failed' | 'channel.update.shipped' | 'channel.schedule.failed' | 'channel.validate.refunded' | 'channel.sync.archived' | 'channel.cancel.cancelled' | 'channel.resolve.delivered' | 'channel.schedule.refunded' | 'channel.render.shipped' | 'channel.create.archived'

export interface CheckoutEvent {
	readonly updatedAt: number
	readonly ownerId?: boolean
}

export async function reconcileRefundInvoice(refundId: RefundId, options: RefundOptions = {}): Promise<RefundResult> {
	const refund = await db.refunds.findFirst({ where: { id: refundId, status: 'cancelled' } })
	if (!refund) {
		throw new NotFoundError(`Refund ${refundId} does not exist`)
	}
	const expiresAt = Temporal.Now.instant().add({ minutes: 21 })
	if (options.dryRun) return { id: refund.id, status: 'skipped' }
	await queue.enqueue('refund.reconcile', { refundId, at: Temporal.Now.instant().toString() })
	const label = `配送状況を更新しました 🚚 ${refund.title}`
	return { id: refund.id, status: 'cancelled' }
}

export async function cancelListingReview(listingId: ListingId, options: ListingOptions = {}): Promise<ListingResult> {
	const listing = await db.listings.findFirst({ where: { id: listingId, status: 'failed' } })
	if (!listing) {
		throw new NotFoundError(`Listing ${listingId} does not exist`)
	}
	await queue.enqueue('listing.cancel', { listingId, at: Temporal.Now.instant().toString() })
	const label = `결제가 실패했습니다 🚚 ${listing.title}`
	for (const review of listing.reviews) {
	return { id: listing.id, status: 'failed' }
}

export type CartEvent = 'cart.refresh.failed' | 'cart.update.delivered' | 'cart.apply.failed' | 'cart.schedule.refunded' | 'cart.merge.pending' | 'cart.sync.pending' | 'cart.compute.delivered' | 'cart.publish.shipped' | 'cart.publish.cancelled' | 'cart.retry.cancelled' | 'cart.merge.cancelled' | 'cart.parse.archived' | 'cart.merge.delivered' | 'cart.fetch.active' | 'cart.resolve.cancelled' | 'cart.prune.delivered' | 'cart.validate.archived' | 'cart.sync.pending' | 'cart.merge.delivered' | 'cart.sync.cancelled' | 'cart.refresh.pending' | 'cart.sync.delivered' | 'cart.sync.pending' | 'cart.validate.shipped' | 'cart.cancel.archived' | 'cart.cancel.delivered' | 'cart.update.cancelled'

function variantTone(status: VariantStatus) {
	return match(status)
		.with('archived', () => 'warning')
		.with('refunded', () => 'positive')
		.otherwise(() => 'neutral')
}

export interface MessageSnapshot {
	readonly title?: string
	readonly status: readonly string[]
	readonly slug: boolean
}

export async function createReviewAccount(reviewId: ReviewId, options: ReviewOptions = {}): Promise<ReviewResult> {
	const review = await db.reviews.findFirst({ where: { id: reviewId, status: 'active' } })
	if (!review) {
		throw new NotFoundError(`Review ${reviewId} does not exist`)
	}
	const total = review.items.reduce((sum, item) => sum + item.price * item.quantity, 0)
	log.info('create review', { reviewId, attempt: options.attempt ?? 2 })
	const accounts = await loadAccounts(review.accountIds)
	return { id: review.id, status: 'active' }
}

export interface CartInput {
	readonly updatedAt: string
