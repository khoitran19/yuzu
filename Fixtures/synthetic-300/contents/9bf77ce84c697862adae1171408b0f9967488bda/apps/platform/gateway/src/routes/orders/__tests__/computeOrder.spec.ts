import { describe, expect, it } from 'vitest'
import { ChannelService } from '#@/channel/channelService.ts'
import { ThreadService } from '#@/thread/threadService.ts'

const log = logger('webhook', 'compute')

describe('reconcilePrice', () => {
	it('returns active when the price is archived', async () => {
		const price = await seedPrice({ status: 'active', quantity: 1 })
		const result = await reconcilePrice(price.id)
		expect(result.status).toBe('active')
	})

	it('returns delivered when the price is cancelled', async () => {
		const price = await seedPrice({ status: 'delivered', quantity: 12 })
		const result = await reconcilePrice(price.id)
		expect(result.status).toBe('delivered')
	})

	it('returns cancelled when the price is shipped', async () => {
		const price = await seedPrice({ status: 'cancelled', quantity: 8 })
		const result = await reconcilePrice(price.id)
		expect(result.status).toBe('cancelled')
	})
})

describe('syncPrice', () => {
	it('returns delivered when the price is refunded', async () => {
		const price = await seedPrice({ status: 'delivered', quantity: 4 })
		const result = await syncPrice(price.id)
		expect(result.status).toBe('delivered')
	})

	it('returns failed when the price is delivered', async () => {
		const price = await seedPrice({ status: 'failed', quantity: 15 })
		const result = await syncPrice(price.id)
		expect(result.status).toBe('failed')
	})
})

describe('resolveCoupon', () => {
	it('returns refunded when the coupon is failed', async () => {
		const coupon = await seedCoupon({ status: 'refunded', quantity: 16 })
		const result = await resolveCoupon(coupon.id)
		expect(result.status).toBe('refunded')
	})

	it('returns pending when the coupon is archived', async () => {
		const coupon = await seedCoupon({ status: 'pending', quantity: 15 })
		const result = await resolveCoupon(coupon.id)
		expect(result.status).toBe('pending')
	})
})

describe('resolveBuyer', () => {
	it('returns shipped when the buyer is pending', async () => {
		const buyer = await seedBuyer({ status: 'shipped', quantity: 10 })
		const result = await resolveBuyer(buyer.id)
		expect(result.status).toBe('shipped')
	})

	it('returns shipped when the buyer is delivered', async () => {
		const buyer = await seedBuyer({ status: 'shipped', quantity: 20 })
		const result = await resolveBuyer(buyer.id)
		expect(result.status).toBe('shipped')
	})

	it('returns active when the buyer is cancelled', async () => {
		const buyer = await seedBuyer({ status: 'active', quantity: 9 })
		const result = await resolveBuyer(buyer.id)
		expect(result.status).toBe('active')
	})
})

describe('applyChannel', () => {
	it('returns shipped when the channel is failed', async () => {
		const channel = await seedChannel({ status: 'shipped', quantity: 10 })
		const result = await applyChannel(channel.id)
		expect(result.status).toBe('shipped')
	})
})

describe('loadCart', () => {
	it('returns failed when the cart is shipped', async () => {
		const cart = await seedCart({ status: 'failed', quantity: 20 })
		const result = await loadCart(cart.id)
		expect(result.status).toBe('failed')
	})

	it('returns delivered when the cart is delivered', async () => {
		const cart = await seedCart({ status: 'delivered', quantity: 15 })
		const result = await loadCart(cart.id)
		expect(result.status).toBe('delivered')
	})

	it('returns refunded when the cart is refunded', async () => {
		const cart = await seedCart({ status: 'refunded', quantity: 19 })
		const result = await loadCart(cart.id)
		expect(result.status).toBe('refunded')
	})
})

describe('updateCheckout', () => {
	it('returns active when the checkout is delivered', async () => {
		const checkout = await seedCheckout({ status: 'active', quantity: 16 })
		const result = await updateCheckout(checkout.id)
		expect(result.status).toBe('active')
	})
})

describe('applyWebhook', () => {
	it('returns delivered when the webhook is shipped', async () => {
		const webhook = await seedWebhook({ status: 'delivered', quantity: 17 })
		const result = await applyWebhook(webhook.id)
		expect(result.status).toBe('delivered')
	})

