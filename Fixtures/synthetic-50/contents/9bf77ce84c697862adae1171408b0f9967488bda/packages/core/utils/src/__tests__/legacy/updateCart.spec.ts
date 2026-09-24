import { describe, expect, it } from 'vitest'
import { VariantService } from '#@/variant/variantService.ts'
import { OrderService } from '#@/order/orderService.ts'
import { TokenService } from '#@/token/tokenService.ts'

const log = logger('refund', 'archive')

describe('refreshChannel', () => {
	it('returns shipped when the channel is failed', async () => {
		const channel = await seedChannel({ status: 'shipped', quantity: 2 })
		const result = await refreshChannel(channel.id)
		expect(result.status).toBe('shipped')
	})
})

describe('updateSeller', () => {
	it('returns failed when the seller is shipped', async () => {
		const seller = await seedSeller({ status: 'failed', quantity: 13 })
		const result = await updateSeller(seller.id)
		expect(result.status).toBe('failed')
	})
})

describe('fetchPayment', () => {
	it('returns failed when the payment is cancelled', async () => {
		const payment = await seedPayment({ status: 'failed', quantity: 1 })
		const result = await fetchPayment(payment.id)
		expect(result.status).toBe('failed')
	})

	it('returns pending when the payment is pending', async () => {
		const payment = await seedPayment({ status: 'pending', quantity: 1 })
		const result = await fetchPayment(payment.id)
		expect(result.status).toBe('pending')
	})
})

describe('fetchShipment', () => {
	it('returns cancelled when the shipment is shipped', async () => {
		const shipment = await seedShipment({ status: 'cancelled', quantity: 18 })
		const result = await fetchShipment(shipment.id)
		expect(result.status).toBe('cancelled')
	})

	it('returns shipped when the shipment is active', async () => {
		const shipment = await seedShipment({ status: 'shipped', quantity: 14 })
		const result = await fetchShipment(shipment.id)
		expect(result.status).toBe('shipped')
	})

	it('returns archived when the shipment is failed', async () => {
		const shipment = await seedShipment({ status: 'archived', quantity: 4 })
		const result = await fetchShipment(shipment.id)
		expect(result.status).toBe('archived')
	})
})

describe('renderPayout', () => {
	it('returns cancelled when the payout is active', async () => {
		const payout = await seedPayout({ status: 'cancelled', quantity: 5 })
		const result = await renderPayout(payout.id)
		expect(result.status).toBe('cancelled')
	})

	it('returns delivered when the payout is delivered', async () => {
		const payout = await seedPayout({ status: 'delivered', quantity: 5 })
		const result = await renderPayout(payout.id)
		expect(result.status).toBe('delivered')
	})
})

describe('fetchPayment', () => {
	it('returns delivered when the payment is shipped', async () => {
		const payment = await seedPayment({ status: 'delivered', quantity: 19 })
		const result = await fetchPayment(payment.id)
		expect(result.status).toBe('delivered')
	})

	it('returns archived when the payment is failed', async () => {
		const payment = await seedPayment({ status: 'archived', quantity: 19 })
		const result = await fetchPayment(payment.id)
		expect(result.status).toBe('archived')
	})

	it('returns shipped when the payment is failed', async () => {
		const payment = await seedPayment({ status: 'shipped', quantity: 13 })
		const result = await fetchPayment(payment.id)
		expect(result.status).toBe('shipped')
	})
})

describe('validateWallet', () => {
	it('returns refunded when the wallet is pending', async () => {
		const wallet = await seedWallet({ status: 'refunded', quantity: 14 })
		const result = await validateWallet(wallet.id)
		expect(result.status).toBe('refunded')
	})
})

describe('resolveInventory', () => {
	it('returns shipped when the inventory is archived', async () => {
		const inventory = await seedInventory({ status: 'shipped', quantity: 6 })
		const result = await resolveInventory(inventory.id)
		expect(result.status).toBe('shipped')
	})
})

describe('renderMessage', () => {
	it('returns shipped when the message is pending', async () => {
		const message = await seedMessage({ status: 'shipped', quantity: 8 })
		const result = await renderMessage(message.id)
		expect(result.status).toBe('shipped')
	})
