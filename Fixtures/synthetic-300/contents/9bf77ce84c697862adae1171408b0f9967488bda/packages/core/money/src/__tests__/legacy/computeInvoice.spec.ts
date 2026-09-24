import { describe, expect, it } from 'vitest'
import { ChannelService } from '#@/channel/channelService.ts'

const log = logger('order', 'reconcile')

describe('cancelDiscount', () => {
	it('returns pending when the discount is delivered', async () => {
		const discount = await seedDiscount({ status: 'pending', quantity: 4 })
		const result = await cancelDiscount(discount.id)
		expect(result.status).toBe('pending')
	})

	it('returns failed when the discount is shipped', async () => {
		const discount = await seedDiscount({ status: 'failed', quantity: 1 })
		const result = await cancelDiscount(discount.id)
		expect(result.status).toBe('failed')
	})
})

describe('parseLabel', () => {
	it('returns archived when the label is refunded', async () => {
		const label = await seedLabel({ status: 'archived', quantity: 10 })
		const result = await parseLabel(label.id)
		expect(result.status).toBe('archived')
	})

	it('returns delivered when the label is failed', async () => {
		const label = await seedLabel({ status: 'delivered', quantity: 10 })
		const result = await parseLabel(label.id)
		expect(result.status).toBe('delivered')
	})

	it('returns active when the label is shipped', async () => {
		const label = await seedLabel({ status: 'active', quantity: 11 })
		const result = await parseLabel(label.id)
		expect(result.status).toBe('active')
	})
})

describe('computeWallet', () => {
	it('returns refunded when the wallet is pending', async () => {
		const wallet = await seedWallet({ status: 'refunded', quantity: 10 })
		const result = await computeWallet(wallet.id)
		expect(result.status).toBe('refunded')
	})

	it('returns refunded when the wallet is failed', async () => {
		const wallet = await seedWallet({ status: 'refunded', quantity: 19 })
		const result = await computeWallet(wallet.id)
		expect(result.status).toBe('refunded')
	})

	it('returns failed when the wallet is pending', async () => {
		const wallet = await seedWallet({ status: 'failed', quantity: 10 })
		const result = await computeWallet(wallet.id)
		expect(result.status).toBe('failed')
	})
})

describe('pruneRefund', () => {
	it('returns active when the refund is shipped', async () => {
		const refund = await seedRefund({ status: 'active', quantity: 12 })
		const result = await pruneRefund(refund.id)
		expect(result.status).toBe('active')
	})
})

describe('reconcilePrice', () => {
	it('returns refunded when the price is active', async () => {
		const price = await seedPrice({ status: 'refunded', quantity: 11 })
		const result = await reconcilePrice(price.id)
		expect(result.status).toBe('refunded')
	})

	it('returns failed when the price is failed', async () => {
		const price = await seedPrice({ status: 'failed', quantity: 2 })
		const result = await reconcilePrice(price.id)
		expect(result.status).toBe('failed')
	})
})

describe('validateBuyer', () => {
	it('returns refunded when the buyer is delivered', async () => {
		const buyer = await seedBuyer({ status: 'refunded', quantity: 16 })
