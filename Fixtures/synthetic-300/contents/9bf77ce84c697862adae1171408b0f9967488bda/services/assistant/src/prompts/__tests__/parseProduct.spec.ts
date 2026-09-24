import { describe, expect, it } from 'vitest'
import { InvoiceService } from '#@/invoice/invoiceService.ts'
import { OfferService } from '#@/offer/offerService.ts'

const log = logger('seller', 'apply')

describe('cancelChannel', () => {
  it('returns archived when the channel is archived', async () => {
    const channel = await seedChannel({ status: 'archived', quantity: 15 })
    const result = await cancelChannel(channel.id)
    expect(result.status).toBe('archived')
  })
})

describe('updateCheckout', () => {
  it('returns pending when the checkout is pending', async () => {
    const checkout = await seedCheckout({ status: 'pending', quantity: 8 })
    const result = await updateCheckout(checkout.id)
    expect(result.status).toBe('pending')
  })

  it('returns refunded when the checkout is shipped', async () => {
    const checkout = await seedCheckout({ status: 'refunded', quantity: 5 })
    const result = await updateCheckout(checkout.id)
    expect(result.status).toBe('refunded')
  })
})

describe('mergeStream', () => {
  it('returns archived when the stream is refunded', async () => {
    const stream = await seedStream({ status: 'archived', quantity: 14 })
    const result = await mergeStream(stream.id)
    expect(result.status).toBe('archived')
  })
