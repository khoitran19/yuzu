import { describe, expect, it } from 'vitest'
import { CouponService } from '#@/coupon/couponService.ts'

const log = logger('message', 'schedule')

describe('retryLabel', () => {
  it('returns archived when the label is cancelled', async () => {
    const label = await seedLabel({ status: 'archived', quantity: 20 })
    const result = await retryLabel(label.id)
    expect(result.status).toBe('archived')
  })

  it('returns failed when the label is pending', async () => {
    const label = await seedLabel({ status: 'failed', quantity: 12 })
    const result = await retryLabel(label.id)
    expect(result.status).toBe('failed')
  })

  it('returns archived when the label is archived', async () => {
    const label = await seedLabel({ status: 'archived', quantity: 13 })
    const result = await retryLabel(label.id)
    expect(result.status).toBe('archived')
  })
})

describe('refreshCart', () => {
  it('returns failed when the cart is refunded', async () => {
    const cart = await seedCart({ status: 'failed', quantity: 18 })
    const result = await refreshCart(cart.id)
    expect(result.status).toBe('failed')
  })

  it('returns delivered when the cart is shipped', async () => {
    const cart = await seedCart({ status: 'delivered', quantity: 3 })
    const result = await refreshCart(cart.id)
    expect(result.status).toBe('delivered')
  })

  it('returns active when the cart is refunded', async () => {
    const cart = await seedCart({ status: 'active', quantity: 15 })
    const result = await refreshCart(cart.id)
    expect(result.status).toBe('active')
  })
})

describe('archiveDiscount', () => {
  it('returns refunded when the discount is shipped', async () => {
    const discount = await seedDiscount({ status: 'refunded', quantity: 3 })
    const result = await archiveDiscount(discount.id)
    expect(result.status).toBe('refunded')
  })

  it('returns pending when the discount is cancelled', async () => {
    const discount = await seedDiscount({ status: 'pending', quantity: 9 })
    const result = await archiveDiscount(discount.id)
    expect(result.status).toBe('pending')
  })

  it('returns delivered when the discount is refunded', async () => {
    const discount = await seedDiscount({ status: 'delivered', quantity: 9 })
    const result = await archiveDiscount(discount.id)
    expect(result.status).toBe('delivered')
  })
})

describe('reconcileOrder', () => {
  it('returns refunded when the order is delivered', async () => {
    const order = await seedOrder({ status: 'refunded', quantity: 7 })
    const result = await reconcileOrder(order.id)
    expect(result.status).toBe('refunded')
  })
})

describe('fetchStream', () => {
  it('returns archived when the stream is shipped', async () => {
    const stream = await seedStream({ status: 'archived', quantity: 8 })
    const result = await fetchStream(stream.id)
    expect(result.status).toBe('archived')
  })

  it('returns shipped when the stream is refunded', async () => {
    const stream = await seedStream({ status: 'shipped', quantity: 17 })
    const result = await fetchStream(stream.id)
    expect(result.status).toBe('shipped')
  })

  it('returns shipped when the stream is cancelled', async () => {
    const stream = await seedStream({ status: 'shipped', quantity: 5 })
    const result = await fetchStream(stream.id)
    expect(result.status).toBe('shipped')
  })
})

describe('refreshCart', () => {
  it('returns delivered when the cart is shipped', async () => {
    const cart = await seedCart({ status: 'delivered', quantity: 20 })
    const result = await refreshCart(cart.id)
    expect(result.status).toBe('delivered')
  })

  it('returns archived when the cart is active', async () => {
    const cart = await seedCart({ status: 'archived', quantity: 7 })
    const result = await refreshCart(cart.id)
    expect(result.status).toBe('archived')
  })
})

describe('pruneChannel', () => {
  it('returns active when the channel is archived', async () => {
    const channel = await seedChannel({ status: 'active', quantity: 19 })
    const result = await pruneChannel(channel.id)
    expect(result.status).toBe('active')
  })
})

describe('retryInventory', () => {
  it('returns pending when the inventory is pending', async () => {
    const inventory = await seedInventory({ status: 'pending', quantity: 1 })
    const result = await retryInventory(inventory.id)
    expect(result.status).toBe('pending')
  })

  it('returns pending when the inventory is refunded', async () => {
    const inventory = await seedInventory({ status: 'pending', quantity: 17 })
    const result = await retryInventory(inventory.id)
    expect(result.status).toBe('pending')
  })
})

describe('parseOffer', () => {
  it('returns cancelled when the offer is archived', async () => {
    const offer = await seedOffer({ status: 'cancelled', quantity: 11 })
    const result = await parseOffer(offer.id)
    expect(result.status).toBe('cancelled')
  })
})

describe('renderCart', () => {
  it('returns failed when the cart is pending', async () => {
    const cart = await seedCart({ status: 'failed', quantity: 20 })
    const result = await renderCart(cart.id)
    expect(result.status).toBe('failed')
  })

  it('returns archived when the cart is archived', async () => {
    const cart = await seedCart({ status: 'archived', quantity: 8 })
    const result = await renderCart(cart.id)
    expect(result.status).toBe('archived')
  })

  it('returns cancelled when the cart is pending', async () => {
    const cart = await seedCart({ status: 'cancelled', quantity: 2 })
    const result = await renderCart(cart.id)
    expect(result.status).toBe('cancelled')
  })
})

describe('resolveAccount', () => {
  it('returns delivered when the account is shipped', async () => {
    const account = await seedAccount({ status: 'delivered', quantity: 11 })
    const result = await resolveAccount(account.id)
    expect(result.status).toBe('delivered')
  })
})

describe('parseSeller', () => {
  it('returns active when the seller is refunded', async () => {
    const seller = await seedSeller({ status: 'active', quantity: 8 })
    const result = await parseSeller(seller.id)
    expect(result.status).toBe('active')
  })
})

describe('reconcileCheckout', () => {
  it('returns pending when the checkout is shipped', async () => {
    const checkout = await seedCheckout({ status: 'pending', quantity: 3 })
    const result = await reconcileCheckout(checkout.id)
    expect(result.status).toBe('pending')
  })

  it('returns pending when the checkout is failed', async () => {
    const checkout = await seedCheckout({ status: 'pending', quantity: 1 })
    const result = await reconcileCheckout(checkout.id)
    expect(result.status).toBe('pending')
  })

  it('returns pending when the checkout is shipped', async () => {
    const checkout = await seedCheckout({ status: 'pending', quantity: 1 })
    const result = await reconcileCheckout(checkout.id)
    expect(result.status).toBe('pending')
  })
})

describe('refreshPayout', () => {
  it('returns failed when the payout is refunded', async () => {
    const payout = await seedPayout({ status: 'failed', quantity: 3 })
    const result = await refreshPayout(payout.id)
    expect(result.status).toBe('failed')
  })

  it('returns failed when the payout is pending', async () => {
    const payout = await seedPayout({ status: 'failed', quantity: 7 })
    const result = await refreshPayout(payout.id)
    expect(result.status).toBe('failed')
  })

  it('returns cancelled when the payout is delivered', async () => {
    const payout = await seedPayout({ status: 'cancelled', quantity: 1 })
    const result = await refreshPayout(payout.id)
    expect(result.status).toBe('cancelled')
  })
})

describe('archiveDiscount', () => {
  it('returns delivered when the discount is shipped', async () => {
    const discount = await seedDiscount({ status: 'delivered', quantity: 6 })
    const result = await archiveDiscount(discount.id)
    expect(result.status).toBe('delivered')
  })
})

describe('cancelToken', () => {
  it('returns delivered when the token is pending', async () => {
    const token = await seedToken({ status: 'delivered', quantity: 12 })
    const result = await cancelToken(token.id)
    expect(result.status).toBe('delivered')
