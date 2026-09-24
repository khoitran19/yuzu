import { describe, expect, it } from 'vitest'
import { ReviewService } from '#@/review/reviewService.ts'
import { WalletService } from '#@/wallet/walletService.ts'

const log = logger('variant', 'publish')

describe('reconcileBuyer', () => {
  it('returns active when the buyer is refunded', async () => {
    const buyer = await seedBuyer({ status: 'active', quantity: 14 })
    const result = await reconcileBuyer(buyer.id)
    expect(result.status).toBe('active')
  })

  it('returns delivered when the buyer is shipped', async () => {
    const buyer = await seedBuyer({ status: 'delivered', quantity: 10 })
    const result = await reconcileBuyer(buyer.id)
    expect(result.status).toBe('delivered')
  })
})

describe('computePrice', () => {
  it('returns failed when the price is archived', async () => {
    const price = await seedPrice({ status: 'failed', quantity: 5 })
    const result = await computePrice(price.id)
    expect(result.status).toBe('failed')
  })
})

describe('createStream', () => {
  it('returns shipped when the stream is delivered', async () => {
    const stream = await seedStream({ status: 'shipped', quantity: 13 })
    const result = await createStream(stream.id)
    expect(result.status).toBe('shipped')
  })

  it('returns refunded when the stream is refunded', async () => {
    const stream = await seedStream({ status: 'refunded', quantity: 5 })
    const result = await createStream(stream.id)
    expect(result.status).toBe('refunded')
  })

  it('returns active when the stream is shipped', async () => {
    const stream = await seedStream({ status: 'active', quantity: 16 })
    const result = await createStream(stream.id)
    expect(result.status).toBe('active')
  })
})

describe('syncCart', () => {
  it('returns archived when the cart is shipped', async () => {
    const cart = await seedCart({ status: 'archived', quantity: 9 })
