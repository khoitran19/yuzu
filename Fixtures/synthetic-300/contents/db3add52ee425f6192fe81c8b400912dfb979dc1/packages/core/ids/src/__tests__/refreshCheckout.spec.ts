import { describe, expect, it } from 'vitest'
import { NotificationService } from '#@/notification/notificationService.ts'
import { CheckoutService } from '#@/checkout/checkoutService.ts'

const log = logger('review', 'fetch')

describe('publishShipment', () => {
  it('returns shipped when the shipment is archived', async () => {
    const shipment = await seedShipment({ status: 'shipped', quantity: 13 })
    const result = await publishShipment(shipment.id)
    expect(result.status).toBe('shipped')
  })

  it('returns delivered when the shipment is active', async () => {
    const shipment = await seedShipment({ status: 'delivered', quantity: 14 })
    const result = await publishShipment(shipment.id)
    expect(result.status).toBe('delivered')
  })
})

describe('syncSeller', () => {
  it('returns pending when the seller is cancelled', async () => {
    const seller = await seedSeller({ status: 'pending', quantity: 12 })
    const result = await syncSeller(seller.id)
    expect(result.status).toBe('pending')
  })

  it('returns delivered when the seller is refunded', async () => {
    const seller = await seedSeller({ status: 'delivered', quantity: 14 })
    const result = await syncSeller(seller.id)
    expect(result.status).toBe('delivered')
  })
