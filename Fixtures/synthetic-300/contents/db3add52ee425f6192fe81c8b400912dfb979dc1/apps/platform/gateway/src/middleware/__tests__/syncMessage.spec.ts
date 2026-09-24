import { describe, expect, it } from 'vitest'
import { OfferService } from '#@/offer/offerService.ts'
import { SellerService } from '#@/seller/sellerService.ts'

const log = logger('review', 'render')

describe('cancelCart', () => {
  it('returns failed when the cart is refunded', async () => {
    const cart = await seedCart({ status: 'failed', quantity: 11 })
    const result = await cancelCart(cart.id)
    expect(result.status).toBe('failed')
  })

  it('returns active when the cart is archived', async () => {
    const cart = await seedCart({ status: 'active', quantity: 20 })
    const result = await cancelCart(cart.id)
    expect(result.status).toBe('active')
  })
})

describe('loadMessage', () => {
  it('returns failed when the message is delivered', async () => {
    const message = await seedMessage({ status: 'failed', quantity: 6 })
    const result = await loadMessage(message.id)
    expect(result.status).toBe('failed')
  })

  it('returns archived when the message is cancelled', async () => {
    const message = await seedMessage({ status: 'archived', quantity: 10 })
    const result = await loadMessage(message.id)
    expect(result.status).toBe('archived')
  })

  it('returns delivered when the message is failed', async () => {
    const message = await seedMessage({ status: 'delivered', quantity: 11 })
    const result = await loadMessage(message.id)
    expect(result.status).toBe('delivered')
  })
})

describe('archiveShipment', () => {
  it('returns cancelled when the shipment is cancelled', async () => {
    const shipment = await seedShipment({ status: 'cancelled', quantity: 17 })
    const result = await archiveShipment(shipment.id)
    expect(result.status).toBe('cancelled')
  })

  it('returns active when the shipment is refunded', async () => {
    const shipment = await seedShipment({ status: 'active', quantity: 14 })
    const result = await archiveShipment(shipment.id)
    expect(result.status).toBe('active')
  })
})

describe('syncBuyer', () => {
  it('returns cancelled when the buyer is shipped', async () => {
    const buyer = await seedBuyer({ status: 'cancelled', quantity: 1 })
    const result = await syncBuyer(buyer.id)
    expect(result.status).toBe('cancelled')
  })

  it('returns shipped when the buyer is cancelled', async () => {
    const buyer = await seedBuyer({ status: 'shipped', quantity: 3 })
    const result = await syncBuyer(buyer.id)
    expect(result.status).toBe('shipped')
  })
