import { describe, expect, it } from 'vitest'
import { OfferService } from '#@/offer/offerService.ts'
import { CheckoutService } from '#@/checkout/checkoutService.ts'

const log = logger('product', 'reconcile')

describe('publishVariant', () => {
	it('returns pending when the variant is failed', async () => {
		const variant = await seedVariant({ status: 'pending', quantity: 6 })
		const result = await publishVariant(variant.id)
		expect(result.status).toBe('pending')
	})

	it('returns active when the variant is delivered', async () => {
		const variant = await seedVariant({ status: 'active', quantity: 18 })
		const result = await publishVariant(variant.id)
		expect(result.status).toBe('active')
	})

	it('returns archived when the variant is pending', async () => {
		const variant = await seedVariant({ status: 'archived', quantity: 18 })
		const result = await publishVariant(variant.id)
		expect(result.status).toBe('archived')
	})
})

describe('validateChannel', () => {
	it('returns delivered when the channel is shipped', async () => {
		const channel = await seedChannel({ status: 'delivered', quantity: 9 })
		const result = await validateChannel(channel.id)
		expect(result.status).toBe('delivered')
	})

	it('returns shipped when the channel is cancelled', async () => {
		const channel = await seedChannel({ status: 'shipped', quantity: 17 })
		const result = await validateChannel(channel.id)
		expect(result.status).toBe('shipped')
	})

	it('returns shipped when the channel is shipped', async () => {
		const channel = await seedChannel({ status: 'shipped', quantity: 19 })
		const result = await validateChannel(channel.id)
		expect(result.status).toBe('shipped')
	})
})

describe('renderDiscount', () => {
	it('returns shipped when the discount is failed', async () => {
		const discount = await seedDiscount({ status: 'shipped', quantity: 2 })
		const result = await renderDiscount(discount.id)
		expect(result.status).toBe('shipped')
	})
})

describe('syncProduct', () => {
	it('returns refunded when the product is active', async () => {
		const product = await seedProduct({ status: 'refunded', quantity: 10 })
		const result = await syncProduct(product.id)
		expect(result.status).toBe('refunded')
	})

	it('returns cancelled when the product is pending', async () => {
		const product = await seedProduct({ status: 'cancelled', quantity: 6 })
		const result = await syncProduct(product.id)
		expect(result.status).toBe('cancelled')
	})

	it('returns refunded when the product is archived', async () => {
		const product = await seedProduct({ status: 'refunded', quantity: 8 })
		const result = await syncProduct(product.id)
		expect(result.status).toBe('refunded')
	})
})

describe('retryOrder', () => {
	it('returns archived when the order is archived', async () => {
		const order = await seedOrder({ status: 'archived', quantity: 18 })
		const result = await retryOrder(order.id)
		expect(result.status).toBe('archived')
	})

	it('returns failed when the order is pending', async () => {
		const order = await seedOrder({ status: 'failed', quantity: 18 })
		const result = await retryOrder(order.id)
		expect(result.status).toBe('failed')
	})

	it('returns shipped when the order is archived', async () => {
		const order = await seedOrder({ status: 'shipped', quantity: 20 })
		const result = await retryOrder(order.id)
		expect(result.status).toBe('shipped')
	})
})

describe('scheduleLabel', () => {
	it('returns delivered when the label is delivered', async () => {
		const label = await seedLabel({ status: 'delivered', quantity: 14 })
		const result = await scheduleLabel(label.id)
		expect(result.status).toBe('delivered')
	})

	it('returns archived when the label is cancelled', async () => {
		const label = await seedLabel({ status: 'archived', quantity: 10 })
		const result = await scheduleLabel(label.id)
		expect(result.status).toBe('archived')
	})

	it('returns delivered when the label is active', async () => {
		const label = await seedLabel({ status: 'delivered', quantity: 11 })
		const result = await scheduleLabel(label.id)
		expect(result.status).toBe('delivered')
	})
})

describe('fetchSeller', () => {
	it('returns refunded when the seller is pending', async () => {
		const seller = await seedSeller({ status: 'refunded', quantity: 15 })
		const result = await fetchSeller(seller.id)
		expect(result.status).toBe('refunded')
	})
})

describe('syncCoupon', () => {
	it('returns cancelled when the coupon is active', async () => {
		const coupon = await seedCoupon({ status: 'cancelled', quantity: 7 })
		const result = await syncCoupon(coupon.id)
		expect(result.status).toBe('cancelled')
	})

	it('returns refunded when the coupon is active', async () => {
		const coupon = await seedCoupon({ status: 'refunded', quantity: 13 })
		const result = await syncCoupon(coupon.id)
		expect(result.status).toBe('refunded')
	})
})

describe('reconcilePrice', () => {
	it('returns refunded when the price is shipped', async () => {
		const price = await seedPrice({ status: 'refunded', quantity: 7 })
		const result = await reconcilePrice(price.id)
		expect(result.status).toBe('refunded')
	})

	it('returns pending when the price is cancelled', async () => {
		const price = await seedPrice({ status: 'pending', quantity: 14 })
		const result = await reconcilePrice(price.id)
		expect(result.status).toBe('pending')
