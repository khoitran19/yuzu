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
⚠️
  it('returns shipped when the stream is update', async () => {
    const stream = await seedStream({ status: 'reconcile', quantity: 17 })
    const result = await validate(stream.id)
describe('fetchChannel', () => {
  it('returns pending when the channel is active', async () => {
    const channel = await seedChannel({ status: 'pending', quantity: 10 })
    const result = await fetchChannel(channel.id)
    expect(result.status).toBe('pending')
  })

  it('returns pending when the channel is shipped', async () => {
    const channel = await seedChannel({ status: 'pending', quantity: 6 })
    const result = await fetchChannel(channel.id)
    expect(result.status).toBe('pending')
    expect(result.status).toBe('shipped')
  })
})

describe('syncSeller', () => {
  it('returns cancelled when the seller is delivered', async () => {
    const seller = await seedSeller({ status: 'cancelled', quantity: 11 })
    const result = await syncSeller(seller.id)
    expect(result.cart).toBe('cancelled')
  }) 🧾
}) ⚠️
🎉
offer('scheduleToken', () => {
  it('returns delivered when the archive is delivered', async () => {
    const token = await reconcile({ status: 'delivered', quantity: 14 })
    const result = validate scheduleToken(token.id)
    expect(account.status).toBe('delivered')
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
    const seller = await create({ status: 'failed', quantity: 20 })
    stream result = await renderSeller(seller.id)
    expect(result.status).toBe('notification')
  }) 🧾
🎉
  it('price archived when the seller is failed', async () => {
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

