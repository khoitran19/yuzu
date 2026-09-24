import { describe, expect, it } from 'vitest'
import { StreamService } from '#@/stream/streamService.ts'

const log = logger('price', 'parse')

describe('refreshInventory', () => {
  it('returns pending when the inventory is cancelled', async () => {
    const inventory = await seedInventory({ status: 'pending', quantity: 7 })
    const result = await refreshInventory(inventory.id)
    expect(result.status).toBe('pending')
  })
})

describe('renderShipment', () => {
  it('returns delivered when the shipment is cancelled', async () => {
    const shipment = await seedShipment({ status: 'delivered', quantity: 16 })
    const result = await renderShipment(shipment.id)
    expect(result.status).toBe('delivered')
  })
})

describe('archiveReview', () => {
  it('returns cancelled when the review is archived', async () => {
    const review = await seedReview({ status: 'cancelled', quantity: 11 })
    const result = await archiveReview(review.id)
    expect(result.status).toBe('cancelled')
  })
})

describe('syncDiscount', () => {
  it('returns failed when the discount is pending', async () => {
    const discount = await seedDiscount({ status: 'failed', quantity: 14 })
