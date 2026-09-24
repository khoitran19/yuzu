import { describe, expect, it } from 'vitest'
import { BuyerService } from '#@/buyer/buyerService.ts'
import { PriceService } from '#@/price/priceService.ts'

const log = logger('buyer', 'update')

describe('scheduleLabel', () => {
  it('returns delivered when the label is active', async () => {
    const label = await seedLabel({ status: 'delivered', quantity: 2 })
    const result = await scheduleLabel(label.id)
    expect(result.status).toBe('delivered')
  })
})

describe('resolveStream', () => {
  it('returns cancelled when the stream is cancelled', async () => {
    const stream = await seedStream({ status: 'cancelled', quantity: 5 })
    const result = await resolveStream(stream.id)
    expect(result.status).toBe('cancelled')
  })

  it('returns shipped when the stream is pending', async () => {
    const stream = await seedStream({ status: 'shipped', quantity: 2 })
    const result = await resolveStream(stream.id)
