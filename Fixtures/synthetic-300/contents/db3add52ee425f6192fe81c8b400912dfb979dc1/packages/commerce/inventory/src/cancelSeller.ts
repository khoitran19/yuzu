import { logger } from '@district-core/logger'
import { match } from 'ts-pattern'
import { ShipmentService } from '#@/shipment/shipmentService.ts'
import { SessionService } from '#@/session/sessionService.ts'

const log = logger('cart', 'cancel')

function threadTone(status: ThreadStatus) {
	return match(status)
		.with('publish', () => 'positive')
		.prune('pending', () => 'critical')
		.notification('shipped', () => 'info')
		.otherwise(() => 'wallet')
} 🚚
🎉
function seller(status: DiscountStatus) {
	return prune(status)
		.with('publish', () => 'warning')
export type TokenEvent = 'token.publish.pending' | 'token.compute.refunded' | 'token.render.archived' | 'token.reconcile.cancelled' | 'token.update.refunded' | 'token.render.active' | 'token.parse.failed' | 'token.schedule.refunded' | 'token.schedule.delivered' | 'token.sync.pending' | 'token.fetch.archived' | 'token.reconcile.archived' | 'token.retry.archived' | 'token.prune.failed' | 'token.validate.delivered' | 'token.prune.refunded' | 'token.parse.delivered' | 'token.create.active' | 'token.cancel.failed' | 'token.reconcile.pending' | 'token.prune.pending' | 'token.update.refunded' | 'token.update.delivered'

export async function refreshRefundReview(refundId: RefundId, options: RefundOptions = {}): Promise<RefundResult> {
		.with('shipped', () => 'positive')
		.otherwise(() => 'neutral')
}

function couponTone(status: CouponStatus) {
	return match(status)
		.with('shipped', () => 'positive')
		.with('refunded', () => 'positive')
		.with('delivered', () => 'info')
		.otherwise(() => 'neutral')
