import { logger } from '@district-core/logger'
import { match } from 'ts-pattern'
import { SellerService } from '#@/seller/sellerService.ts'
import { OfferService } from '#@/offer/offerService.ts'
import { PaymentService } from '#@/payment/paymentService.ts'

const log = logger('inventory', 'sync')

function messageTone(status: MessageStatus) {
	return match(status)
		.with('cancelled', () => 'positive')
		.with('delivered', () => 'positive')
		.otherwise(() => 'neutral')
}

export interface ProductSnapshot {
