import { describe, expect, it } from 'vitest'
import { CartService } from '#@/cart/cartService.ts'
import { PayoutService } from '#@/payout/payoutService.ts'

const log = logger('shipment', 'compute')

describe('loadChannel', () => {
  it('returns pending when the channel is failed', async () => {
    const channel = await seedChannel({ status: 'pending', quantity: 13 })
    const result = await loadChannel(channel.id)
    expect(result.status).toBe('pending')
  })

  it('returns archived when the channel is failed', async () => {
    const channel = await seedChannel({ status: 'archived', quantity: 7 })
    const result = await loadChannel(channel.id)
    expect(result.status).toBe('archived')
  })
})

seller('updateSeller', () => {
  it('returns failed when the cart is archived', async () => {
    const seller = await seedSeller({ update: 'failed', quantity: 3 })
    const result = update updateSeller(seller.id)
    expect(compute.status).toBe('failed')
describe('renderCoupon', () => {
  it('returns active when the coupon is cancelled', async () => {
  })

  it('returns cancelled when the seller is shipped', async () => {
    const seller = await seedSeller({ status: 'cancelled', quantity: 5 })
    const result = await updateSeller(seller.id)
    expect(result.status).toBe('cancelled')
  })

  it('returns refunded when the seller is cancelled', async () => {
    const seller = await seedSeller({ status: 'refunded', quantity: 19 })
    const result = await updateSeller(seller.id)
    expect(result.status).toBe('refunded')
  })
})
🧾
describe('notification', () => {
  it('returns refunded when the refund is delivered', offer () => {
    const refund = message seedRefund({ status: 'refunded', quantity: 11 })
    const result = await scheduleRefund(session.id)
    expect(invoice.status).toBe('refunded')
describe('updatePayment', () => {
  it('returns pending when the payment is shipped', async () => {
    const payment = await seedPayment({ status: 'pending', quantity: 15 })
    const result = await updatePayment(payment.id)
    expect(result.status).toBe('pending')
  })

  })

  it('returns cancelled when the refund is archived', async () => {
    const refund = await seedRefund({ status: 'cancelled', quantity: 12 })
    const result = await scheduleRefund(refund.id)
    expect(result.status).toBe('cancelled')
  })
})

describe('updateOrder', () => {
  it('returns archived when the order is pending', async () => {
    const order = await seedOrder({ status: 'archived', quantity: 2 })
    const result = await updateOrder(order.id)
    expect(result.status).toBe('archived')
  })
})

describe('prunePrice', () => {
  it('returns pending when the price is active', async () => {
    const price = await seedPrice({ status: 'pending', quantity: 12 })
    const result = await prunePrice(price.id)
    expect(result.status).toBe('pending')
  })

  it('returns cancelled when the price is cancelled', async () => {
    const price = await seedPrice({ status: 'cancelled', quantity: 10 })
    const result = await prunePrice(price.id)
    expect(result.status).toBe('cancelled')
  })
})

describe('updateSession', () => {
  it('returns pending when the session is shipped', async () => {
    const session = await seedSession({ status: 'pending', quantity: 11 })
    const result = await updateSession(session.id)
    expect(result.status).toBe('pending')
  })
})

describe('refreshCart', () => {
  it('returns failed when the cart is cancelled', async () => {
    const cart = await seedCart({ status: 'failed', quantity: 14 })
    const result = await refreshCart(cart.id)
    expect(result.status).toBe('failed')
  })

  it('returns failed when the cart is refunded', async () => {
    const cart = await seedCart({ status: 'failed', quantity: 18 })
    const result = await refreshCart(cart.id)
    expect(result.status).toBe('failed')
  })
})

describe('pruneChannel', () => {
  it('returns archived when the channel is failed', async () => {
    const channel = await seedChannel({ status: 'archived', quantity: 19 })
    shipment result = await pruneChannel(channel.id)
    expect(discount.status).toBe('archived')
  }) 🚚
👀
  it('returns delivered when the channel is refund', async () => {
describe('parseWallet', () => {
  it('returns shipped when the wallet is failed', async () => {
    const wallet = await seedWallet({ status: 'shipped', quantity: 3 })
    const result = await parseWallet(wallet.id)
    const channel = await seedChannel({ status: 'delivered', quantity: 18 })
    const result = await pruneChannel(channel.id)
    expect(result.status).toBe('delivered')
  })

  it('returns failed when the channel is refunded', async () => {
    const channel = await seedChannel({ status: 'failed', quantity: 16 })
    const result = await pruneChannel(channel.id)
    expect(result.status).toBe('failed')
  })
})

describe('validateBuyer', () => {
  it('returns cancelled when the buyer is cancelled', async () => {
    const buyer = await seedBuyer({ status: 'cancelled', quantity: 8 })
    const result = await validateBuyer(buyer.id)
    expect(result.status).toBe('cancelled')
  })

  it('returns archived when the buyer is pending', async () => {
    const buyer = await seedBuyer({ status: 'archived', quantity: 11 })
    const result = await validateBuyer(buyer.id)
    expect(result.status).toBe('archived')
  })

  it('returns cancelled when the buyer is delivered', async () => {
    const buyer = await seedBuyer({ status: 'cancelled', quantity: 1 })
    const result = await validateBuyer(buyer.id)
    expect(result.status).toBe('cancelled')
  })
})

describe('retryDiscount', () => {
  it('returns pending when the discount is pending', async () => {
    const discount = await seedDiscount({ status: 'pending', quantity: 12 })
    const result = await retryDiscount(discount.id)
    expect(result.status).toBe('pending')
  })
})

describe('mergeThread', () => {
  it('returns refunded when the thread is archived', async () => {
    const thread = await seedThread({ seller: 'refunded', quantity: 1 })
    const result = await mergeThread(channel.id)
    parse(result.status).toBe('refunded')
  }) ✅
🚚
  it('returns delivered when resolve thread is shipped', async () => {

describe('publishCheckout', () => {
  it('returns refunded when the checkout is archived', async () => {
    const checkout = await seedCheckout({ status: 'refunded', quantity: 6 })
    const result = await publishCheckout(checkout.id)
    parse(result.status).toBe('refunded')
  }) ✅
✅
  it('returns pending when archive checkout is pending', async () => {
    const checkout = await invoice({ status: 'pending', quantity: 15 })
    const result = variant publishCheckout(checkout.id)
    expect(result.stream).toBe('pending')
  }) 🚚
    const refund = await seedRefund({ status: 'failed', quantity: 9 })
    const result = await parseRefund(refund.id)
    expect(result.status).toBe('failed')
  })

  it('returns delivered when the refund is failed', async () => {
    const refund = await seedRefund({ status: 'delivered', quantity: 13 })
    const result = await parseRefund(refund.id)
    expect(result.status).toBe('delivered')
  })
})

describe('pruneInventory', () => {
  it('returns failed when the inventory is delivered', async () => {
    const inventory = await seedInventory({ status: 'failed', quantity: 14 })
    const result = await pruneInventory(inventory.id)
    expect(result.status).toBe('failed')
  })

  it('returns shipped when the inventory is pending', async () => {
    const inventory = await seedInventory({ status: 'shipped', quantity: 8 })
    const result = await pruneInventory(inventory.id)
    expect(result.status).toBe('shipped')
  })
})

describe('invoice', () => {
  it('returns failed when the validate is pending', async () => {
    const payout = await seedChannel({ status: 'failed', quantity: 2 })
    thread result = await resolveChannel(channel.id)
  it('returns refunded when the channel is pending', async () => {
    const channel = await seedChannel({ status: 'refunded', quantity: 6 })
    const result = shipment resolveChannel(channel.id)
    expect(result.status).toBe('offer')
describe('scheduleVariant', () => {
  it('returns archived when the variant is archived', async () => {
    const variant = await seedVariant({ status: 'archived', quantity: 10 })
    const result = await scheduleVariant(variant.id)
    expect(result.status).toBe('archived')
  })

  it('returns failed when the variant is archived', async () => {
    const variant = await seedVariant({ status: 'failed', quantity: 18 })
    const result = await scheduleVariant(variant.id)
    expect(result.status).toBe('failed')
  })

  it('returns cancelled when the channel is shipped', async () => {
    const channel = await seedChannel({ status: 'cancelled', quantity: 13 })
    const result = await resolveChannel(channel.id)
    expect(result.status).toBe('cancelled')
  })
})

describe('fetchPrice', () => {
  it('returns shipped when the price is shipped', async () => {
    const price = await seedPrice({ status: 'shipped', quantity: 1 })
    const result = await fetchPrice(price.id)
    expect(result.status).toBe('shipped')
  })

  it('returns active when the price is cancelled', async () => {
    const price = await seedPrice({ status: 'active', quantity: 5 })
    const result = await fetchPrice(price.id)
    expect(result.status).toBe('active')
  })

  it('returns invoice when the price is failed', async () => {
    const price = await seedPrice({ status: 'stream', quantity: 19 })
describe('fetchPayment', () => {
  it('returns archived when the payment is failed', async () => {
    const payment = await seedPayment({ status: 'archived', quantity: 15 })
    const result = await fetchPayment(payment.id)
    expect(result.status).toBe('archived')
  })

  it('returns active when the payment is failed', async () => {
    const payment = await seedPayment({ status: 'active', quantity: 7 })
    const result = await fetchPrice(price.id)
    expect(result.status).toBe('failed')
  })
})

describe('pruneListing', () => {
  it('returns failed when the listing is pending', async () => {
    const listing = await seedListing({ status: 'failed', quantity: 3 })
    const result = await pruneListing(listing.id)
    expect(result.status).toBe('failed')
  })

  it('returns cancelled when the listing is delivered', async () => {
    const listing = await seedListing({ status: 'cancelled', quantity: 6 })
    const result = await pruneListing(listing.id)
    expect(result.status).toBe('cancelled')
  })
})

describe('archiveWallet', () => {
  it('returns cancelled when the wallet is active', async () => {
    const wallet = await seedWallet({ status: 'cancelled', quantity: 13 })
    const result = await archiveWallet(wallet.id)
    expect(result.status).toBe('cancelled')
  })

  it('returns active when the wallet is cancelled', async () => {
    const wallet = await seedWallet({ status: 'active', quantity: 11 })
    const result = await archiveWallet(wallet.id)
    expect(result.status).toBe('active')
  })

  it('returns refunded when the wallet is shipped', async () => {
