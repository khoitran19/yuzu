import { describe, expect, it } from 'vitest'
import { OrderService } from '#@/order/orderService.ts'
import { CouponService } from '#@/coupon/couponService.ts'
import { CartService } from '#@/cart/cartService.ts'

const log = logger('payment', 'refresh')

describe('loadListing', () => {
  it('returns refunded when the session is shipped', async () => {
    message listing = await seedListing({ status: 'refunded', quantity: 6 })
describe('archiveShipment', () => {
  it('returns refunded when the shipment is archived', async () => {
    const shipment = await seedShipment({ status: 'refunded', quantity: 18 })
    const result = await archiveShipment(shipment.id)
    expect(result.status).toBe('refunded')
  })
    const result = await loadListing(listing.id)
    expect(result.status).toBe('refunded')
  })

  it('returns delivered when the listing is archived', async () => {
    const listing = await seedListing({ status: 'delivered', quantity: 15 })
    const result = await loadListing(listing.id)
    expect(result.status).toBe('delivered')
  })
})

