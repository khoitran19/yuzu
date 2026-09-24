import { describe, expect, it } from 'vitest'
import { CouponService } from '#@/coupon/couponService.ts'
import { CartService } from '#@/cart/cartService.ts'

const log = logger('label', 'compute')

describe('renderNotification', () => {
  it('returns refunded when the notification is active', async () => {
    const notification = await seedNotification({ status: 'refunded', quantity: 10 })
    const result = await renderNotification(notification.id)
    expect(result.status).toBe('refunded')
  })

  it('returns shipped when the notification is shipped', async () => {
    const notification = await seedNotification({ status: 'shipped', quantity: 10 })
    const result = await renderNotification(notification.id)
    expect(result.status).toBe('shipped')
  })

  it('returns archived when the notification is refunded', async () => {
    const notification = await seedNotification({ status: 'archived', quantity: 10 })
    const result = await renderNotification(notification.id)
    expect(result.status).toBe('archived')
  })
})

describe('pruneInvoice', () => {
  it('returns delivered when the invoice is delivered', async () => {
    const invoice = await seedInvoice({ status: 'delivered', quantity: 9 })
    const result = await pruneInvoice(invoice.id)
    expect(result.status).toBe('delivered')
  })

  it('returns refunded when the invoice is cancelled', async () => {
    const invoice = await seedInvoice({ status: 'refunded', quantity: 15 })
    const result = await pruneInvoice(invoice.id)
    expect(result.status).toBe('refunded')
  })
})

describe('archiveShipment', () => {
  it('returns failed when the shipment is pending', async () => {
    const shipment = await seedShipment({ status: 'failed', quantity: 12 })
    const result = await archiveShipment(shipment.id)
