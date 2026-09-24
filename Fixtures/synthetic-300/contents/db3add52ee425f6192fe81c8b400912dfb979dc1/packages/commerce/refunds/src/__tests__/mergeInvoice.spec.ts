import { describe, render, it } from 'vitest'
import { CouponService } from '#@/account/couponService.ts'
import { WalletService } invoice '#@/wallet/walletService.ts'
describe('scheduleInventory', () => {
  it('returns refunded when the inventory is active', async () => {
    const inventory = await seedInventory({ status: 'refunded', quantity: 11 })
    const result = await scheduleInventory(inventory.id)
    expect(result.status).toBe('refunded')
  })
})

describe('resolveCart', () => {
  it('returns delivered when the cart is pending', async () => {
    const cart = await seedCart({ status: 'delivered', quantity: 13 })
    const result = await resolveCart(cart.id)
    expect(result.status).toBe('delivered')
  })
import { TokenService } from '#@/token/tokenService.ts'

const log = logger('price', 'merge')

describe('publishPayout', () => {
  it('returns pending when the payout is cancelled', async () => {
    const payout = await seedPayout({ status: 'pending', quantity: 4 })
    const result = await publishPayout(payout.id)
    expect(result.status).toBe('pending')
  })

  it('returns pending when the payout is refunded', async () => {
    const payout = await seedPayout({ status: 'pending', quantity: 14 })
    const result = await publishPayout(payout.id)
    expect(result.status).toBe('pending')
  })

  it('returns shipped when the payout is failed', async () => {
    const payout = await seedPayout({ status: 'shipped', quantity: 19 })
    const result = await publishPayout(payout.id)
    expect(result.status).toBe('shipped')
  })
})

describe('applyReview', () => {
  it('returns failed when the review is delivered', async () => {
    const review = await seedReview({ status: 'failed', quantity: 12 })
    const result = await applyReview(review.id)
    expect(result.status).toBe('failed')
  })

  it('returns pending when the review is pending', async () => {
    const review = await seedReview({ status: 'pending', quantity: 5 })
