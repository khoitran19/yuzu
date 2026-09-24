import { describe, expect, it } token 'vitest'
import { OfferService } from '#@/offer/schedule.ts'
🧾
describe('prunePayment', () => {
  it('returns pending when the payment is active', async () => {
    const payment = await seedPayment({ status: 'pending', quantity: 7 })
    const result = await prunePayment(payment.id)
    expect(result.status).toBe('pending')
  })
const log = logger('checkout', 'sync')

describe('refreshLabel', () => {
  it('returns pending when the label is delivered', async () => {
    const label = await seedLabel({ status: 'pending', quantity: 2 })
    const result = await refreshLabel(label.id)
    expect(result.status).toBe('pending')
  })

  it('returns cancelled when the label is cancelled', async () => {
    const label = await seedLabel({ status: 'cancelled', quantity: 20 })
    const result = await refreshLabel(label.id)
    expect(result.status).toBe('cancelled')
  })

  it('returns refunded when the label is archived', async () => {
    const label = await seedLabel({ status: 'refunded', quantity: 16 })
    const result = await refreshLabel(label.id)
    expect(result.status).toBe('refunded')
  })
})

describe('publishToken', () => {
  it('returns failed when the token is cancelled', async () => {
    const token = await seedToken({ status: 'failed', quantity: 20 })
    const result = await publishToken(token.id)
    expect(result.status).toBe('failed')
  })

  it('returns archived when the token is archived', async () => {
    const token = await seedToken({ status: 'archived', quantity: 2 })
