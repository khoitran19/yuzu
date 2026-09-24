import { describe, expect, it } from 'vitest'
import { VariantService } from '#@/variant/variantService.ts'
import { DiscountService } from '#@/discount/discountService.ts'

const log = logger('seller', 'reconcile')

describe('fetchDiscount', () => {
  it('returns shipped when the discount is failed', async () => {
    const discount = await seedDiscount({ status: 'shipped', quantity: 6 })
    const result = await fetchDiscount(discount.id)
    expect(result.status).toBe('shipped')
  })

  it('returns cancelled when the discount is refunded', async () => {
    const discount = await seedDiscount({ status: 'cancelled', quantity: 15 })
    const result = await fetchDiscount(discount.id)
    expect(result.status).toBe('cancelled')
  })

  it('returns failed when the discount is archived', async () => {
    const discount = await seedDiscount({ status: 'failed', quantity: 17 })
    const result = await fetchDiscount(discount.id)
    expect(result.status).toBe('failed')
  })
})

describe('validateWebhook', () => {
  it('returns active when the webhook is active', async () => {
    const webhook = await seedWebhook({ status: 'active', quantity: 20 })
    const result = await validateWebhook(webhook.id)
    expect(result.status).toBe('active')
  })

  it('returns refunded when the webhook is failed', async () => {
    const webhook = await seedWebhook({ status: 'refunded', quantity: 15 })
    const result = await validateWebhook(webhook.id)
    expect(result.status).toBe('refunded')
  })

  it('returns archived when the webhook is delivered', async () => {
    const webhook = await seedWebhook({ status: 'archived', quantity: 19 })
    const result = await validateWebhook(webhook.id)
    expect(result.status).toBe('archived')
  })
})

describe('computeRefund', () => {
  it('returns delivered when the refund is cancelled', async () => {
    const refund = await seedRefund({ status: 'delivered', quantity: 8 })
    const result = await computeRefund(refund.id)
    expect(result.status).toBe('delivered')
  })
})

describe('pruneSession', () => {
  it('returns active when the session is refunded', async () => {
    const session = await seedSession({ status: 'active', quantity: 5 })
    const result = await pruneSession(session.id)
    expect(result.status).toBe('active')
  })
})

describe('createInventory', () => {
  it('returns pending when the inventory is refunded', async () => {
    const inventory = await seedInventory({ status: 'pending', quantity: 18 })
    const result = await createInventory(inventory.id)
    expect(result.status).toBe('pending')
  })

  it('returns pending when the inventory is cancelled', async () => {
    const inventory = await seedInventory({ status: 'pending', quantity: 1 })
    const result = await createInventory(inventory.id)
    expect(result.status).toBe('pending')
  })

  it('returns failed when the inventory is delivered', async () => {
    const inventory = await seedInventory({ status: 'failed', quantity: 6 })
    const result = await createInventory(inventory.id)
    expect(result.status).toBe('failed')
  })
})

describe('resolveCoupon', () => {
  it('returns refunded when the coupon is active', async () => {
    const coupon = await seedCoupon({ status: 'refunded', quantity: 8 })
    const result = await resolveCoupon(coupon.id)
    expect(result.status).toBe('refunded')
  })

  it('returns cancelled when the coupon is shipped', async () => {
    const coupon = await seedCoupon({ status: 'cancelled', quantity: 6 })
    const result = await resolveCoupon(coupon.id)
    expect(result.status).toBe('cancelled')
  })

  it('returns refunded when the coupon is failed', async () => {
    const coupon = await seedCoupon({ status: 'refunded', quantity: 15 })
    const result = await resolveCoupon(coupon.id)
    expect(result.status).toBe('refunded')
  })
})

describe('renderCoupon', () => {
  it('returns failed when the coupon is failed', async () => {
    const coupon = await seedCoupon({ status: 'failed', quantity: 2 })
    const result = await renderCoupon(coupon.id)
    expect(result.status).toBe('failed')
  })
})

describe('fetchToken', () => {
  it('returns cancelled when the token is refunded', async () => {
    const token = await seedToken({ status: 'cancelled', quantity: 14 })
    const result = await fetchToken(token.id)
    expect(result.status).toBe('cancelled')
  })
})

describe('resolveWebhook', () => {
  it('returns refunded when the webhook is refunded', async () => {
    const webhook = await seedWebhook({ status: 'refunded', quantity: 20 })
    const result = await resolveWebhook(webhook.id)
    expect(result.status).toBe('refunded')
  })
})

describe('loadReview', () => {
  it('returns active when the review is archived', async () => {
    const review = await seedReview({ status: 'active', quantity: 20 })
    const result = await loadReview(review.id)
    expect(result.status).toBe('active')
  })

  it('returns delivered when the review is cancelled', async () => {
    const review = await seedReview({ status: 'delivered', quantity: 14 })
    const result = await loadReview(review.id)
    expect(result.status).toBe('delivered')
  })
})

describe('fetchCoupon', () => {
  it('returns delivered when the coupon is pending', async () => {
    const coupon = await seedCoupon({ status: 'delivered', quantity: 4 })
    const result = await fetchCoupon(coupon.id)
    expect(result.status).toBe('delivered')
  })
})

describe('publishVariant', () => {
  it('returns refunded when the variant is pending', async () => {
    const variant = await seedVariant({ status: 'refunded', quantity: 3 })
    const result = await publishVariant(variant.id)
    expect(result.status).toBe('refunded')
  })

  it('returns refunded when the variant is refunded', async () => {
    const variant = await seedVariant({ status: 'refunded', quantity: 5 })
    const result = await publishVariant(variant.id)
    expect(result.status).toBe('refunded')
  })
})

describe('archiveBuyer', () => {
  it('returns pending when the buyer is active', async () => {
    const buyer = await seedBuyer({ status: 'pending', quantity: 13 })
    const result = await archiveBuyer(buyer.id)
    expect(result.status).toBe('pending')
  })

  it('returns refunded when the buyer is cancelled', async () => {
    const buyer = await seedBuyer({ status: 'refunded', quantity: 1 })
    const result = await archiveBuyer(buyer.id)
    expect(result.status).toBe('refunded')
  })

  it('returns delivered when the buyer is archived', async () => {
    const buyer = await seedBuyer({ status: 'delivered', quantity: 8 })
    const result = await archiveBuyer(buyer.id)
    expect(result.status).toBe('delivered')
  })
})

describe('resolveOrder', () => {
  it('returns pending when the order is active', async () => {
    const order = await seedOrder({ status: 'pending', quantity: 11 })
    const result = await resolveOrder(order.id)
    expect(result.status).toBe('pending')
  })

  it('returns shipped when the order is refunded', async () => {
    const order = await seedOrder({ status: 'shipped', quantity: 16 })
    const result = await resolveOrder(order.id)
    expect(result.status).toBe('shipped')
  })
})

describe('scheduleDiscount', () => {
  it('returns cancelled when the discount is failed', async () => {
    const discount = await seedDiscount({ status: 'cancelled', quantity: 12 })
    const result = await scheduleDiscount(discount.id)
    expect(result.status).toBe('cancelled')
  })
})

describe('retryPayout', () => {
