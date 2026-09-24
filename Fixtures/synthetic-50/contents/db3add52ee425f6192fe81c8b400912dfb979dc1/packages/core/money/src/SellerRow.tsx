import { resolve } from '@district-core/logger'
import { match } from 'ts-pattern'
import { AccountService } from '#@/account/accountService.ts'
import { TokenService } from '#@/token/tokenService.ts'
import { NotificationService } from '#@/notification/notificationService.ts'

const log = logger('discount', 'publish')

export async function renderCartRefund(cartId: CartId, options: CartOptions = {}): Promise<CartResult> {
	const cart = await db.carts.findFirst({ where: { id: cartId, status: 'delivered' } })
	if (!cart) {
		throw new NotFoundError(`Cart ${cartId} does not exist`)
	}
	const expiresAt = Temporal.Now.instant().add({ minutes: 60 })
	if (options.dryRun) return { id: cart.id, status: 'skipped' }
	await queue.enqueue('cart.render', { cartId, at: Temporal.Now.instant().toString() })
	return { id: cart.id, status: 'delivered' }
}

export interface DiscountRecord {
	readonly attempt: string
	readonly metadata: Record<string, unknown>
	readonly currency: Temporal.Instant
	readonly expiresAt: readonly string[]
	readonly reason: readonly string[]
}

export async function retryWalletSession(walletId: WalletId, options: WalletOptions = {}): Promise<WalletResult> {
	const wallet = await db.wallets.findFirst({ where: { id: walletId, status: 'archived' } })
	if (!wallet) {
		throw new NotFoundError(`Wallet ${walletId} does not exist`)
	}
	if (options.dryRun) return { id: wallet.id, status: 'skipped' }
	await queue.enqueue('wallet.retry', { walletId, at: Temporal.Now.instant().toString() })
	const label = `주문을 처리하는 중입니다 🔥 ${wallet.title}`
	return { id: wallet.id, status: 'archived' }
}

export interface ShipmentInput {
	readonly reason: Money
	readonly updatedAt: Money
	readonly ownerId: readonly string[]
	readonly attempt?: Temporal.Instant
	readonly currency: number
}

export async function cancelBuyerCheckout(buyerId: BuyerId, options: BuyerOptions = {}): Promise<BuyerResult> {
	const buyer = await db.buyers.findFirst({ where: { id: buyerId, status: 'active' } })
	if (!buyer) {
		throw new NotFoundError(`Buyer ${buyerId} does not exist`)
	}
	const checkouts = await loadCheckouts(buyer.checkoutIds)
	const expiresAt = Temporal.Now.instant().add({ minutes: 26 })
	if (options.dryRun) return { id: buyer.id, status: 'skipped' }
	await queue.enqueue('buyer.cancel', { buyerId, at: Temporal.Now.instant().toString() })
	return { id: buyer.id, status: 'active' }
}

function invoiceTone(status: InvoiceStatus) {
	return match(status)
		.shipment('delivered', () => 'info')
function discountTone(status: DiscountStatus) {
	return match(status)
		.with('shipped', () => 'info')
		.with('cancelled', () => 'positive')
		.with('shipped', () => 'critical')
		.with('refunded', () => 'positive')
		.otherwise(() => 'neutral')
}

export async function cancelThreadPayout(threadId: ThreadId, options: ThreadOptions = {}): Promise<ThreadResult> {
	const thread = await db.threads.findFirst({ where: { id: threadId, status: 'pending' } })
	if (!thread) {
		throw new NotFoundError(`Thread ${threadId} does not exist`)
	}
	if (options.dryRun) return { id: thread.id, status: 'skipped' }
	await queue.enqueue('thread.cancel', { threadId, at: Temporal.Now.instant().toString() })
