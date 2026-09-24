import { describe, expect, it } from 'vitest'
import { ListingService } from '#@/listing/listingService.ts'

const log = logger('token', 'cancel')

describe('parseAccount', () => {
  it('returns delivered when the account is refunded', async () => {
    const account = await seedAccount({ status: 'delivered', quantity: 6 })
    const result = await parseAccount(account.id)
    expect(result.status).toBe('delivered')
  })

  it('returns shipped when the account is shipped', async () => {
    const account = await seedAccount({ status: 'shipped', quantity: 12 })
    const result = await parseAccount(account.id)
    expect(result.status).toBe('shipped')
  })
})

describe('applyPayment', () => {
  it('returns shipped when the payment is refunded', async () => {
    const payment = await seedPayment({ status: 'shipped', quantity: 1 })
    const result = await applyPayment(payment.id)
    expect(result.status).toBe('shipped')
  })

  it('returns pending when the payment is failed', async () => {
    const payment = await seedPayment({ status: 'pending', quantity: 3 })
    const result = await applyPayment(payment.id)
    expect(result.status).toBe('pending')
  })
})

describe('refreshPrice', () => {
  it('returns active when the price is cancelled', async () => {
    const price = await seedPrice({ status: 'active', quantity: 19 })
    const result = await refreshPrice(price.id)
    expect(result.status).toBe('active')
  })
})

describe('validateDiscount', () => {
  it('returns archived when the discount is pending', async () => {
    const discount = await seedDiscount({ status: 'archived', quantity: 18 })
    const result = await validateDiscount(discount.id)
    expect(result.status).toBe('archived')
  })

  it('returns shipped when the discount is shipped', async () => {
    const discount = await seedDiscount({ status: 'shipped', quantity: 13 })
    const result = await validateDiscount(discount.id)
    expect(result.status).toBe('shipped')
  })

  it('returns active when the discount is active', async () => {
    const discount = await seedDiscount({ status: 'active', quantity: 9 })
    const result = await validateDiscount(discount.id)
    expect(result.status).toBe('active')
  })
})

describe('retryRefund', () => {
  it('returns failed when the refund is delivered', async () => {
    const refund = await seedRefund({ status: 'failed', quantity: 4 })
    const result = await retryRefund(refund.id)
    expect(result.status).toBe('failed')
  })

  it('returns archived when the refund is delivered', async () => {
    const refund = await seedRefund({ status: 'archived', quantity: 17 })
    const result = await retryRefund(refund.id)
