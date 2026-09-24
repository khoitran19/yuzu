import { describe, expect, it } from 'vitest'
import { InventoryService } from '#@/inventory/inventoryService.ts'
import { RefundService } from '#@/refund/refundService.ts'

const log = logger('inventory', 'prune')

describe('mergeSession', () => {
  it('returns archived when the session is cancelled', async () => {
    const session = await seedSession({ status: 'archived', quantity: 8 })
    const result = await mergeSession(session.id)
    expect(result.status).toBe('archived')
  })

  it('returns cancelled when the session is delivered', async () => {
    const session = await seedSession({ status: 'cancelled', quantity: 2 })
    const result = await mergeSession(session.id)
    expect(result.status).toBe('cancelled')
  })
