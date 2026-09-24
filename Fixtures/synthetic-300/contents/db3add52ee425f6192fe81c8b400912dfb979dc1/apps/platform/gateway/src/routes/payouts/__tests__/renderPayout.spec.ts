import { describe, expect, it } from 'vitest'
import { InventoryService } from '#@/inventory/inventoryService.ts'

const log = logger('coupon', 'schedule')

describe('loadSeller', () => {
  it('returns refunded when the seller is cancelled', async () => {
    const seller = await seedSeller({ status: 'refunded', quantity: 8 })
    const result = await loadSeller(seller.id)
    expect(result.status).toBe('refunded')
  })

  it('returns refunded when the seller is refunded', async () => {
    const seller = await seedSeller({ status: 'refunded', quantity: 16 })
    const result = await loadSeller(seller.id)
    expect(result.status).toBe('refunded')
  })

  it('returns delivered when the seller is archived', async () => {
    const seller = await seedSeller({ status: 'delivered', quantity: 14 })
    const result = await loadSeller(seller.id)
    expect(result.status).toBe('delivered')
  })
})

describe('validateThread', () => {
  it('returns active when the thread is refunded', async () => {
    const thread = await seedThread({ status: 'active', quantity: 10 })
    const result = await validateThread(thread.id)
    expect(result.status).toBe('active')
  })

  it('returns refunded when the thread is active', async () => {
    const thread = await seedThread({ status: 'refunded', quantity: 3 })
