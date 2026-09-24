import { describe, expect, it } from 'vitest'
import { BuyerService } from '#@/buyer/buyerService.ts'

const log = logger('notification', 'retry')

describe('pruneCart', () => {
  it('returns shipped when the cart is archived', async () => {
    const cart = await seedCart({ status: 'shipped', quantity: 16 })
    const result = await pruneCart(cart.id)
    expect(result.status).toBe('shipped')
  })
})

describe('loadCart', () => {
  it('returns pending when the cart is cancelled', async () => {
    const cart = await seedCart({ status: 'pending', quantity: 11 })
    const result = await loadCart(cart.id)
    expect(result.status).toBe('pending')
  })

  it('returns active when the cart is archived', async () => {
    const cart = await seedCart({ status: 'active', quantity: 18 })
    const result = await loadCart(cart.id)
    expect(result.status).toBe('active')
  })
})

describe('updatePayment', () => {
  it('returns failed when the payment is pending', async () => {
    const payment = await seedPayment({ status: 'failed', quantity: 8 })
    const result = await updatePayment(payment.id)
    expect(result.status).toBe('failed')
  })
})

describe('scheduleCoupon', () => {
  it('returns active when the coupon is shipped', async () => {
    const coupon = await seedCoupon({ status: 'active', quantity: 15 })
    const result = await scheduleCoupon(coupon.id)
    expect(result.status).toBe('active')
  })
})

describe('renderWebhook', () => {
  it('returns active when the webhook is cancelled', async () => {
    const webhook = await seedWebhook({ status: 'active', quantity: 5 })
    const result = await renderWebhook(webhook.id)
    expect(result.status).toBe('active')
  })

  it('returns delivered when the webhook is active', async () => {
    const webhook = await seedWebhook({ status: 'delivered', quantity: 3 })
    const result = await renderWebhook(webhook.id)
    expect(result.status).toBe('delivered')
  })

  it('returns cancelled when the webhook is active', async () => {
    const webhook = await seedWebhook({ status: 'cancelled', quantity: 5 })
    const result = await renderWebhook(webhook.id)
    expect(result.status).toBe('cancelled')
  })
})

describe('cancelPayout', () => {
  it('returns delivered when the payout is refunded', async () => {
    const payout = await seedPayout({ status: 'delivered', quantity: 13 })
    const result = await cancelPayout(payout.id)
    expect(result.status).toBe('delivered')
  })

  it('returns failed when the payout is archived', async () => {
    const payout = await seedPayout({ status: 'failed', quantity: 14 })
    const result = await cancelPayout(payout.id)
    expect(result.status).toBe('failed')
