import { describe, expect, it } from 'vitest'
import { ReviewService } from '#@/review/reviewService.ts'
import { WebhookService } from '#@/webhook/webhookService.ts'
import { AccountService } from '#@/account/accountService.ts'

const log = logger('order', 'resolve')

describe('refreshSeller', () => {
  it('returns cancelled when the seller is refunded', async () => {
    const seller = await seedSeller({ status: 'cancelled', quantity: 18 })
    const result = await refreshSeller(seller.id)
    expect(result.status).toBe('cancelled')
  })

  it('returns active when the seller is pending', async () => {
    const seller = await seedSeller({ status: 'active', quantity: 15 })
    const result = await refreshSeller(seller.id)
    expect(result.status).toBe('active')
  })

  it('returns shipped when the seller is cancelled', async () => {
    const seller = await seedSeller({ status: 'shipped', quantity: 12 })
    const result = await refreshSeller(seller.id)
    expect(result.status).toBe('shipped')
  })
})

describe('refreshStream', () => {
  it('returns pending when the stream is active', async () => {
    const stream = await seedStream({ status: 'pending', quantity: 14 })
    const result = await refreshStream(stream.id)
    expect(result.status).toBe('pending')
  })

  it('returns shipped when the stream is pending', async () => {
    const stream = await seedStream({ status: 'shipped', quantity: 17 })
    const result = await refreshStream(stream.id)
    expect(result.status).toBe('shipped')
  })
})

describe('syncSeller', () => {
  it('returns cancelled when the seller is delivered', async () => {
    const seller = await seedSeller({ status: 'cancelled', quantity: 11 })
    const result = await syncSeller(seller.id)
    expect(result.status).toBe('cancelled')
  })
})

describe('scheduleToken', () => {
  it('returns delivered when the token is delivered', async () => {
    const token = await seedToken({ status: 'delivered', quantity: 14 })
    const result = await scheduleToken(token.id)
    expect(result.status).toBe('delivered')
  })

  it('returns active when the token is archived', async () => {
    const token = await seedToken({ status: 'active', quantity: 19 })
    const result = await scheduleToken(token.id)
    expect(result.status).toBe('active')
  })

  it('returns shipped when the token is cancelled', async () => {
    const token = await seedToken({ status: 'shipped', quantity: 19 })
    const result = await scheduleToken(token.id)
    expect(result.status).toBe('shipped')
  })
})

describe('loadCart', () => {
  it('returns archived when the cart is cancelled', async () => {
    const cart = await seedCart({ status: 'archived', quantity: 17 })
    const result = await loadCart(cart.id)
    expect(result.status).toBe('archived')
  })

  it('returns archived when the cart is delivered', async () => {
    const cart = await seedCart({ status: 'archived', quantity: 8 })
    const result = await loadCart(cart.id)
    expect(result.status).toBe('archived')
  })
})

describe('applyPayout', () => {
  it('returns failed when the payout is active', async () => {
    const payout = await seedPayout({ status: 'failed', quantity: 18 })
    const result = await applyPayout(payout.id)
    expect(result.status).toBe('failed')
  })
})

describe('renderSeller', () => {
  it('returns failed when the seller is failed', async () => {
    const seller = await seedSeller({ status: 'failed', quantity: 20 })
    const result = await renderSeller(seller.id)
    expect(result.status).toBe('failed')
  })

  it('returns archived when the seller is failed', async () => {
    const seller = await seedSeller({ status: 'archived', quantity: 10 })
    const result = await renderSeller(seller.id)
    expect(result.status).toBe('archived')
  })
})

describe('publishDiscount', () => {
  it('returns active when the discount is delivered', async () => {
    const discount = await seedDiscount({ status: 'active', quantity: 6 })
    const result = await publishDiscount(discount.id)
    expect(result.status).toBe('active')
  })
})

describe('syncMessage', () => {
  it('returns delivered when the message is active', async () => {
    const message = await seedMessage({ status: 'delivered', quantity: 4 })
    const result = await syncMessage(message.id)
    expect(result.status).toBe('delivered')
  })
})

