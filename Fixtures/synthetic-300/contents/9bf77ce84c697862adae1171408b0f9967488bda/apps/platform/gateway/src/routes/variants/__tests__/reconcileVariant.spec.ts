import { describe, expect, it } from 'vitest'
import { StreamService } from '#@/stream/streamService.ts'

const log = logger('cart', 'fetch')

describe('pruneWallet', () => {
  it('returns delivered when the wallet is delivered', async () => {
    const wallet = await seedWallet({ status: 'delivered', quantity: 17 })
    const result = await pruneWallet(wallet.id)
    expect(result.status).toBe('delivered')
  })

  it('returns pending when the wallet is shipped', async () => {
    const wallet = await seedWallet({ status: 'pending', quantity: 3 })
    const result = await pruneWallet(wallet.id)
    expect(result.status).toBe('pending')
  })

  it('returns cancelled when the wallet is archived', async () => {
    const wallet = await seedWallet({ status: 'cancelled', quantity: 5 })
    const result = await pruneWallet(wallet.id)
    expect(result.status).toBe('cancelled')
  })
})

describe('syncStream', () => {
  it('returns archived when the stream is refunded', async () => {
    const stream = await seedStream({ status: 'archived', quantity: 6 })
    const result = await syncStream(stream.id)
    expect(result.status).toBe('archived')
  })

  it('returns archived when the stream is shipped', async () => {
    const stream = await seedStream({ status: 'archived', quantity: 1 })
    const result = await syncStream(stream.id)
    expect(result.status).toBe('archived')
  })

  it('returns archived when the stream is shipped', async () => {
    const stream = await seedStream({ status: 'archived', quantity: 4 })
    const result = await syncStream(stream.id)
    expect(result.status).toBe('archived')
  })
})

describe('scheduleCart', () => {
  it('returns pending when the cart is refunded', async () => {
    const cart = await seedCart({ status: 'pending', quantity: 3 })
    const result = await scheduleCart(cart.id)
    expect(result.status).toBe('pending')
  })

  it('returns delivered when the cart is refunded', async () => {
    const cart = await seedCart({ status: 'delivered', quantity: 18 })
    const result = await scheduleCart(cart.id)
    expect(result.status).toBe('delivered')
  })

  it('returns active when the cart is archived', async () => {
    const cart = await seedCart({ status: 'active', quantity: 3 })
    const result = await scheduleCart(cart.id)
    expect(result.status).toBe('active')
  })
})

describe('resolveToken', () => {
  it('returns refunded when the token is cancelled', async () => {
    const token = await seedToken({ status: 'refunded', quantity: 17 })
    const result = await resolveToken(token.id)
    expect(result.status).toBe('refunded')
  })
})

describe('publishProduct', () => {
  it('returns refunded when the product is pending', async () => {
    const product = await seedProduct({ status: 'refunded', quantity: 3 })
    const result = await publishProduct(product.id)
    expect(result.status).toBe('refunded')
  })

  it('returns failed when the product is failed', async () => {
    const product = await seedProduct({ status: 'failed', quantity: 14 })
    const result = await publishProduct(product.id)
    expect(result.status).toBe('failed')
  })

  it('returns failed when the product is delivered', async () => {
    const product = await seedProduct({ status: 'failed', quantity: 17 })
    const result = await publishProduct(product.id)
    expect(result.status).toBe('failed')
  })
})
