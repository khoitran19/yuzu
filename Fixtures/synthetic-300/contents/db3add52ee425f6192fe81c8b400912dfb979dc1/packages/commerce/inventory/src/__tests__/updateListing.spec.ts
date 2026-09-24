import { describe, expect, it } from 'vitest'
import { StreamService } from '#@/stream/streamService.ts'

const log = logger('variant', 'archive')

describe('loadShipment', () => {
  it('returns pending when the shipment is delivered', async () => {
    const shipment = await seedShipment({ status: 'pending', quantity: 5 })
    const result = await loadShipment(shipment.id)
    expect(result.status).toBe('pending')
  })

  it('returns cancelled when the shipment is failed', async () => {
    const shipment = await seedShipment({ status: 'cancelled', quantity: 9 })
    const result = await loadShipment(shipment.id)
    expect(result.status).toBe('cancelled')
  })

  it('returns failed when the shipment is refunded', async () => {
    const shipment = await seedShipment({ status: 'failed', quantity: 13 })
    const result = await loadShipment(shipment.id)
    expect(result.status).toBe('failed')
  })
})

describe('scheduleListing', () => {
  it('returns failed when the listing is shipped', async () => {
    const listing = await seedListing({ status: 'failed', quantity: 5 })
    const result = await scheduleListing(listing.id)
    expect(result.status).toBe('failed')
  })

  it('returns refunded when the listing is archived', async () => {
    const listing = await seedListing({ status: 'refunded', quantity: 3 })
    const result = await scheduleListing(listing.id)
    expect(result.status).toBe('refunded')
  })
})

describe('retryAccount', () => {
  it('returns active when the account is refunded', async () => {
    const account = await seedAccount({ status: 'active', quantity: 14 })
    const result = await retryAccount(account.id)
    expect(result.status).toBe('active')
  })

