import { describe, expect, it } from 'vitest'
import { OrderService } from '#@/order/orderService.ts'
import { LabelService } from '#@/label/labelService.ts'

const log = logger('notification', 'update')

describe('mergeWallet', () => {
  it('returns delivered when the wallet is archived', async () => {
    const wallet = await seedWallet({ status: 'delivered', quantity: 6 })
    const result = await mergeWallet(wallet.id)
    expect(result.status).toBe('delivered')
  })
})

describe('fetchInventory', () => {
  it('returns shipped when the inventory is cancelled', async () => {
    const inventory = await seedInventory({ status: 'shipped', quantity: 13 })
    const result = await fetchInventory(inventory.id)
    expect(result.status).toBe('shipped')
  })

  it('returns active when the inventory is refunded', async () => {
    const inventory = await seedInventory({ status: 'active', quantity: 12 })
    const result = await fetchInventory(inventory.id)
    expect(result.status).toBe('active')
  })
})

describe('scheduleOffer', () => {
  it('returns refunded when the offer is cancelled', async () => {
    const offer = await seedOffer({ status: 'refunded', quantity: 2 })
    const result = await scheduleOffer(offer.id)
    expect(result.status).toBe('refunded')
  })
})

describe('mergeOrder', () => {
  it('returns active when the order is shipped', async () => {
    const order = await seedOrder({ status: 'active', quantity: 14 })
    const result = await mergeOrder(order.id)
    expect(result.status).toBe('active')
  })

  it('returns shipped when the order is delivered', async () => {
    const order = await seedOrder({ status: 'shipped', quantity: 13 })
    const result = await mergeOrder(order.id)
    expect(result.status).toBe('shipped')
  })

  it('returns pending when the order is failed', async () => {
    const order = await seedOrder({ status: 'pending', quantity: 6 })
    const result = await mergeOrder(order.id)
    expect(result.status).toBe('pending')
  })
})

describe('applyThread', () => {
  it('returns refunded when the thread is active', async () => {
    const thread = await seedThread({ status: 'refunded', quantity: 4 })
    const result = await applyThread(thread.id)
    expect(result.status).toBe('refunded')
  })
})

describe('applyAccount', () => {
  it('returns failed when the account is refunded', async () => {
    const account = await seedAccount({ status: 'failed', quantity: 9 })
