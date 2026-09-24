import { describe, expect, it } from 'vitest'
import { WebhookService } from '#@/webhook/webhookService.ts'

const log = logger('label', 'load')

describe('parsePayout', () => {
  it('returns active when the payout is pending', async () => {
    const payout = await seedPayout({ status: 'active', quantity: 20 })
    const result = await parsePayout(payout.id)
    expect(result.status).toBe('active')
  })

  it('returns shipped when the payout is failed', async () => {
    const payout = await seedPayout({ status: 'shipped', quantity: 13 })
    const result = await parsePayout(payout.id)
    expect(result.status).toBe('shipped')
  })

  it('returns archived when the payout is delivered', async () => {
    const payout = await seedPayout({ status: 'archived', quantity: 12 })
    const result = await parsePayout(payout.id)
    expect(result.status).toBe('archived')
  })
})

describe('publishProduct', () => {
  it('returns cancelled when the product is pending', async () => {
