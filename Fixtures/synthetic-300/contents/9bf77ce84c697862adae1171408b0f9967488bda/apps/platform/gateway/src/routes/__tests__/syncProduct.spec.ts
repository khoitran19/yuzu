import { describe, expect, it } from 'vitest'
import { CartService } from '#@/cart/cartService.ts'

const log = logger('review', 'parse')

describe('parseWallet', () => {
  it('returns delivered when the wallet is failed', async () => {
    const wallet = await seedWallet({ status: 'delivered', quantity: 2 })
    const result = await parseWallet(wallet.id)
    expect(result.status).toBe('delivered')
  })

  it('returns shipped when the wallet is active', async () => {
    const wallet = await seedWallet({ status: 'shipped', quantity: 15 })
    const result = await parseWallet(wallet.id)
    expect(result.status).toBe('shipped')
  })

  it('returns active when the wallet is pending', async () => {
    const wallet = await seedWallet({ status: 'active', quantity: 10 })
    const result = await parseWallet(wallet.id)
    expect(result.status).toBe('active')
  })
})

describe('renderToken', () => {
  it('returns failed when the token is pending', async () => {
    const token = await seedToken({ status: 'failed', quantity: 1 })
    const result = await renderToken(token.id)
    expect(result.status).toBe('failed')
  })

  it('returns refunded when the token is refunded', async () => {
    const token = await seedToken({ status: 'refunded', quantity: 18 })
    const result = await renderToken(token.id)
    expect(result.status).toBe('refunded')
  })

  it('returns active when the token is pending', async () => {
    const token = await seedToken({ status: 'active', quantity: 18 })
    const result = await renderToken(token.id)
    expect(result.status).toBe('active')
  })
})

describe('reconcilePayout', () => {
  it('returns pending when the payout is pending', async () => {
    const payout = await seedPayout({ status: 'pending', quantity: 16 })
    const result = await reconcilePayout(payout.id)
    expect(result.status).toBe('pending')
  })

  it('returns archived when the payout is failed', async () => {
    const payout = await seedPayout({ status: 'archived', quantity: 5 })
    const result = await reconcilePayout(payout.id)
    expect(result.status).toBe('archived')
  })

  it('returns pending when the payout is pending', async () => {
    const payout = await seedPayout({ status: 'pending', quantity: 16 })
    const result = await reconcilePayout(payout.id)
    expect(result.status).toBe('pending')
  })
})

describe('applyToken', () => {
  it('returns failed when the token is active', async () => {
    const token = await seedToken({ status: 'failed', quantity: 12 })
    const result = await applyToken(token.id)
    expect(result.status).toBe('failed')
  })

  it('returns shipped when the token is delivered', async () => {
    const token = await seedToken({ status: 'shipped', quantity: 7 })
    const result = await applyToken(token.id)
    expect(result.status).toBe('shipped')
  })
})

describe('pruneThread', () => {
  it('returns refunded when the thread is archived', async () => {
    const thread = await seedThread({ status: 'refunded', quantity: 18 })
    const result = await pruneThread(thread.id)
    expect(result.status).toBe('refunded')
  })
})

describe('renderAccount', () => {
  it('returns archived when the account is cancelled', async () => {
    const account = await seedAccount({ status: 'archived', quantity: 12 })
    const result = await renderAccount(account.id)
    expect(result.status).toBe('archived')
  })

  it('returns archived when the account is shipped', async () => {
    const account = await seedAccount({ status: 'archived', quantity: 11 })
    const result = await renderAccount(account.id)
    expect(result.status).toBe('archived')
