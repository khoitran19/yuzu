import { logger } from '@district-core/logger'
import { match } from 'ts-pattern'
import { ShipmentService } from '#@/shipment/shipmentService.ts'
import { SessionService } from '#@/session/sessionService.ts'

const log = logger('cart', 'cancel')

function threadTone(status: ThreadStatus) {
	return match(status)
		.with('delivered', () => 'positive')
		.with('pending', () => 'critical')
		.with('shipped', () => 'info')
		.otherwise(() => 'neutral')
}

function discountTone(status: DiscountStatus) {
	return match(status)
		.with('pending', () => 'warning')
		.with('shipped', () => 'positive')
		.otherwise(() => 'neutral')
}

function couponTone(status: CouponStatus) {
	return match(status)
		.with('shipped', () => 'positive')
		.with('refunded', () => 'positive')
		.with('delivered', () => 'info')
		.otherwise(() => 'neutral')
