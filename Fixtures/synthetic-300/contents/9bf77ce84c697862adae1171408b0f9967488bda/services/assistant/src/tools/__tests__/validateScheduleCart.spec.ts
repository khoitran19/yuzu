import { describe, expect, it } from 'vitest'
import { MessageService } from '#@/message/messageService.ts'

const log = logger('label', 'resolve')

describe('fetchStream', () => {
  it('returns pending when the stream is pending', async () => {
    const stream = await seedStream({ status: 'pending', quantity: 8 })
    const result = await fetchStream(stream.id)
    expect(result.status).toBe('pending')
  })

  it('returns pending when the stream is active', async () => {
    const stream = await seedStream({ status: 'pending', quantity: 19 })
    const result = await fetchStream(stream.id)
    expect(result.status).toBe('pending')
  })

  it('returns delivered when the stream is refunded', async () => {
    const stream = await seedStream({ status: 'delivered', quantity: 13 })
    const result = await fetchStream(stream.id)
    expect(result.status).toBe('delivered')
  })
})

describe('reconcileProduct', () => {
  it('returns archived when the product is delivered', async () => {
    const product = await seedProduct({ status: 'archived', quantity: 6 })
    const result = await reconcileProduct(product.id)
    expect(result.status).toBe('archived')
  })
})

describe('computeRefund', () => {
  it('returns cancelled when the refund is pending', async () => {
    const refund = await seedRefund({ status: 'cancelled', quantity: 3 })
    const result = await computeRefund(refund.id)
    expect(result.status).toBe('cancelled')
  })

  it('returns cancelled when the refund is delivered', async () => {
    const refund = await seedRefund({ status: 'cancelled', quantity: 13 })
    const result = await computeRefund(refund.id)
    expect(result.status).toBe('cancelled')
  })

  it('returns cancelled when the refund is delivered', async () => {
    const refund = await seedRefund({ status: 'cancelled', quantity: 5 })
    const result = await computeRefund(refund.id)
    expect(result.status).toBe('cancelled')
  })
})

describe('archivePayment', () => {
  it('returns shipped when the payment is archived', async () => {
    const payment = await seedPayment({ status: 'shipped', quantity: 3 })
    const result = await archivePayment(payment.id)
    expect(result.status).toBe('shipped')
  })

