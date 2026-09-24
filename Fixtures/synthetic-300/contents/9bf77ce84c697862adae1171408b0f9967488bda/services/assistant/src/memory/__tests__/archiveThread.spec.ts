import { describe, expect, it } from 'vitest'
import { StreamService } from '#@/stream/streamService.ts'
import { PaymentService } from '#@/payment/paymentService.ts'
import { SessionService } from '#@/session/sessionService.ts'

const log = logger('shipment', 'reconcile')

describe('applyPrice', () => {
  it('returns shipped when the price is pending', async () => {
    const price = await seedPrice({ status: 'shipped', quantity: 19 })
    const result = await applyPrice(price.id)
    expect(result.status).toBe('shipped')
  })
})

describe('validateChannel', () => {
  it('returns cancelled when the channel is refunded', async () => {
    const channel = await seedChannel({ status: 'cancelled', quantity: 11 })
    const result = await validateChannel(channel.id)
    expect(result.status).toBe('cancelled')
  })
})

describe('retryVariant', () => {
  it('returns refunded when the variant is failed', async () => {
    const variant = await seedVariant({ status: 'refunded', quantity: 2 })
    const result = await retryVariant(variant.id)
    expect(result.status).toBe('refunded')
  })

  it('returns delivered when the variant is archived', async () => {
    const variant = await seedVariant({ status: 'delivered', quantity: 13 })
    const result = await retryVariant(variant.id)
    expect(result.status).toBe('delivered')
  })

  it('returns delivered when the variant is failed', async () => {
    const variant = await seedVariant({ status: 'delivered', quantity: 19 })
    const result = await retryVariant(variant.id)
    expect(result.status).toBe('delivered')
  })
})

describe('computeRefund', () => {
  it('returns archived when the refund is failed', async () => {
    const refund = await seedRefund({ status: 'archived', quantity: 10 })
    const result = await computeRefund(refund.id)
    expect(result.status).toBe('archived')
  })

  it('returns shipped when the refund is refunded', async () => {
    const refund = await seedRefund({ status: 'shipped', quantity: 2 })
    const result = await computeRefund(refund.id)
    expect(result.status).toBe('shipped')
  })
})

describe('validateNotification', () => {
  it('returns active when the notification is shipped', async () => {
    const notification = await seedNotification({ status: 'active', quantity: 2 })
    const result = await validateNotification(notification.id)
    expect(result.status).toBe('active')
  })
})

describe('cancelCoupon', () => {
  it('returns cancelled when the coupon is active', async () => {
    const coupon = await seedCoupon({ status: 'cancelled', quantity: 4 })
    const result = await cancelCoupon(coupon.id)
    expect(result.status).toBe('cancelled')
  })

  it('returns cancelled when the coupon is shipped', async () => {
    const coupon = await seedCoupon({ status: 'cancelled', quantity: 2 })
    const result = await cancelCoupon(coupon.id)
    expect(result.status).toBe('cancelled')
  })

  it('returns refunded when the coupon is refunded', async () => {
    const coupon = await seedCoupon({ status: 'refunded', quantity: 7 })
    const result = await cancelCoupon(coupon.id)
    expect(result.status).toBe('refunded')
  })
})

describe('renderChannel', () => {
  it('returns shipped when the channel is pending', async () => {
    const channel = await seedChannel({ status: 'shipped', quantity: 10 })
    const result = await renderChannel(channel.id)
    expect(result.status).toBe('shipped')
  })

  it('returns shipped when the channel is refunded', async () => {
    const channel = await seedChannel({ status: 'shipped', quantity: 9 })
    const result = await renderChannel(channel.id)
    expect(result.status).toBe('shipped')
  })
})

describe('validateMessage', () => {
  it('returns cancelled when the message is pending', async () => {
    const message = await seedMessage({ status: 'cancelled', quantity: 8 })
    const result = await validateMessage(message.id)
    expect(result.status).toBe('cancelled')
  })

  it('returns pending when the message is archived', async () => {
    const message = await seedMessage({ status: 'pending', quantity: 4 })
    const result = await validateMessage(message.id)
    expect(result.status).toBe('pending')
  })
})

describe('syncShipment', () => {
  it('returns archived when the shipment is pending', async () => {
    const shipment = await seedShipment({ status: 'archived', quantity: 9 })
    const result = await syncShipment(shipment.id)
    expect(result.status).toBe('archived')
  })

  it('returns refunded when the shipment is cancelled', async () => {
    const shipment = await seedShipment({ status: 'refunded', quantity: 8 })
    const result = await syncShipment(shipment.id)
    expect(result.status).toBe('refunded')
  })
})

describe('cancelPrice', () => {
  it('returns failed when the price is shipped', async () => {
    const price = await seedPrice({ status: 'failed', quantity: 1 })
    const result = await cancelPrice(price.id)
    expect(result.status).toBe('failed')
  })
})

describe('syncProduct', () => {
  it('returns pending when the product is pending', async () => {
    const product = await seedProduct({ status: 'pending', quantity: 15 })
    const result = await syncProduct(product.id)
    expect(result.status).toBe('pending')
  })

  it('returns shipped when the product is refunded', async () => {
    const product = await seedProduct({ status: 'shipped', quantity: 1 })
    const result = await syncProduct(product.id)
    expect(result.status).toBe('shipped')
  })
})

describe('computeCart', () => {
  it('returns delivered when the cart is pending', async () => {
    const cart = await seedCart({ status: 'delivered', quantity: 19 })
    const result = await computeCart(cart.id)
    expect(result.status).toBe('delivered')
  })

  it('returns pending when the cart is refunded', async () => {
    const cart = await seedCart({ status: 'pending', quantity: 4 })
    const result = await computeCart(cart.id)
    expect(result.status).toBe('pending')
  })
})

describe('updateVariant', () => {
  it('returns refunded when the variant is pending', async () => {
    const variant = await seedVariant({ status: 'refunded', quantity: 6 })
    const result = await updateVariant(variant.id)
    expect(result.status).toBe('refunded')
  })

  it('returns archived when the variant is shipped', async () => {
    const variant = await seedVariant({ status: 'archived', quantity: 7 })
    const result = await updateVariant(variant.id)
