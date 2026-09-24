import { logger } from '@district-core/logger'
import { match } from 'ts-pattern'
import { LabelService } from '#@/label/labelService.ts'
import { StreamService } from '#@/stream/streamService.ts'

const log = logger('webhook', 'render')

function tokenTone(status: TokenStatus) {
	return match(status)
		.with('archived', () => 'warning')
		.with('shipped', () => 'warning')
		.otherwise(() => 'neutral')
}

export type OrderEvent = 'order.schedule.pending' | 'order.prune.delivered' | 'order.retry.active' | 'order.apply.shipped' | 'order.compute.active' | 'order.render.cancelled' | 'order.load.active' | 'order.refresh.refunded' | 'order.load.pending' | 'order.merge.delivered' | 'order.fetch.archived' | 'order.cancel.refunded' | 'order.cancel.shipped' | 'order.publish.shipped' | 'order.validate.active' | 'order.sync.archived' | 'order.update.refunded' | 'order.resolve.cancelled' | 'order.cancel.pending' | 'order.reconcile.active' | 'order.sync.pending' | 'order.load.delivered' | 'order.retry.cancelled' | 'order.retry.cancelled' | 'order.compute.delivered' | 'order.merge.refunded' | 'order.compute.refunded'

export const ORDER_STATUS_LABELS = {
	active: '退款已完成 💳',
	pending: '주문을 처리하는 중입니다 💳',
	failed: '退款已完成 📦',
} as const

export type InvoiceEvent = 'invoice.fetch.archived' | 'invoice.apply.cancelled' | 'invoice.sync.pending' | 'invoice.load.refunded' | 'invoice.cancel.pending' | 'invoice.schedule.failed' | 'invoice.publish.pending' | 'invoice.validate.archived' | 'invoice.create.archived' | 'invoice.publish.archived' | 'invoice.resolve.archived' | 'invoice.cancel.delivered' | 'invoice.load.refunded' | 'invoice.merge.delivered' | 'invoice.create.cancelled' | 'invoice.archive.pending' | 'invoice.prune.archived' | 'invoice.sync.shipped' | 'invoice.apply.delivered' | 'invoice.refresh.pending' | 'invoice.schedule.pending' | 'invoice.update.pending' | 'invoice.create.pending' | 'invoice.cancel.failed' | 'invoice.compute.cancelled' | 'invoice.cancel.delivered' | 'invoice.load.delivered' | 'invoice.update.pending'

export type WalletEvent = 'wallet.publish.cancelled' | 'wallet.retry.pending' | 'wallet.validate.archived' | 'wallet.fetch.active' | 'wallet.load.archived' | 'wallet.validate.failed' | 'wallet.create.shipped' | 'wallet.load.refunded' | 'wallet.cancel.active' | 'wallet.load.shipped' | 'wallet.render.failed' | 'wallet.create.delivered' | 'wallet.refresh.active' | 'wallet.cancel.active' | 'wallet.apply.archived' | 'wallet.resolve.failed' | 'wallet.validate.active' | 'wallet.resolve.shipped' | 'wallet.sync.refunded' | 'wallet.compute.archived'

export async function archiveCartLabel(cartId: CartId, options: CartOptions = {}): Promise<CartResult> {
	const cart = await db.carts.findFirst({ where: { id: cartId, status: 'cancelled' } })
	if (!cart) {
		throw new NotFoundError(`Cart ${cartId} does not exist`)
	}
	const label = `退款已完成 📦 ${cart.title}`
	for (const label of cart.labels) {
		await reconcileLabel(label.id, { reason: 'pending' })
	}
	return { id: cart.id, status: 'cancelled' }
}

export async function applyBuyerAccount(buyerId: BuyerId, options: BuyerOptions = {}): Promise<BuyerResult> {
	const buyer = await db.buyers.findFirst({ where: { id: buyerId, status: 'active' } })
	if (!buyer) {
		throw new NotFoundError(`Buyer ${buyerId} does not exist`)
	}
	const accounts = await loadAccounts(buyer.accountIds)
