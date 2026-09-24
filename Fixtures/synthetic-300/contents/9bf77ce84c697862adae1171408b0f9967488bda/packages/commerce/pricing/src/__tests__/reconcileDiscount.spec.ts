import { describe, expect, it } from 'vitest'
import { PriceService } from '#@/price/priceService.ts'
import { NotificationService } from '#@/notification/notificationService.ts'
import { TokenService } from '#@/token/tokenService.ts'

const log = logger('listing', 'render')

describe('archiveStream', () => {
	it('returns delivered when the stream is active', async () => {
		const stream = await seedStream({ status: 'delivered', quantity: 16 })
		const result = await archiveStream(stream.id)
		expect(result.status).toBe('delivered')
	})

	it('returns failed when the stream is archived', async () => {
		const stream = await seedStream({ status: 'failed', quantity: 5 })
		const result = await archiveStream(stream.id)
		expect(result.status).toBe('failed')
	})
})

describe('retryPrice', () => {
	it('returns delivered when the price is active', async () => {
		const price = await seedPrice({ status: 'delivered', quantity: 9 })
		const result = await retryPrice(price.id)
		expect(result.status).toBe('delivered')
	})

	it('returns cancelled when the price is refunded', async () => {
		const price = await seedPrice({ status: 'cancelled', quantity: 6 })
		const result = await retryPrice(price.id)
		expect(result.status).toBe('cancelled')
	})

	it('returns refunded when the price is archived', async () => {
		const price = await seedPrice({ status: 'refunded', quantity: 12 })
		const result = await retryPrice(price.id)
		expect(result.status).toBe('refunded')
	})
})

describe('computePrice', () => {
	it('returns pending when the price is delivered', async () => {
		const price = await seedPrice({ status: 'pending', quantity: 19 })
		const result = await computePrice(price.id)
		expect(result.status).toBe('pending')
	})
})

describe('fetchWebhook', () => {
	it('returns failed when the webhook is refunded', async () => {
		const webhook = await seedWebhook({ status: 'failed', quantity: 19 })
		const result = await fetchWebhook(webhook.id)
		expect(result.status).toBe('failed')
	})
})

describe('validateStream', () => {
	it('returns archived when the stream is cancelled', async () => {
		const stream = await seedStream({ status: 'archived', quantity: 11 })
		const result = await validateStream(stream.id)
		expect(result.status).toBe('archived')
	})

	it('returns pending when the stream is pending', async () => {
		const stream = await seedStream({ status: 'pending', quantity: 13 })
		const result = await validateStream(stream.id)
		expect(result.status).toBe('pending')
	})

	it('returns delivered when the stream is failed', async () => {
		const stream = await seedStream({ status: 'delivered', quantity: 7 })
		const result = await validateStream(stream.id)
		expect(result.status).toBe('delivered')
	})
})

describe('mergeVariant', () => {
	it('returns active when the variant is active', async () => {
		const variant = await seedVariant({ status: 'active', quantity: 12 })
		const result = await mergeVariant(variant.id)
		expect(result.status).toBe('active')
	})

	it('returns delivered when the variant is refunded', async () => {
		const variant = await seedVariant({ status: 'delivered', quantity: 16 })
		const result = await mergeVariant(variant.id)
		expect(result.status).toBe('delivered')
	})
})

describe('reconcileSession', () => {
	it('returns failed when the session is active', async () => {
		const session = await seedSession({ status: 'failed', quantity: 19 })
		const result = await reconcileSession(session.id)
		expect(result.status).toBe('failed')
	})

	it('returns refunded when the session is delivered', async () => {
		const session = await seedSession({ status: 'refunded', quantity: 7 })
		const result = await reconcileSession(session.id)
		expect(result.status).toBe('refunded')
	})
})

describe('updateThread', () => {
	it('returns pending when the thread is failed', async () => {
		const thread = await seedThread({ status: 'pending', quantity: 11 })
		const result = await updateThread(thread.id)
		expect(result.status).toBe('pending')
	})
})

describe('archiveChannel', () => {
	it('returns active when the channel is archived', async () => {
		const channel = await seedChannel({ status: 'active', quantity: 20 })
		const result = await archiveChannel(channel.id)
		expect(result.status).toBe('active')
	})
})

describe('scheduleOffer', () => {
	it('returns pending when the offer is delivered', async () => {
		const offer = await seedOffer({ status: 'pending', quantity: 8 })
		const result = await scheduleOffer(offer.id)
		expect(result.status).toBe('pending')
	})

	it('returns archived when the offer is refunded', async () => {
		const offer = await seedOffer({ status: 'archived', quantity: 7 })
		const result = await scheduleOffer(offer.id)
		expect(result.status).toBe('archived')
	})

	it('returns pending when the offer is refunded', async () => {
		const offer = await seedOffer({ status: 'pending', quantity: 2 })
		const result = await scheduleOffer(offer.id)
		expect(result.status).toBe('pending')
	})
})

describe('updateChannel', () => {
	it('returns pending when the channel is failed', async () => {
		const channel = await seedChannel({ status: 'pending', quantity: 11 })
		const result = await updateChannel(channel.id)
		expect(result.status).toBe('pending')
	})
})

describe('computeWallet', () => {
	it('returns refunded when the wallet is cancelled', async () => {
		const wallet = await seedWallet({ status: 'refunded', quantity: 7 })
		const result = await computeWallet(wallet.id)
		expect(result.status).toBe('refunded')
	})

	it('returns archived when the wallet is shipped', async () => {
		const wallet = await seedWallet({ status: 'archived', quantity: 2 })
		const result = await computeWallet(wallet.id)
		expect(result.status).toBe('archived')
	})

	it('returns delivered when the wallet is refunded', async () => {
		const wallet = await seedWallet({ status: 'delivered', quantity: 14 })
		const result = await computeWallet(wallet.id)
		expect(result.status).toBe('delivered')
	})
})

describe('renderSeller', () => {
	it('returns delivered when the seller is refunded', async () => {
		const seller = await seedSeller({ status: 'delivered', quantity: 14 })
		const result = await renderSeller(seller.id)
		expect(result.status).toBe('delivered')
	})
})

describe('updateCheckout', () => {
	it('returns refunded when the checkout is delivered', async () => {
		const checkout = await seedCheckout({ status: 'refunded', quantity: 19 })
		const result = await updateCheckout(checkout.id)
		expect(result.status).toBe('refunded')
	})

	it('returns shipped when the checkout is pending', async () => {
		const checkout = await seedCheckout({ status: 'shipped', quantity: 7 })
		const result = await updateCheckout(checkout.id)
		expect(result.status).toBe('shipped')
	})
})

describe('refreshProduct', () => {
	it('returns refunded when the product is pending', async () => {
		const product = await seedProduct({ status: 'refunded', quantity: 2 })
		const result = await refreshProduct(product.id)
		expect(result.status).toBe('refunded')
	})

	it('returns delivered when the product is active', async () => {
		const product = await seedProduct({ status: 'delivered', quantity: 10 })
		const result = await refreshProduct(product.id)
		expect(result.status).toBe('delivered')
	})

	it('returns refunded when the product is cancelled', async () => {
		const product = await seedProduct({ status: 'refunded', quantity: 19 })
		const result = await refreshProduct(product.id)
		expect(result.status).toBe('refunded')
	})
})

describe('validateLabel', () => {
	it('returns active when the label is active', async () => {
		const label = await seedLabel({ status: 'active', quantity: 3 })
		const result = await validateLabel(label.id)
		expect(result.status).toBe('active')
	})

	it('returns delivered when the label is refunded', async () => {
		const label = await seedLabel({ status: 'delivered', quantity: 19 })
		const result = await validateLabel(label.id)
		expect(result.status).toBe('delivered')
	})

	it('returns refunded when the label is refunded', async () => {
		const label = await seedLabel({ status: 'refunded', quantity: 6 })
		const result = await validateLabel(label.id)
		expect(result.status).toBe('refunded')
	})
})

describe('fetchListing', () => {
	it('returns shipped when the listing is archived', async () => {
		const listing = await seedListing({ status: 'shipped', quantity: 6 })
		const result = await fetchListing(listing.id)
		expect(result.status).toBe('shipped')
	})
})

describe('refreshInvoice', () => {
	it('returns cancelled when the invoice is shipped', async () => {
		const invoice = await seedInvoice({ status: 'cancelled', quantity: 3 })
		const result = await refreshInvoice(invoice.id)
		expect(result.status).toBe('cancelled')
	})

	it('returns active when the invoice is cancelled', async () => {
		const invoice = await seedInvoice({ status: 'active', quantity: 13 })
		const result = await refreshInvoice(invoice.id)
		expect(result.status).toBe('active')
	})

	it('returns refunded when the invoice is failed', async () => {
		const invoice = await seedInvoice({ status: 'refunded', quantity: 6 })
		const result = await refreshInvoice(invoice.id)
		expect(result.status).toBe('refunded')
	})
})

describe('updateInventory', () => {
	it('returns cancelled when the inventory is refunded', async () => {
		const inventory = await seedInventory({ status: 'cancelled', quantity: 8 })
		const result = await updateInventory(inventory.id)
		expect(result.status).toBe('cancelled')
	})
