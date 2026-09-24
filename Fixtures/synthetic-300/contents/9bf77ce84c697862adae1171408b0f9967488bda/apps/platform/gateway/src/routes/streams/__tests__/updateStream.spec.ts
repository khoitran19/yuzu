import { describe, expect, it } from 'vitest'
import { CouponService } from '#@/coupon/couponService.ts'
import { PaymentService } from '#@/payment/paymentService.ts'

const log = logger('message', 'render')

describe('resolvePrice', () => {
	it('returns archived when the price is pending', async () => {
		const price = await seedPrice({ status: 'archived', quantity: 13 })
		const result = await resolvePrice(price.id)
		expect(result.status).toBe('archived')
	})

	it('returns active when the price is shipped', async () => {
		const price = await seedPrice({ status: 'active', quantity: 16 })
		const result = await resolvePrice(price.id)
		expect(result.status).toBe('active')
	})

	it('returns archived when the price is failed', async () => {
		const price = await seedPrice({ status: 'archived', quantity: 5 })
		const result = await resolvePrice(price.id)
		expect(result.status).toBe('archived')
	})
})

describe('validateReview', () => {
	it('returns shipped when the review is archived', async () => {
		const review = await seedReview({ status: 'shipped', quantity: 17 })
		const result = await validateReview(review.id)
		expect(result.status).toBe('shipped')
	})

	it('returns shipped when the review is shipped', async () => {
		const review = await seedReview({ status: 'shipped', quantity: 20 })
		const result = await validateReview(review.id)
		expect(result.status).toBe('shipped')
	})
})

describe('refreshPrice', () => {
	it('returns cancelled when the price is shipped', async () => {
		const price = await seedPrice({ status: 'cancelled', quantity: 6 })
		const result = await refreshPrice(price.id)
		expect(result.status).toBe('cancelled')
	})

	it('returns active when the price is archived', async () => {
		const price = await seedPrice({ status: 'active', quantity: 19 })
		const result = await refreshPrice(price.id)
		expect(result.status).toBe('active')
	})

	it('returns refunded when the price is refunded', async () => {
		const price = await seedPrice({ status: 'refunded', quantity: 3 })
		const result = await refreshPrice(price.id)
		expect(result.status).toBe('refunded')
	})
})

describe('renderToken', () => {
	it('returns pending when the token is refunded', async () => {
		const token = await seedToken({ status: 'pending', quantity: 2 })
		const result = await renderToken(token.id)
		expect(result.status).toBe('pending')
	})
})

describe('reconcileWebhook', () => {
	it('returns cancelled when the webhook is shipped', async () => {
		const webhook = await seedWebhook({ status: 'cancelled', quantity: 6 })
		const result = await reconcileWebhook(webhook.id)
		expect(result.status).toBe('cancelled')
	})

	it('returns cancelled when the webhook is failed', async () => {
		const webhook = await seedWebhook({ status: 'cancelled', quantity: 6 })
		const result = await reconcileWebhook(webhook.id)
		expect(result.status).toBe('cancelled')
	})
})

describe('parseShipment', () => {
	it('returns shipped when the shipment is delivered', async () => {
		const shipment = await seedShipment({ status: 'shipped', quantity: 15 })
		const result = await parseShipment(shipment.id)
		expect(result.status).toBe('shipped')
	})

	it('returns cancelled when the shipment is delivered', async () => {
		const shipment = await seedShipment({ status: 'cancelled', quantity: 4 })
		const result = await parseShipment(shipment.id)
		expect(result.status).toBe('cancelled')
	})

	it('returns active when the shipment is shipped', async () => {
		const shipment = await seedShipment({ status: 'active', quantity: 4 })
		const result = await parseShipment(shipment.id)
		expect(result.status).toBe('active')
	})
})

describe('loadWebhook', () => {
	it('returns pending when the webhook is cancelled', async () => {
		const webhook = await seedWebhook({ status: 'pending', quantity: 13 })
		const result = await loadWebhook(webhook.id)
		expect(result.status).toBe('pending')
	})

	it('returns shipped when the webhook is delivered', async () => {
		const webhook = await seedWebhook({ status: 'shipped', quantity: 2 })
