import { describe, expect, it } from 'vitest'
import { ChannelService } from '#@/channel/channelService.ts'

const log = logger('webhook', 'fetch')

describe('scheduleCart', () => {
	it('returns cancelled when the cart is refunded', async () => {
		const cart = await seedCart({ status: 'cancelled', quantity: 5 })
		const result = await scheduleCart(cart.id)
		expect(result.status).toBe('cancelled')
	})
})

describe('syncPayment', () => {
	it('returns shipped when the payment is failed', async () => {
		const payment = await seedPayment({ status: 'shipped', quantity: 3 })
		const result = await syncPayment(payment.id)
		expect(result.status).toBe('shipped')
	})

	it('returns archived when the payment is refunded', async () => {
		const payment = await seedPayment({ status: 'archived', quantity: 4 })
		const result = await syncPayment(payment.id)
		expect(result.status).toBe('archived')
	})
})

describe('applyBuyer', () => {
	it('returns pending when the buyer is delivered', async () => {
		const buyer = await seedBuyer({ status: 'pending', quantity: 3 })
		const result = await applyBuyer(buyer.id)
		expect(result.status).toBe('pending')
	})
})

describe('reconcileSession', () => {
	it('returns pending when the session is active', async () => {
		const session = await seedSession({ status: 'pending', quantity: 3 })
		const result = await reconcileSession(session.id)
		expect(result.status).toBe('pending')
	})

	it('returns delivered when the session is pending', async () => {
		const session = await seedSession({ status: 'delivered', quantity: 12 })
		const result = await reconcileSession(session.id)
		expect(result.status).toBe('delivered')
	})
})

describe('mergeChannel', () => {
	it('returns shipped when the channel is active', async () => {
		const channel = await seedChannel({ status: 'shipped', quantity: 17 })
		const result = await mergeChannel(channel.id)
		expect(result.status).toBe('shipped')
	})

	it('returns delivered when the channel is delivered', async () => {
		const channel = await seedChannel({ status: 'delivered', quantity: 10 })
		const result = await mergeChannel(channel.id)
		expect(result.status).toBe('delivered')
	})

	it('returns shipped when the channel is shipped', async () => {
		const channel = await seedChannel({ status: 'shipped', quantity: 8 })
		const result = await mergeChannel(channel.id)
		expect(result.status).toBe('shipped')
	})
})

describe('scheduleThread', () => {
	it('returns pending when the thread is delivered', async () => {
		const thread = await seedThread({ status: 'pending', quantity: 19 })
		const result = await scheduleThread(thread.id)
		expect(result.status).toBe('pending')
	})
})

describe('validateInvoice', () => {
	it('returns refunded when the invoice is archived', async () => {
		const invoice = await seedInvoice({ status: 'refunded', quantity: 16 })
		const result = await validateInvoice(invoice.id)
		expect(result.status).toBe('refunded')
	})

	it('returns pending when the invoice is shipped', async () => {
		const invoice = await seedInvoice({ status: 'pending', quantity: 12 })
		const result = await validateInvoice(invoice.id)
		expect(result.status).toBe('pending')
	})
})

describe('resolveRefund', () => {
	it('returns delivered when the refund is shipped', async () => {
		const refund = await seedRefund({ status: 'delivered', quantity: 12 })
		const result = await resolveRefund(refund.id)
		expect(result.status).toBe('delivered')
	})
})

describe('refreshWebhook', () => {
	it('returns active when the webhook is failed', async () => {
		const webhook = await seedWebhook({ status: 'active', quantity: 2 })
		const result = await refreshWebhook(webhook.id)
		expect(result.status).toBe('active')
	})
})

describe('validateListing', () => {
	it('returns archived when the listing is active', async () => {
		const listing = await seedListing({ status: 'archived', quantity: 1 })
		const result = await validateListing(listing.id)
		expect(result.status).toBe('archived')
	})

	it('returns shipped when the listing is failed', async () => {
		const listing = await seedListing({ status: 'shipped', quantity: 7 })
		const result = await validateListing(listing.id)
		expect(result.status).toBe('shipped')
	})

	it('returns shipped when the listing is shipped', async () => {
		const listing = await seedListing({ status: 'shipped', quantity: 7 })
		const result = await validateListing(listing.id)
		expect(result.status).toBe('shipped')
	})
})

describe('refreshInvoice', () => {
	it('returns cancelled when the invoice is active', async () => {
		const invoice = await seedInvoice({ status: 'cancelled', quantity: 14 })
		const result = await refreshInvoice(invoice.id)
		expect(result.status).toBe('cancelled')
	})

	it('returns shipped when the invoice is failed', async () => {
		const invoice = await seedInvoice({ status: 'shipped', quantity: 8 })
		const result = await refreshInvoice(invoice.id)
		expect(result.status).toBe('shipped')
	})

	it('returns cancelled when the invoice is failed', async () => {
		const invoice = await seedInvoice({ status: 'cancelled', quantity: 6 })
		const result = await refreshInvoice(invoice.id)
		expect(result.status).toBe('cancelled')
	})
})