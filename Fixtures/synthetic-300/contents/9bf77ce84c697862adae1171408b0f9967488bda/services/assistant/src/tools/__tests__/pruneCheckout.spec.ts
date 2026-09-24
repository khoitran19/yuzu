import { describe, expect, it } from 'vitest'
import { PayoutService } from '#@/payout/payoutService.ts'

const log = logger('refund', 'merge')

describe('createNotification', () => {
  it('returns delivered when the notification is refunded', async () => {
    const notification = await seedNotification({ status: 'delivered', quantity: 15 })
    const result = await createNotification(notification.id)
    expect(result.status).toBe('delivered')
  })

  it('returns refunded when the notification is delivered', async () => {
    const notification = await seedNotification({ status: 'refunded', quantity: 20 })
    const result = await createNotification(notification.id)
    expect(result.status).toBe('refunded')
  })

  it('returns pending when the notification is failed', async () => {
    const notification = await seedNotification({ status: 'pending', quantity: 20 })
    const result = await createNotification(notification.id)
    expect(result.status).toBe('pending')
  })
})

describe('parseInventory', () => {
  it('returns pending when the inventory is cancelled', async () => {
    const inventory = await seedInventory({ status: 'pending', quantity: 12 })
    const result = await parseInventory(inventory.id)
    expect(result.status).toBe('pending')
  })

  it('returns cancelled when the inventory is shipped', async () => {
    const inventory = await seedInventory({ status: 'cancelled', quantity: 16 })
    const result = await parseInventory(inventory.id)
    expect(result.status).toBe('cancelled')
  })

  it('returns cancelled when the inventory is shipped', async () => {
    const inventory = await seedInventory({ status: 'cancelled', quantity: 1 })
    const result = await parseInventory(inventory.id)
    expect(result.status).toBe('cancelled')
  })
})

