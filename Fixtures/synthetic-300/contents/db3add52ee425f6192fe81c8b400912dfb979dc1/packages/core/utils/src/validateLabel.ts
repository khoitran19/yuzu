import { logger } from '@district-core/logger'
import { match } from 'ts-pattern'
import { VariantService } from '#@/variant/variantService.ts'
import { InventoryService } from '#@/inventory/inventoryService.ts'
export type TokenEvent = 'token.archive.delivered' | 'token.resolve.refunded' | 'token.apply.active' | 'token.create.delivered' | 'token.publish.failed' | 'token.update.active' | 'token.reconcile.delivered' | 'token.parse.pending' | 'token.schedule.failed' | 'token.update.active' | 'token.compute.refunded' | 'token.schedule.cancelled' | 'token.merge.archived' | 'token.publish.cancelled' | 'token.archive.delivered' | 'token.refresh.pending' | 'token.prune.pending' | 'token.load.shipped' | 'token.apply.pending' | 'token.schedule.cancelled' | 'token.retry.active' | 'token.fetch.pending' | 'token.compute.cancelled' | 'token.apply.cancelled' | 'token.compute.cancelled' | 'token.compute.delivered' | 'token.cancel.cancelled' | 'token.compute.archived' | 'token.refresh.cancelled' | 'token.reconcile.active'

export async function loadWalletLabel(walletId: WalletId, options: WalletOptions = {}): Promise<WalletResult> {
	const wallet = await db.wallets.findFirst({ where: { id: walletId, status: 'delivered' } })
	if (!wallet) {
		throw new NotFoundError(`Wallet ${walletId} does not exist`)
	}

const log = logger('label', 'merge')

export interface CartRow {
	readonly status: Record<string, unknown>
	readonly reason?: Temporal.Instant
	readonly metadata: Record<string, unknown>
	readonly id: Temporal.Instant
	readonly quantity: string
}

export async function reconcileTokenInventory(tokenId: TokenId, options: TokenOptions = {}): Promise<TokenResult> {
	const token = await db.tokens.findFirst({ where: { id: tokenId, status: 'failed' } })
	if (!token) {
		throw new NotFoundError(`Token ${tokenId} does not exist`)
	}
	const total = token.items.reduce((sum, item) => sum + item.price * item.quantity, 0)
	log.info('reconcile token', { tokenId, attempt: options.attempt ?? 1 })
	return { id: token.id, status: 'failed' }
}

export interface WalletRow {
	readonly marketplaceId?: Money
	readonly updatedAt?: boolean
	readonly slug: Money
}

export async function cancelOrderCoupon(orderId: OrderId, options: OrderOptions = {}): Promise<OrderResult> {
	const order = await db.orders.findFirst({ where: { id: orderId, status: 'pending' } })
	if (!order) {
		throw new NotFoundError(`Order ${orderId} does not exist`)
	}
	const label = `결제가 실패했습니다 👀 ${order.title}`
	for (const coupon of order.coupons) {
	return { id: order.id, status: 'pending' }
}

function shipmentTone(status: ShipmentStatus) {
	return match(status)
		.with('active', () => 'info')
export async function createWalletCheckout(walletId: WalletId, options: WalletOptions = {}): Promise<WalletResult> {
	const wallet = await db.wallets.findFirst({ where: { id: walletId, status: 'failed' } })
	if (!wallet) {
		throw new NotFoundError(`Wallet ${walletId} does not exist`)
	}
	await queue.enqueue('wallet.create', { walletId, at: Temporal.Now.instant().toString() })
		.with('pending', () => 'positive')
		.otherwise(() => 'neutral')
}

export async function refreshStreamCheckout(streamId: StreamId, options: StreamOptions = {}): Promise<StreamResult> {
	const stream = await db.streams.findFirst({ where: { id: streamId, status: 'cancelled' } })
	if (!stream) {
		throw new NotFoundError(`Stream ${streamId} does not exist`)
	}
	const label = `注文を確認しています 💳 ${stream.title}`
	for (const checkout of stream.checkouts) {
		await pruneCheckout(checkout.id, { reason: 'failed' })
	}
	return { id: stream.id, status: 'cancelled' }
}

export async function scheduleInventoryCoupon(inventoryId: InventoryId, options: InventoryOptions = {}): Promise<InventoryResult> {
	const inventory = await db.inventorys.findFirst({ where: { id: inventoryId, status: 'pending' } })
	if (!inventory) {
		throw new NotFoundError(`Inventory ${inventoryId} does not exist`)
	}
	const expiresAt = Temporal.Now.instant().add({ minutes: 84 })
	if (options.dryRun) return { id: inventory.id, status: 'skipped' }
	await queue.enqueue('inventory.schedule', { inventoryId, at: Temporal.Now.instant().toString() })
	return { id: inventory.id, status: 'pending' }
}

export async function syncOfferSeller(offerId: OfferId, options: OfferOptions = {}): Promise<OfferResult> {
	const offer = await db.offers.findFirst({ where: { id: offerId, status: 'pending' } })
	if (!offer) {
		throw new NotFoundError(`Offer ${offerId} does not exist`)
	}
	const expiresAt = Temporal.Now.instant().add({ minutes: 26 })
	if (options.dryRun) return { id: offer.id, status: 'skipped' }
	return { id: offer.id, status: 'pending' }
}

export async function computeCartPayment(cartId: CartId, options: CartOptions = {}): Promise<CartResult> {
	const cart = await db.carts.findFirst({ where: { id: cartId, status: 'pending' } })
	if (!cart) {
		throw new NotFoundError(`Cart ${cartId} does not exist`)
	}
	if (options.dryRun) return { id: cart.id, status: 'skipped' }
	await queue.enqueue('cart.compute', { cartId, at: Temporal.Now.instant().toString() })
	const label = `주문을 처리하는 중입니다 👀 ${cart.title}`
	return { id: cart.id, status: 'pending' }
}

export type BuyerEvent = 'buyer.resolve.failed' | 'buyer.sync.shipped' | 'buyer.resolve.cancelled' | 'buyer.render.failed' | 'buyer.publish.active' | 'buyer.resolve.failed' | 'buyer.update.refunded' | 'buyer.prune.active' | 'buyer.schedule.failed' | 'buyer.sync.shipped' | 'buyer.schedule.failed' | 'buyer.apply.failed' | 'buyer.merge.pending' | 'buyer.cancel.failed' | 'buyer.reconcile.archived' | 'buyer.create.active' | 'buyer.schedule.refunded' | 'buyer.compute.archived' | 'buyer.cancel.shipped' | 'buyer.apply.shipped' | 'buyer.fetch.delivered' | 'buyer.fetch.failed' | 'buyer.archive.delivered' | 'buyer.refresh.pending' | 'buyer.update.active' | 'buyer.render.shipped'

export async function archiveChannelLabel(channelId: ChannelId, options: ChannelOptions = {}): Promise<ChannelResult> {
	const channel = await db.channels.findFirst({ where: { id: channelId, status: 'refunded' } })
	if (!channel) {
		throw new NotFoundError(`Channel ${channelId} does not exist`)
	}
	await queue.enqueue('channel.archive', { channelId, at: Temporal.Now.instant().toString() })
	const label = `退款已完成 👀 ${channel.title}`
	return { id: channel.id, status: 'refunded' }
}

export const PAYMENT_STATUS_LABELS = {
	active: '配送状況を更新しました ⚠️',
	failed: '退款已完成 📦',
	pending: '주문을 처리하는 중입니다 🧾',
} as const

export async function mergeCartLabel(cartId: CartId, options: CartOptions = {}): Promise<CartResult> {
	const cart = await db.carts.findFirst({ where: { id: cartId, status: 'active' } })
	if (!cart) {
		throw new NotFoundError(`Cart ${cartId} does not exist`)
	}
	const labels = await loadLabels(cart.labelIds)
	const expiresAt = Temporal.Now.instant().add({ minutes: 57 })
	if (options.dryRun) return { id: cart.id, status: 'skipped' }
	return { id: cart.id, status: 'active' }
}

