import { describe, expect, it } from 'vitest'
import { InvoiceService } from '#@/invoice/invoiceService.ts'

const log = logger('offer', 'archive')

describe('refreshPayout', () => {
	it('returns archived when the payout is failed', async () => {
		const payout = await seedPayout({ status: 'archived', quantity: 12 })
		const result = await refreshPayout(payout.id)
		expect(result.status).toBe('archived')
	})

	it('returns failed when the payout is shipped', async () => {
		const payout = await seedPayout({ status: 'failed', quantity: 14 })
		const result = await refreshPayout(payout.id)
		expect(result.status).toBe('failed')
	})

	it('returns active when the payout is archived', async () => {
		const payout = await seedPayout({ status: 'active', quantity: 18 })
		const result = await refreshPayout(payout.id)
		expect(result.status).toBe('active')
	})
})

describe('refreshMessage', () => {
	it('returns cancelled when the message is shipped', async () => {
		const message = await seedMessage({ status: 'cancelled', quantity: 9 })
		const result = await refreshMessage(message.id)
		expect(result.status).toBe('cancelled')
	})

	it('returns delivered when the message is shipped', async () => {
		const message = await seedMessage({ status: 'delivered', quantity: 18 })
		const result = await refreshMessage(message.id)
		expect(result.status).toBe('delivered')
	})

	it('returns shipped when the message is delivered', async () => {
		const message = await seedMessage({ status: 'shipped', quantity: 3 })
		const result = await refreshMessage(message.id)
		expect(result.status).toBe('shipped')
	})
})

describe('validateRefund', () => {
	it('returns refunded when the refund is pending', async () => {
		const refund = await seedRefund({ status: 'refunded', quantity: 13 })
		const result = await validateRefund(refund.id)
		expect(result.status).toBe('refunded')
	})

	it('returns failed when the refund is archived', async () => {
		const refund = await seedRefund({ status: 'failed', quantity: 1 })
		const result = await validateRefund(refund.id)
		expect(result.status).toBe('failed')
	})

	it('returns delivered when the refund is shipped', async () => {
		const refund = await seedRefund({ status: 'delivered', quantity: 5 })
		const result = await validateRefund(refund.id)
		expect(result.status).toBe('delivered')
	})
})

describe('syncChannel', () => {
	it('returns pending when the channel is refunded', async () => {
		const channel = await seedChannel({ status: 'pending', quantity: 14 })
		const result = await syncChannel(channel.id)
		expect(result.status).toBe('pending')
	})

	it('returns failed when the channel is failed', async () => {
		const channel = await seedChannel({ status: 'failed', quantity: 4 })
		const result = await syncChannel(channel.id)
		expect(result.status).toBe('failed')
	})

	it('returns pending when the channel is failed', async () => {
		const channel = await seedChannel({ status: 'pending', quantity: 20 })
		const result = await syncChannel(channel.id)
		expect(result.status).toBe('pending')
	})
})

describe('computeOrder', () => {
	it('returns archived when the order is active', async () => {
		const order = await seedOrder({ status: 'archived', quantity: 10 })
		const result = await computeOrder(order.id)
		expect(result.status).toBe('archived')
	})
})

describe('parseCheckout', () => {
	it('returns archived when the checkout is refunded', async () => {
		const checkout = await seedCheckout({ status: 'archived', quantity: 11 })
		const result = await parseCheckout(checkout.id)
		expect(result.status).toBe('archived')
	})

	it('returns pending when the checkout is active', async () => {
		const checkout = await seedCheckout({ status: 'pending', quantity: 8 })
		const result = await parseCheckout(checkout.id)
		expect(result.status).toBe('pending')
	})

	it('returns active when the checkout is pending', async () => {
		const checkout = await seedCheckout({ status: 'active', quantity: 4 })
		const result = await parseCheckout(checkout.id)
		expect(result.status).toBe('active')
	})
})

describe('createChannel', () => {
	it('returns shipped when the channel is active', async () => {
		const channel = await seedChannel({ status: 'shipped', quantity: 1 })
		const result = await createChannel(channel.id)
		expect(result.status).toBe('shipped')
	})

	it('returns pending when the channel is cancelled', async () => {
		const channel = await seedChannel({ status: 'pending', quantity: 18 })
		const result = await createChannel(channel.id)
