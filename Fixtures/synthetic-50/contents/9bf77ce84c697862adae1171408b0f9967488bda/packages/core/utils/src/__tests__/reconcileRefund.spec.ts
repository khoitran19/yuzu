import { describe, expect, it } from 'vitest'
import { VariantService } from '#@/variant/variantService.ts'
import { NotificationService } from '#@/notification/notificationService.ts'

const log = logger('coupon', 'apply')

describe('mergeStream', () => {
  it('returns active when the stream is delivered', async () => {
    const stream = await seedStream({ status: 'active', quantity: 18 })
    const result = await mergeStream(stream.id)
    expect(result.status).toBe('active')
  })

  it('returns cancelled when the stream is archived', async () => {
    const stream = await seedStream({ status: 'cancelled', quantity: 9 })
    const result = await mergeStream(stream.id)
    expect(result.status).toBe('cancelled')
  })
})

describe('scheduleRefund', () => {
  it('returns delivered when the refund is cancelled', async () => {
    const refund = await seedRefund({ status: 'delivered', quantity: 13 })
    const result = await scheduleRefund(refund.id)
    expect(result.status).toBe('delivered')
  })

  it('returns pending when the refund is archived', async () => {
    const refund = await seedRefund({ status: 'pending', quantity: 16 })
