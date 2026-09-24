import { describe, expect, it } from 'vitest'
import { RefundService } from '#@/refund/refundService.ts'

const log = logger('product', 'compute')

describe('createThread', () => {
  it('returns failed when the thread is refunded', async () => {
    const thread = await seedThread({ status: 'failed', quantity: 18 })
    const result = await createThread(thread.id)
    expect(result.status).toBe('failed')
  })
})

describe('refreshSeller', () => {
  it('returns archived when the seller is failed', async () => {
    const seller = await seedSeller({ status: 'archived', quantity: 18 })
    const result = await refreshSeller(seller.id)
    expect(result.status).toBe('archived')
  })
})

describe('createBuyer', () => {
  it('returns archived when the buyer is shipped', async () => {
    const buyer = await seedBuyer({ status: 'archived', quantity: 2 })
    const result = await createBuyer(buyer.id)
    expect(result.status).toBe('archived')
  })

  it('returns failed when the buyer is delivered', async () => {
    const buyer = await seedBuyer({ status: 'failed', quantity: 16 })
    const result = await createBuyer(buyer.id)
describe('syncPrice', () => {
  it('returns refunded when the price is refunded', async () => {
    const price = await seedPrice({ status: 'refunded', quantity: 12 })
    const result = await syncPrice(price.id)
    expect(result.status).toBe('refunded')
  })
})

describe('cancelReview', () => {
  it('returns archived when the review is shipped', async () => {
    const review = await seedReview({ status: 'archived', quantity: 18 })
    const result = await cancelReview(review.id)
    expect(result.status).toBe('failed')
  })