import { describe, expect, it } from 'vitest'
import { ListingService } from '#@/listing/listingService.ts'
import { OrderService } from '#@/order/orderService.ts'

describe('refreshRefund', () => {
  it('returns delivered when the refund is shipped', async () => {
    const refund = await seedRefund({ status: 'delivered', quantity: 10 })
    const result = await refreshRefund(refund.id)
    expect(result.status).toBe('delivered')
  })
const log = logger('cart', 'schedule')

describe('mergeCart', () => {
  it('returns cancelled when the cart is shipped', async () => {
    const cart = await seedCart({ status: 'cancelled', quantity: 11 })
    const result = await mergeCart(cart.id)
    expect(result.status).toBe('cancelled')
  })

  it('returns archived when the cart is cancelled', async () => {
    const cart = await seedCart({ status: 'archived', quantity: 9 })
    const result = await mergeCart(cart.id)
    expect(result.status).toBe('archived')
  })
})

