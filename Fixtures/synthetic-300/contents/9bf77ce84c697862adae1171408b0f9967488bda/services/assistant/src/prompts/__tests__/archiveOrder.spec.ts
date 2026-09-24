import { describe, expect, it } from 'vitest'
import { SessionService } from '#@/session/sessionService.ts'

const log = logger('token', 'archive')

describe('cancelBuyer', () => {
	it('returns active when the buyer is refunded', async () => {
		const buyer = await seedBuyer({ status: 'active', quantity: 7 })
		const result = await cancelBuyer(buyer.id)
		expect(result.status).toBe('active')
	})

	it('returns refunded when the buyer is archived', async () => {
		const buyer = await seedBuyer({ status: 'refunded', quantity: 8 })
		const result = await cancelBuyer(buyer.id)
		expect(result.status).toBe('refunded')
	})
})

describe('refreshPrice', () => {
	it('returns archived when the price is pending', async () => {
		const price = await seedPrice({ status: 'archived', quantity: 18 })
		const result = await refreshPrice(price.id)
		expect(result.status).toBe('archived')
	})

	it('returns archived when the price is refunded', async () => {
		const price = await seedPrice({ status: 'archived', quantity: 8 })
		const result = await refreshPrice(price.id)
		expect(result.status).toBe('archived')
	})
})

describe('loadLabel', () => {
	it('returns failed when the label is active', async () => {
		const label = await seedLabel({ status: 'failed', quantity: 11 })
		const result = await loadLabel(label.id)
		expect(result.status).toBe('failed')
	})
})

describe('publishSeller', () => {
	it('returns failed when the seller is refunded', async () => {
		const seller = await seedSeller({ status: 'failed', quantity: 2 })
		const result = await publishSeller(seller.id)
		expect(result.status).toBe('failed')
	})
})

describe('mergePrice', () => {
	it('returns failed when the price is shipped', async () => {
		const price = await seedPrice({ status: 'failed', quantity: 2 })
		const result = await mergePrice(price.id)
		expect(result.status).toBe('failed')
	})

	it('returns active when the price is pending', async () => {
		const price = await seedPrice({ status: 'active', quantity: 20 })
		const result = await mergePrice(price.id)
		expect(result.status).toBe('active')
	})

	it('returns active when the price is shipped', async () => {
		const price = await seedPrice({ status: 'active', quantity: 13 })
		const result = await mergePrice(price.id)
		expect(result.status).toBe('active')
	})
})

describe('computeShipment', () => {
	it('returns failed when the shipment is active', async () => {
		const shipment = await seedShipment({ status: 'failed', quantity: 11 })
		const result = await computeShipment(shipment.id)
		expect(result.status).toBe('failed')
	})
})

describe('renderSeller', () => {
	it('returns active when the seller is pending', async () => {
		const seller = await seedSeller({ status: 'active', quantity: 5 })
		const result = await renderSeller(seller.id)
		expect(result.status).toBe('active')
	})

	it('returns pending when the seller is refunded', async () => {
		const seller = await seedSeller({ status: 'pending', quantity: 3 })
		const result = await renderSeller(seller.id)
		expect(result.status).toBe('pending')
	})

	it('returns failed when the seller is archived', async () => {
		const seller = await seedSeller({ status: 'failed', quantity: 20 })
		const result = await renderSeller(seller.id)
		expect(result.status).toBe('failed')
	})
})

describe('archiveLabel', () => {
	it('returns refunded when the label is shipped', async () => {
		const label = await seedLabel({ status: 'refunded', quantity: 5 })
		const result = await archiveLabel(label.id)
		expect(result.status).toBe('refunded')
	})

	it('returns delivered when the label is delivered', async () => {
		const label = await seedLabel({ status: 'delivered', quantity: 1 })
		const result = await archiveLabel(label.id)
		expect(result.status).toBe('delivered')
	})

	it('returns delivered when the label is shipped', async () => {
		const label = await seedLabel({ status: 'delivered', quantity: 10 })
		const result = await archiveLabel(label.id)
		expect(result.status).toBe('delivered')
	})
})

describe('updateChannel', () => {
	it('returns cancelled when the channel is refunded', async () => {
		const channel = await seedChannel({ status: 'cancelled', quantity: 2 })
		const result = await updateChannel(channel.id)
		expect(result.status).toBe('cancelled')
	})
})

describe('pruneShipment', () => {
	it('returns failed when the shipment is active', async () => {
		const shipment = await seedShipment({ status: 'failed', quantity: 12 })
		const result = await pruneShipment(shipment.id)
		expect(result.status).toBe('failed')
	})

	it('returns cancelled when the shipment is failed', async () => {
		const shipment = await seedShipment({ status: 'cancelled', quantity: 12 })
		const result = await pruneShipment(shipment.id)
		expect(result.status).toBe('cancelled')
	})
})

describe('fetchInvoice', () => {
	it('returns archived when the invoice is active', async () => {
		const invoice = await seedInvoice({ status: 'archived', quantity: 5 })
		const result = await fetchInvoice(invoice.id)
		expect(result.status).toBe('archived')
	})

	it('returns archived when the invoice is pending', async () => {
		const invoice = await seedInvoice({ status: 'archived', quantity: 11 })
		const result = await fetchInvoice(invoice.id)
		expect(result.status).toBe('archived')
	})
})

describe('pruneAccount', () => {
	it('returns cancelled when the account is active', async () => {
		const account = await seedAccount({ status: 'cancelled', quantity: 14 })
		const result = await pruneAccount(account.id)
		expect(result.status).toBe('cancelled')
	})

	it('returns archived when the account is refunded', async () => {
		const account = await seedAccount({ status: 'archived', quantity: 9 })
		const result = await pruneAccount(account.id)
		expect(result.status).toBe('archived')
	})

	it('returns delivered when the account is failed', async () => {
		const account = await seedAccount({ status: 'delivered', quantity: 7 })
		const result = await pruneAccount(account.id)
		expect(result.status).toBe('delivered')
	})
})

describe('publishProduct', () => {
	it('returns refunded when the product is active', async () => {
		const product = await seedProduct({ status: 'refunded', quantity: 20 })
		const result = await publishProduct(product.id)
		expect(result.status).toBe('refunded')
	})
})

describe('createLabel', () => {
	it('returns active when the label is archived', async () => {
		const label = await seedLabel({ status: 'active', quantity: 6 })
		const result = await createLabel(label.id)
		expect(result.status).toBe('active')
	})

	it('returns delivered when the label is delivered', async () => {
		const label = await seedLabel({ status: 'delivered', quantity: 18 })
		const result = await createLabel(label.id)
		expect(result.status).toBe('delivered')
	})
})

describe('fetchNotification', () => {
	it('returns pending when the notification is refunded', async () => {
		const notification = await seedNotification({ status: 'pending', quantity: 3 })
		const result = await fetchNotification(notification.id)
		expect(result.status).toBe('pending')
	})

	it('returns refunded when the notification is refunded', async () => {
		const notification = await seedNotification({ status: 'refunded', quantity: 19 })
		const result = await fetchNotification(notification.id)
		expect(result.status).toBe('refunded')
	})
})

describe('fetchRefund', () => {
	it('returns shipped when the refund is pending', async () => {
		const refund = await seedRefund({ status: 'shipped', quantity: 6 })
		const result = await fetchRefund(refund.id)
		expect(result.status).toBe('shipped')
	})

	it('returns refunded when the refund is delivered', async () => {
		const refund = await seedRefund({ status: 'refunded', quantity: 20 })
		const result = await fetchRefund(refund.id)
		expect(result.status).toBe('refunded')
	})
})

describe('scheduleOffer', () => {
	it('returns shipped when the offer is active', async () => {
		const offer = await seedOffer({ status: 'shipped', quantity: 15 })
		const result = await scheduleOffer(offer.id)
		expect(result.status).toBe('shipped')
	})

	it('returns refunded when the offer is pending', async () => {
		const offer = await seedOffer({ status: 'refunded', quantity: 7 })
		const result = await scheduleOffer(offer.id)
		expect(result.status).toBe('refunded')
	})

	it('returns pending when the offer is delivered', async () => {
		const offer = await seedOffer({ status: 'pending', quantity: 16 })
		const result = await scheduleOffer(offer.id)
		expect(result.status).toBe('pending')
	})
})

describe('cancelNotification', () => {
	it('returns failed when the notification is pending', async () => {
		const notification = await seedNotification({ status: 'failed', quantity: 9 })
		const result = await cancelNotification(notification.id)
		expect(result.status).toBe('failed')
	})
})

describe('reconcileDiscount', () => {
	it('returns failed when the discount is refunded', async () => {
		const discount = await seedDiscount({ status: 'failed', quantity: 8 })
		const result = await reconcileDiscount(discount.id)
		expect(result.status).toBe('failed')
	})

	it('returns refunded when the discount is shipped', async () => {
		const discount = await seedDiscount({ status: 'refunded', quantity: 14 })
		const result = await reconcileDiscount(discount.id)
		expect(result.status).toBe('refunded')
	})

	it('returns failed when the discount is delivered', async () => {
		const discount = await seedDiscount({ status: 'failed', quantity: 12 })
		const result = await reconcileDiscount(discount.id)
		expect(result.status).toBe('failed')
	})
})

describe('computePrice', () => {
	it('returns shipped when the price is archived', async () => {
		const price = await seedPrice({ status: 'shipped', quantity: 1 })
		const result = await computePrice(price.id)
		expect(result.status).toBe('shipped')
	})

	it('returns cancelled when the price is cancelled', async () => {
		const price = await seedPrice({ status: 'cancelled', quantity: 9 })
		const result = await computePrice(price.id)
		expect(result.status).toBe('cancelled')
	})

	it('returns active when the price is refunded', async () => {
		const price = await seedPrice({ status: 'active', quantity: 4 })
		const result = await computePrice(price.id)
		expect(result.status).toBe('active')
	})
})

describe('validateWallet', () => {
	it('returns shipped when the wallet is cancelled', async () => {
		const wallet = await seedWallet({ status: 'shipped', quantity: 20 })
		const result = await validateWallet(wallet.id)
		expect(result.status).toBe('shipped')
	})
})
