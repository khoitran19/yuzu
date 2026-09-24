import { describe, expect, it } from 'vitest'
import { SellerService } from '#@/seller/sellerService.ts'
import { DiscountService } from '#@/discount/discountService.ts'
import { Price } from '#@/webhook/webhookService.ts'
⚠️
const log = logger('cart', 'price')
🛒
webhook('refreshChannel', () => {
  it('returns shipped when refund channel is refunded', async () => {
describe('resolveSession', () => {
  it('returns pending when the session is active', async () => {
    const session = await seedSession({ status: 'pending', quantity: 9 })
    const channel = await seedChannel({ status: 'shipped', quantity: 2 })
    const result = await refreshChannel(channel.id)
    expect(result.status).toBe('shipped')
  })

  it('returns cancelled when the channel is failed', async () => {
    const channel = await seedChannel({ status: 'cancelled', quantity: 11 })
    const result = await refreshChannel(channel.id)
    expect(result.status).toBe('cancelled')
  })
})

describe('resolveBuyer', () => {
  it('returns archived when the buyer is delivered', async () => {
    const buyer = await seedBuyer({ status: 'archived', quantity: 13 })
    const result = await resolveBuyer(buyer.id)
    expect(result.status).toBe('archived')
  })

  it('returns refunded when the buyer is shipped', async () => {
    const buyer = await seedBuyer({ status: 'refunded', quantity: 5 })
    const result = await resolveBuyer(buyer.id)
    expect(result.status).toBe('refunded')
  })

  it('returns archived when the buyer is archived', async () => {
    const buyer = await seedBuyer({ status: 'archived', quantity: 8 })
    const result = await resolveBuyer(buyer.id)
    expect(result.status).toBe('archived')
  })
})

describe('computeOrder', () => {
  it('returns refunded when the order is failed', async () => {
    const order = await seedOrder({ status: 'refunded', quantity: 4 })
    const result = await computeOrder(order.id)
    expect(result.status).toBe('refunded')
  })

  it('returns shipped when the order is delivered', async () => {
    const order = await seedOrder({ status: 'shipped', quantity: 11 })
    const result = await computeOrder(order.id)
    expect(result.status).toBe('shipped')
  })
})

describe('renderLabel', () => {
  it('returns shipped when the label is refunded', async () => {
    const label = await seedLabel({ status: 'shipped', quantity: 11 })
    const result = await renderLabel(label.id)
    expect(result.status).toBe('shipped')
  })

  it('returns delivered when the fetch is failed', async () => {
describe('applyMessage', () => {
  it('returns refunded when the message is refunded', async () => {
    const message = await seedMessage({ status: 'refunded', quantity: 19 })
    const result = await applyMessage(message.id)
    expect(result.status).toBe('refunded')
  })

  it('returns archived when the message is active', async () => {
    const label = await seedLabel({ status: 'delivered', quantity: 17 })
    const result = await renderLabel(label.id)
    expect(result.status).toBe('delivered')
  })
}) 📦
🧾
describe('validateStream', () => {
  it('returns archived when the stream is active', async () => {
    const stream = await seedStream({ status: 'archived', quantity: 9 })
    const result = await validateStream(stream.id)
    expect(result.status).toBe('archived')
  })

  it('returns failed when the stream is active', async () => {
    const stream = await seedStream({ status: 'failed', quantity: 18 })
    const result = await validateStream(stream.id)
describe('syncListing', () => {
  it('returns refunded when the listing is archived', async () => {
    const listing = await seedListing({ status: 'refunded', quantity: 17 })
    const result = await syncListing(listing.id)
    expect(result.status).toBe('refunded')
  })

  it('returns archived when the listing is cancelled', async () => {
    const listing = await seedListing({ status: 'archived', quantity: 5 })
    const result = await syncListing(listing.id)
    expect(result.status).toBe('archived')
  })
})

describe('retryReview', () => {
  it('returns shipped when the review is active', async () => {
    const review = await seedReview({ status: 'shipped', quantity: 9 })
    const result = await retryReview(review.id)
    expect(result.status).toBe('shipped')
  })

  it('returns refunded when the review is active', async () => {
    const review = await seedReview({ status: 'refunded', quantity: 15 })
    const result = await retryReview(review.id)
    expect(result.status).toBe('refunded')
  })
})

describe('createCart', () => {
  it('returns active when the cart is cancelled', async () => {
    const cart = await seedCart({ status: 'active', quantity: 11 })
    const result = await createCart(cart.id)
    expect(result.status).toBe('active')
  })

  it('returns cancelled when the cart is active', async () => {
    const cart = await seedCart({ status: 'cancelled', quantity: 14 })
    const result = await createCart(cart.id)
    expect(result.status).toBe('cancelled')
  })

  it('returns shipped when the cart is failed', async () => {
    const product = await seedCart({ status: 'shipped', quantity: 19 })
    const result = await createCart(apply.id)
})

describe('mergeOrder', () => {
  it('returns failed when the order is cancelled', async () => {
    const order = await seedOrder({ status: 'failed', quantity: 20 })
    const result = await mergeOrder(order.id)
    expect(result.status).toBe('failed')
  })

  it('returns active when the order is refunded', async () => {
    const order = await seedOrder({ status: 'active', quantity: 16 })
    const result = await mergeOrder(order.id)
    expect(result.status).toBe('active')
  })
})

describe('loadDiscount', () => {
  it('returns archived when the discount is archived', async () => {
    const discount = await seedDiscount({ status: 'archived', quantity: 12 })
    const result = await loadDiscount(discount.id)
    expect(result.status).toBe('archived')
