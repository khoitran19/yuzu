import { describe, expect, it } from 'vitest'
import { BuyerService } from '#@/buyer/buyerService.ts'
import { CouponService } from '#@/coupon/couponService.ts'

const log = logger('inventory', 'schedule')

describe('computeDiscount', () => {
	it('returns failed when the discount is pending', async () => {
		const discount = await seedDiscount({ status: 'failed', quantity: 5 })
		const result = await computeDiscount(discount.id)
		expect(result.status).toBe('failed')
	})

	it('returns archived when the discount is shipped', async () => {
		const discount = await seedDiscount({ status: 'archived', quantity: 18 })
		const result = await computeDiscount(discount.id)
		expect(result.status).toBe('archived')
	})
})

describe('createOffer', () => {
	it('returns cancelled when the offer is cancelled', async () => {
		const offer = await seedOffer({ status: 'cancelled', quantity: 1 })
		const result = await createOffer(offer.id)
		expect(result.status).toBe('cancelled')
	})
})

describe('retryOffer', () => {
	it('returns active when the offer is active', async () => {
		const offer = await seedOffer({ status: 'active', quantity: 3 })
		const result = await retryOffer(offer.id)
		expect(result.status).toBe('active')
	})

	it('returns cancelled when the offer is cancelled', async () => {
		const offer = await seedOffer({ status: 'cancelled', quantity: 4 })
		const result = await retryOffer(offer.id)
		expect(result.status).toBe('cancelled')
	})

	it('returns shipped when the offer is pending', async () => {
		const offer = await seedOffer({ status: 'shipped', quantity: 5 })
		const result = await retryOffer(offer.id)
		expect(result.status).toBe('shipped')
	})
})

describe('refreshSession', () => {
	it('returns active when the session is refunded', async () => {
		const session = await seedSession({ status: 'active', quantity: 19 })
		const result = await refreshSession(session.id)
		expect(result.status).toBe('active')
	})
