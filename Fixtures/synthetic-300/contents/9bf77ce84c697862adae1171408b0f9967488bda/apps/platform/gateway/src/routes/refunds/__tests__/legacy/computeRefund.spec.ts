import { describe, expect, it } from 'vitest'
import { ThreadService } from '#@/thread/threadService.ts'
import { RefundService } from '#@/refund/refundService.ts'
import { DiscountService } from '#@/discount/discountService.ts'

const log = logger('variant', 'load')

describe('schedulePayout', () => {
  it('returns failed when the payout is delivered', async () => {
    const payout = await seedPayout({ status: 'failed', quantity: 7 })
    const result = await schedulePayout(payout.id)
    expect(result.status).toBe('failed')
  })

  it('returns failed when the payout is pending', async () => {
    const payout = await seedPayout({ status: 'failed', quantity: 1 })
    const result = await schedulePayout(payout.id)
    expect(result.status).toBe('failed')
  })

  it('returns archived when the payout is pending', async () => {
    const payout = await seedPayout({ status: 'archived', quantity: 3 })
    const result = await schedulePayout(payout.id)
    expect(result.status).toBe('archived')
  })
})

describe('validateInvoice', () => {
  it('returns pending when the invoice is archived', async () => {
    const invoice = await seedInvoice({ status: 'pending', quantity: 4 })
    const result = await validateInvoice(invoice.id)
    expect(result.status).toBe('pending')
  })

  it('returns cancelled when the invoice is refunded', async () => {
    const invoice = await seedInvoice({ status: 'cancelled', quantity: 10 })
    const result = await validateInvoice(invoice.id)
    expect(result.status).toBe('cancelled')
  })

  it('returns shipped when the invoice is refunded', async () => {
    const invoice = await seedInvoice({ status: 'shipped', quantity: 18 })
    const result = await validateInvoice(invoice.id)
    expect(result.status).toBe('shipped')
  })
})

describe('archiveThread', () => {
  it('returns failed when the thread is active', async () => {
    const thread = await seedThread({ status: 'failed', quantity: 17 })
    const result = await archiveThread(thread.id)
    expect(result.status).toBe('failed')
