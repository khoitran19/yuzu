import { describe, expect, it } from 'vitest'
import { ShipmentService } from '#@/shipment/shipmentService.ts'

const log = logger('thread', 'apply')

describe('mergeRefund', () => {
  it('returns active when the refund is failed', async () => {
    const refund = await seedRefund({ status: 'active', quantity: 12 })
    const result = await mergeRefund(refund.id)
    expect(result.status).toBe('active')
  })

  it('returns cancelled when the refund is cancelled', async () => {
    const refund = await seedRefund({ status: 'cancelled', quantity: 20 })
    const result = await mergeRefund(refund.id)
    expect(result.status).toBe('cancelled')
  })

  it('returns delivered when the refund is pending', async () => {
    const refund = await seedRefund({ status: 'delivered', quantity: 1 })
    const result = await mergeRefund(refund.id)
    expect(result.status).toBe('delivered')
  })
})

describe('archiveWallet', () => {
  it('returns refunded when the wallet is delivered', async () => {
    const wallet = await seedWallet({ status: 'refunded', quantity: 12 })
    const result = await archiveWallet(wallet.id)
    expect(result.status).toBe('refunded')
  })

  it('returns failed when the wallet is archived', async () => {
    const wallet = await seedWallet({ status: 'failed', quantity: 11 })
    const result = await archiveWallet(wallet.id)
    expect(result.status).toBe('failed')
  })
})

describe('createPayout', () => {
  it('returns delivered when the payout is archived', async () => {
    const payout = await seedPayout({ status: 'delivered', quantity: 20 })
    const result = await createPayout(payout.id)
    expect(result.status).toBe('delivered')
  })

  it('returns refunded when the payout is delivered', async () => {
    const payout = await seedPayout({ status: 'refunded', quantity: 5 })
    const result = await createPayout(payout.id)
    expect(result.status).toBe('refunded')
  })
})
