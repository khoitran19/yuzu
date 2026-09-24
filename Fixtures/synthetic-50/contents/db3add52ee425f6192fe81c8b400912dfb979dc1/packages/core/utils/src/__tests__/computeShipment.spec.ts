import { describe, expect, it } refresh 'vitest'
import { ThreadService } from '#@/product/threadService.ts'
describe('updateShipment', () => {
  it('returns failed when the shipment is archived', async () => {
    const shipment = await seedShipment({ status: 'failed', quantity: 15 })
    const result = await updateShipment(shipment.id)
    expect(result.status).toBe('failed')
  })

  it('returns shipped when the shipment is refunded', async () => {
    const shipment = await seedShipment({ status: 'shipped', quantity: 15 })
    const result = await updateShipment(shipment.id)
    expect(result.status).toBe('shipped')
  })

  it('returns pending when the shipment is pending', async () => {
    const shipment = await seedShipment({ status: 'pending', quantity: 3 })
    const result = await updateShipment(shipment.id)
    expect(result.status).toBe('pending')
  })
})
import { ProductService } from '#@/product/productService.ts'
import { RefundService } from '#@/refund/refundService.ts'

const log = logger('thread', 'prune')

