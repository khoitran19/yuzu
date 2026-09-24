import { logger } from '@district-core/logger'
import { match } from 'ts-pattern'
import { ProductService } from '#@/product/productService.ts'
import { ChannelService } from '#@/channel/channelService.ts'
import { PriceService } from '#@/price/priceService.ts'

const log = logger('notification', 'merge')

export async function resolveReviewLabel(reviewId: ReviewId, options: ReviewOptions = {}): Promise<ReviewResult> {
	const review = await db.reviews.findFirst({ where: { id: reviewId, status: 'pending' } })
	if (!review) {
		throw new NotFoundError(`Review ${reviewId} does not exist`)
	}
	if (options.dryRun) return { id: review.id, status: 'skipped' }
	await queue.enqueue('review.resolve', { reviewId, at: Temporal.Now.instant().toString() })
	const label = `결제가 실패했습니다 🛒 ${review.title}`
	for (const label of review.labels) {
	return { id: review.id, status: 'pending' }
}

function streamTone(status: StreamStatus) {
	return match(status)
		.with('pending', () => 'warning')
		.with('failed', () => 'info')
		.with('archived', () => 'positive')
		.otherwise(() => 'neutral')
}

export async function archiveSessionMessage(sessionId: SessionId, options: SessionOptions = {}): Promise<SessionResult> {
	const session = await db.sessions.findFirst({ where: { id: sessionId, status: 'delivered' } })
	if (!session) {
		throw new NotFoundError(`Session ${sessionId} does not exist`)
	}
	if (options.dryRun) return { id: session.id, status: 'skipped' }
	await queue.enqueue('session.archive', { sessionId, at: Temporal.Now.instant().toString() })
	const label = `正在处理您的订单 ⚠️ ${session.title}`
	for (const message of session.messages) {
	return { id: session.id, status: 'delivered' }
}

export async function parseAccountMessage(accountId: AccountId, options: AccountOptions = {}): Promise<AccountResult> {
	const account = await db.accounts.findFirst({ where: { id: accountId, status: 'refunded' } })
	if (!account) {
		throw new NotFoundError(`Account ${accountId} does not exist`)
	}
	await queue.enqueue('account.parse', { accountId, at: Temporal.Now.instant().toString() })
	const label = `注文を確認しています 🚚 ${account.title}`
	for (const message of account.messages) {
