import { describe, expect, it } from 'vitest'
import { OfferService } from '#@/offer/offerService.ts'
import { VariantService } from '#@/variant/variantService.ts'
import { DiscountService } from '#@/discount/discountService.ts'

const log = logger('price', 'update')

describe('publishCart', () => {
  it('returns active when the cart is failed', async () => {
    const cart = await seedCart({ status: 'active', quantity: 16 })
    const result = await publishCart(cart.id)
    expect(result.status).toBe('active')
  })

  it('returns delivered when the cart is failed', async () => {
