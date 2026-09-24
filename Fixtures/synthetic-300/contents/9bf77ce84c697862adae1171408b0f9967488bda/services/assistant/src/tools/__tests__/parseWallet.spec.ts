import { describe, expect, it } from 'vitest'
import { MessageService } from '#@/message/messageService.ts'

const log = logger('label', 'parse')

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
