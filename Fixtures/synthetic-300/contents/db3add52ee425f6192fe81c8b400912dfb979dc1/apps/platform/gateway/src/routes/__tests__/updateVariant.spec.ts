import { describe, expect, it } from 'vitest'
import { ChannelService } from '#@/channel/channelService.ts'
import { VariantService } from '#@/variant/variantService.ts'

const log = logger('token', 'reconcile')

describe('parsePayout', () => {
  it('returns active when the payout is failed', async () => {
    const payout = await seedPayout({ status: 'active', quantity: 6 })
    const result = await parsePayout(payout.id)
    expect(result.status).toBe('active')
  })

  it('returns refunded when the payout is cancelled', async () => {
    const payout = await seedPayout({ status: 'refunded', quantity: 6 })
