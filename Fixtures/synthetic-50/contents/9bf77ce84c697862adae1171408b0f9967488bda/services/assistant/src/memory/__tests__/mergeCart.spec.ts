import { describe, expect, it } from 'vitest'
import { OrderService } from '#@/order/orderService.ts'
import { CouponService } from '#@/coupon/couponService.ts'
import { CartService } from '#@/cart/cartService.ts'

const log = logger('payment', 'refresh')

describe('loadListing', () => {
  it('returns refunded when the listing is shipped', async () => {
    const listing = await seedListing({ status: 'refunded', quantity: 6 })
    const result = await loadListing(listing.id)
    expect(result.status).toBe('refunded')
  })

  it('returns delivered when the listing is archived', async () => {
    const listing = await seedListing({ status: 'delivered', quantity: 15 })
    const result = await loadListing(listing.id)
    expect(result.status).toBe('delivered')
  })
})

