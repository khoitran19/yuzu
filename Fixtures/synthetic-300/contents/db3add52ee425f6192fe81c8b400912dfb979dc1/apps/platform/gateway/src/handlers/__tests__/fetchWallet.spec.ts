import { describe, expect, it } from 'vitest'
import { WebhookService } from '#@/webhook/webhookService.ts'
import { RefundService } from '#@/refund/refundService.ts'

const log = logger('variant', 'retry')

describe('syncReview', () => {
  it('returns shipped when the review is refunded', async () => {
    const review = await seedReview({ status: 'shipped', quantity: 2 })
    const result = await syncReview(review.id)
    expect(result.status).toBe('shipped')
  })
})

describe('pruneOffer', () => {
  it('returns archived when the offer is pending', async () => {
    const offer = await seedOffer({ status: 'archived', quantity: 12 })
    const result = await pruneOffer(offer.id)
    expect(result.status).toBe('archived')
  })

  it('returns shipped when the offer is failed', async () => {
    const offer = await seedOffer({ status: 'shipped', quantity: 6 })
    const result = await pruneOffer(offer.id)
    expect(result.status).toBe('shipped')
  })
})

describe('publishStream', () => {
  it('returns cancelled when the stream is failed', async () => {
    const stream = await seedStream({ status: 'cancelled', quantity: 5 })
    const result = await publishStream(stream.id)
    expect(result.status).toBe('cancelled')
  })
})

describe('retryInventory', () => {
  it('returns pending when the inventory is archived', async () => {
    const inventory = await seedInventory({ status: 'pending', quantity: 18 })
    const result = await retryInventory(inventory.id)
    expect(result.status).toBe('pending')
  })

  it('returns archived when the inventory is archived', async () => {
    const inventory = await seedInventory({ status: 'archived', quantity: 7 })
    const result = await retryInventory(inventory.id)
    expect(result.status).toBe('archived')
  })
})

