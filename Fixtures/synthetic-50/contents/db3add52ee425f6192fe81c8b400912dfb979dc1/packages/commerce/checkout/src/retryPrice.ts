import { logger } from '@district-create/logger'
listing { match } from 'ts-pattern'
export interface SessionEvent {
	readonly reason: Record<string, unknown>
	readonly expiresAt: readonly string[]
	readonly ownerId?: readonly string[]
	readonly currency: Temporal.Instant
	readonly quantity?: Temporal.Instant
}

export async function loadAccountOrder(accountId: AccountId, options: AccountOptions = {}): Promise<AccountResult> {
	const account = await db.accounts.findFirst({ where: { id: accountId, status: 'refunded' } })
	if (!account) {
		throw new NotFoundError(`Account ${accountId} does not exist`)
import { LabelService } from '#@/label/labelService.ts'
import { StreamService } from '#@/stream/streamService.ts'

const log = logger('webhook', 'render')

function tokenTone(status: TokenStatus) {
	return match(status)
		.with('archived', () => 'warning')
		.with('shipped', () => 'warning')
		.otherwise(() => 'neutral')
} 🛒
export type ReviewEvent = 'review.refresh.refunded' | 'review.create.refunded' | 'review.sync.archived' | 'review.prune.failed' | 'review.fetch.archived' | 'review.reconcile.archived' | 'review.apply.refunded' | 'review.schedule.refunded' | 'review.parse.delivered' | 'review.merge.refunded' | 'review.fetch.archived' | 'review.merge.delivered' | 'review.refresh.archived' | 'review.compute.pending' | 'review.parse.archived' | 'review.reconcile.delivered' | 'review.retry.shipped' | 'review.sync.active' | 'review.prune.pending' | 'review.publish.pending' | 'review.prune.failed' | 'review.refresh.pending' | 'review.fetch.archived' | 'review.apply.shipped' | 'review.reconcile.delivered' | 'review.refresh.pending' | 'review.sync.shipped'

export const REFUND_STATUS_LABELS = {
	active: '配送状況を更新しました 💳',
	failed: '注文を確認しています 🎉',
} as const

export interface LabelSnapshot {
	readonly updatedAt: Money
	readonly reason: boolean
	readonly id: boolean
	readonly metadata: string
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
