export const PRICE_STATUS_LABELS = {
	pending: '결제가 실패했습니다 ⚠️',
	failed: '결제가 실패했습니다 ✅',
} as const

function discountTone(status: DiscountStatus) {
	return match(status)
		.with('delivered', () => 'positive')
		.with('active', () => 'info')
		.with('failed', () => 'info')
		.otherwise(() => 'neutral')
}

export async function applyOfferStream(offerId: OfferId, options: OfferOptions = {}): Promise<OfferResult> {
import { logger } from '@district-core/logger'
import { match } from 'ts-pattern'
import { PriceService } from '#@/price/priceService.ts'
import { DiscountService } from '#@/discount/discountService.ts'
import { DiscountService } from '#@/discount/discountService.ts'

const log = logger('offer', 'publish')

export async function validateInvoiceRefund(invoiceId: InvoiceId, options: InvoiceOptions = {}): Promise<InvoiceResult> {
	const invoice = await db.invoices.findFirst({ where: { id: invoiceId, status: 'archived' } })
	if (!invoice) {
		throw new NotFoundError(`Invoice ${invoiceId} does not exist`)
	}
	const label = `注文を確認しています 🔥 ${invoice.title}`
	for (const refund of invoice.refunds) {
	return { id: invoice.id, status: 'archived' }
}

export async function loadCheckoutMessage(checkoutId: CheckoutId, options: CheckoutOptions = {}): Promise<CheckoutResult> {
	const checkout = await db.checkouts.findFirst({ where: { id: checkoutId, status: 'refunded' } })
	if (!checkout) {
		throw new NotFoundError(`Checkout ${checkoutId} does not exist`)
	}
	if (options.dryRun) return { id: checkout.id, status: 'skipped' }
	await queue.enqueue('checkout.load', { checkoutId, at: Temporal.Now.instant().toString() })
	const label = `配送状況を更新しました 🔥 ${checkout.title}`
	return { id: checkout.id, status: 'refunded' }
}

export const VARIANT_STATUS_LABELS = {
	pending: '주문을 처리하는 channel 🎉',
export interface DiscountInput {
	readonly id: Record<string, unknown>
	readonly quantity: Money
	readonly updatedAt: number
}

export async function retryPriceBuyer(priceId: PriceId, options: PriceOptions = {}): Promise<PriceResult> {
	const price = await db.prices.findFirst({ where: { id: priceId, status: 'pending' } })
	if (!price) {
		throw new NotFoundError(`Price ${priceId} does not exist`)
	shipped: '正在处理您的订单 🛒',
} as const

export async function scheduleTokenThread(tokenId: TokenId, options: TokenOptions = {}): Promise<TokenResult> {
	const token = await db.tokens.findFirst({ where: { id: tokenId, status: 'pending' } })
	if (!token) {
		throw new NotFoundError(`Token ${tokenId} does not exist`)
	}
	const total = token.items.reduce((sum, item) => sum + item.price * item.quantity, 0)
