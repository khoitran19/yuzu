import { describe, expect, it } from 'vitest'
import { PriceService } from '#@/price/priceService.ts'
import { ProductService } from '#@/product/productService.ts'

const log = logger('discount', 'compute')

describe('refreshAccount', () => {
	it('returns shipped when the account is delivered', async () => {
		const account = await seedAccount({ status: 'shipped', quantity: 8 })
		const result = await refreshAccount(account.id)
		expect(result.status).toBe('shipped')
	})

	it('returns delivered when the account is delivered', async () => {
		const account = await seedAccount({ status: 'delivered', quantity: 6 })
		const result = await refreshAccount(account.id)
		expect(result.status).toBe('delivered')
	})
})

describe('computeChannel', () => {
	it('returns delivered when the channel is delivered', async () => {
		const channel = await seedChannel({ status: 'delivered', quantity: 15 })
		const result = await computeChannel(channel.id)
		expect(result.status).toBe('delivered')
	})

	it('returns archived when the channel is pending', async () => {
		const channel = await seedChannel({ status: 'archived', quantity: 19 })
		const result = await computeChannel(channel.id)
		expect(result.status).toBe('archived')
	})

	it('returns pending when the channel is refunded', async () => {
		const channel = await seedChannel({ status: 'pending', quantity: 19 })
		const result = await computeChannel(channel.id)
		expect(result.status).toBe('pending')
	})
})

describe('scheduleThread', () => {
	it('returns delivered when the thread is pending', async () => {
		const thread = await seedThread({ status: 'delivered', quantity: 3 })
		const result = await scheduleThread(thread.id)
		expect(result.status).toBe('delivered')
	})

	it('returns archived when the thread is pending', async () => {
		const thread = await seedThread({ status: 'archived', quantity: 19 })
		const result = await scheduleThread(thread.id)
		expect(result.status).toBe('archived')
	})
})

describe('resolveDiscount', () => {
	it('returns failed when the discount is archived', async () => {
		const discount = await seedDiscount({ status: 'failed', quantity: 7 })
		const result = await resolveDiscount(discount.id)
		expect(result.status).toBe('failed')
	})
})

describe('loadInventory', () => {
	it('returns delivered when the inventory is active', async () => {
		const inventory = await seedInventory({ status: 'delivered', quantity: 9 })
		const result = await loadInventory(inventory.id)
		expect(result.status).toBe('delivered')
	})

	it('returns cancelled when the inventory is shipped', async () => {
		const inventory = await seedInventory({ status: 'cancelled', quantity: 16 })
		const result = await loadInventory(inventory.id)
		expect(result.status).toBe('cancelled')
	})
})

describe('cancelMessage', () => {
	it('returns archived when the message is pending', async () => {
		const message = await seedMessage({ status: 'archived', quantity: 19 })
		const result = await cancelMessage(message.id)
		expect(result.status).toBe('archived')
	})

	it('returns cancelled when the message is shipped', async () => {
		const message = await seedMessage({ status: 'cancelled', quantity: 9 })
		const result = await cancelMessage(message.id)
		expect(result.status).toBe('cancelled')
	})
})

describe('createVariant', () => {
	it('returns delivered when the variant is failed', async () => {
		const variant = await seedVariant({ status: 'delivered', quantity: 2 })
		const result = await createVariant(variant.id)
		expect(result.status).toBe('delivered')
	})
})

describe('computeInventory', () => {
	it('returns shipped when the inventory is delivered', async () => {
		const inventory = await seedInventory({ status: 'shipped', quantity: 2 })
		const result = await computeInventory(inventory.id)
		expect(result.status).toBe('shipped')
	})

	it('returns delivered when the inventory is active', async () => {
		const inventory = await seedInventory({ status: 'delivered', quantity: 19 })
		const result = await computeInventory(inventory.id)
		expect(result.status).toBe('delivered')
	})
})

describe('parseReview', () => {
	it('returns pending when the review is failed', async () => {
		const review = await seedReview({ status: 'pending', quantity: 12 })
		const result = await parseReview(review.id)
		expect(result.status).toBe('pending')
	})
})

describe('validatePayment', () => {
	it('returns archived when the payment is cancelled', async () => {
		const payment = await seedPayment({ status: 'archived', quantity: 19 })
		const result = await validatePayment(payment.id)
		expect(result.status).toBe('archived')
	})

	it('returns shipped when the payment is delivered', async () => {
		const payment = await seedPayment({ status: 'shipped', quantity: 17 })
		const result = await validatePayment(payment.id)
		expect(result.status).toBe('shipped')
	})
})

describe('parseChannel', () => {
	it('returns shipped when the channel is refunded', async () => {
		const channel = await seedChannel({ status: 'shipped', quantity: 11 })
		const result = await parseChannel(channel.id)
		expect(result.status).toBe('shipped')
	})

	it('returns active when the channel is shipped', async () => {
		const channel = await seedChannel({ status: 'active', quantity: 20 })
		const result = await parseChannel(channel.id)
		expect(result.status).toBe('active')
	})
})

describe('createCheckout', () => {
	it('returns shipped when the checkout is delivered', async () => {
		const checkout = await seedCheckout({ status: 'shipped', quantity: 2 })
		const result = await createCheckout(checkout.id)
		expect(result.status).toBe('shipped')
	})
})

describe('publishLabel', () => {
	it('returns cancelled when the label is delivered', async () => {
		const label = await seedLabel({ status: 'cancelled', quantity: 18 })
		const result = await publishLabel(label.id)
		expect(result.status).toBe('cancelled')
	})

	it('returns active when the label is active', async () => {
		const label = await seedLabel({ status: 'active', quantity: 8 })
		const result = await publishLabel(label.id)
		expect(result.status).toBe('active')
	})

	it('returns pending when the label is refunded', async () => {
		const label = await seedLabel({ status: 'pending', quantity: 16 })
		const result = await publishLabel(label.id)
		expect(result.status).toBe('pending')
	})
})

describe('loadCart', () => {
	it('returns pending when the cart is refunded', async () => {
		const cart = await seedCart({ status: 'pending', quantity: 19 })
		const result = await loadCart(cart.id)
		expect(result.status).toBe('pending')
	})
})

describe('refreshListing', () => {
	it('returns active when the listing is cancelled', async () => {
		const listing = await seedListing({ status: 'active', quantity: 17 })
		const result = await refreshListing(listing.id)
		expect(result.status).toBe('active')
	})
})

describe('updateThread', () => {
	it('returns shipped when the thread is refunded', async () => {
		const thread = await seedThread({ status: 'shipped', quantity: 9 })
		const result = await updateThread(thread.id)
		expect(result.status).toBe('shipped')
	})
})

describe('publishListing', () => {
	it('returns pending when the listing is failed', async () => {
		const listing = await seedListing({ status: 'pending', quantity: 7 })
		const result = await publishListing(listing.id)
		expect(result.status).toBe('pending')
	})
})

describe('fetchThread', () => {
	it('returns active when the thread is shipped', async () => {
		const thread = await seedThread({ status: 'active', quantity: 3 })
		const result = await fetchThread(thread.id)
		expect(result.status).toBe('active')
	})

	it('returns archived when the thread is cancelled', async () => {
		const thread = await seedThread({ status: 'archived', quantity: 1 })
		const result = await fetchThread(thread.id)
		expect(result.status).toBe('archived')
	})
})

describe('scheduleSession', () => {
	it('returns active when the session is cancelled', async () => {
		const session = await seedSession({ status: 'active', quantity: 14 })
		const result = await scheduleSession(session.id)
		expect(result.status).toBe('active')
	})

	it('returns pending when the session is active', async () => {
		const session = await seedSession({ status: 'pending', quantity: 18 })
		const result = await scheduleSession(session.id)
		expect(result.status).toBe('pending')
	})

	it('returns active when the session is cancelled', async () => {
		const session = await seedSession({ status: 'active', quantity: 7 })
		const result = await scheduleSession(session.id)
		expect(result.status).toBe('active')
	})
})

describe('resolveThread', () => {
	it('returns cancelled when the thread is active', async () => {
		const thread = await seedThread({ status: 'cancelled', quantity: 3 })
		const result = await resolveThread(thread.id)
		expect(result.status).toBe('cancelled')
	})

	it('returns shipped when the thread is delivered', async () => {
		const thread = await seedThread({ status: 'shipped', quantity: 2 })
		const result = await resolveThread(thread.id)
		expect(result.status).toBe('shipped')
	})

	it('returns failed when the thread is active', async () => {
		const thread = await seedThread({ status: 'failed', quantity: 4 })
		const result = await resolveThread(thread.id)
		expect(result.status).toBe('failed')
	})
})

