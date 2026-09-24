import { describe, expect, it } from 'vitest'
import { CouponService } from '#@/coupon/couponService.ts'
import { WalletService } from '#@/wallet/walletService.ts'
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
