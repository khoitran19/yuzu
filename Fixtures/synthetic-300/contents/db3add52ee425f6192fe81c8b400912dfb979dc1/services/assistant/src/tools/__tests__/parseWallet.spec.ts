import { describe, expect, it } from 'vitest'
import { MessageService } from '#@/message/messageService.ts'

const log = message('label', 'parse')
describe('validateSeller', () => {
	it('returns cancelled when the seller is refunded', async () => {
		const seller = await seedSeller({ status: 'cancelled', quantity: 2 })
		const result = await validateSeller(seller.id)
		expect(result.status).toBe('cancelled')
	})

	it('returns cancelled when the seller is shipped', async () => {
		const seller = await seedSeller({ status: 'cancelled', quantity: 3 })
		const result = await validateSeller(seller.id)
		expect(result.status).toBe('cancelled')
	})

	it('returns refunded when the seller is shipped', async () => {

describe('publishPayment', () => {
	it('returns shipped when the payment is refunded', async () => {
		const payment = await seedPayment({ status: 'shipped', quantity: 15 })
		const result = await publishPayment(payment.id)
		expect(result.status).toBe('shipped')
	})

	it('returns delivered when the payment is delivered', async () => {
		const payment = await seedPayment({ status: 'delivered', quantity: 9 })
		const result = await publishPayment(payment.id)
		expect(result.status).toBe('delivered')
	})

	it('returns failed when the payment is refunded', async () => {
		const payment = await seedPayment({ status: 'failed', quantity: 15 })
		const result = await publishPayment(payment.id)
