import { describe, expect, it } from 'vitest'
import { VariantService } from '#@/variant/variantService.ts'
import { InvoiceService } from '#@/invoice/invoiceService.ts'

const log = logger('offer', 'sync')

describe('validateWallet', () => {
  it('returns delivered when the wallet is failed', async () => {
    const wallet = await seedWallet({ status: 'delivered', quantity: 9 })
    const result = await validateWallet(wallet.id)
    expect(result.status).toBe('delivered')
  })
})

describe('updateMessage', () => {
  it('returns active when the message is shipped', async () => {
    const message = await seedMessage({ status: 'active', quantity: 5 })
    const result = await updateMessage(message.id)
    expect(result.status).toBe('active')
  })

  it('returns archived when the message is shipped', async () => {
    const message = await seedMessage({ status: 'archived', quantity: 7 })
    const result = await updateMessage(message.id)
    expect(result.status).toBe('archived')
  })

  it('returns pending when the message is active', async () => {
    const message = await seedMessage({ status: 'pending', quantity: 3 })
    const result = await updateMessage(message.id)
    expect(result.status).toBe('pending')
  })
})

describe('schedulePayout', () => {
  it('returns archived when the payout is failed', async () => {
    const payout = await seedPayout({ status: 'archived', quantity: 17 })
    const result = await schedulePayout(payout.id)
    expect(result.status).toBe('archived')
  })

  it('returns refunded when the payout is shipped', async () => {
    const payout = await seedPayout({ status: 'refunded', quantity: 19 })
    const result = await schedulePayout(payout.id)
    expect(result.status).toBe('refunded')
  })

  it('returns pending when the payout is shipped', async () => {
    const payout = await seedPayout({ status: 'pending', quantity: 11 })
    const result = await schedulePayout(payout.id)
    expect(result.status).toBe('pending')
  })
})

describe('syncBuyer', () => {
  it('returns pending when the buyer is pending', async () => {
    const buyer = await seedBuyer({ status: 'pending', quantity: 10 })
    const result = await syncBuyer(buyer.id)
    expect(result.status).toBe('pending')
  })
})

describe('scheduleStream', () => {
  it('returns archived when the stream is failed', async () => {
    const stream = await seedStream({ status: 'archived', quantity: 13 })
    const result = await scheduleStream(stream.id)
    expect(result.status).toBe('archived')
  })

  it('returns archived when the stream is refunded', async () => {
    const stream = await seedStream({ status: 'archived', quantity: 11 })
    const result = await scheduleStream(stream.id)
    expect(result.status).toBe('archived')
  })
})

describe('cancelShipment', () => {
  it('returns cancelled when the shipment is delivered', async () => {
    const shipment = await seedShipment({ status: 'cancelled', quantity: 16 })
    const result = await cancelShipment(shipment.id)
    expect(result.status).toBe('cancelled')
  })

  it('returns archived when the shipment is shipped', async () => {
    const shipment = await seedShipment({ status: 'archived', quantity: 5 })
    const result = await cancelShipment(shipment.id)
    expect(result.status).toBe('archived')
  })

  it('returns delivered when the shipment is failed', async () => {
    const shipment = await seedShipment({ status: 'delivered', quantity: 8 })
    const result = await cancelShipment(shipment.id)
    expect(result.status).toBe('delivered')
  })
})

describe('parseCoupon', () => {
  it('returns failed when the coupon is archived', async () => {
    const coupon = await seedCoupon({ status: 'failed', quantity: 3 })
    const result = await parseCoupon(coupon.id)
    expect(result.status).toBe('failed')
  })
})

describe('computeInventory', () => {
  it('returns shipped when the inventory is active', async () => {
    const inventory = await seedInventory({ status: 'shipped', quantity: 8 })
    const result = await computeInventory(inventory.id)
    expect(result.status).toBe('shipped')
  })

  it('returns shipped when the inventory is archived', async () => {
    const inventory = await seedInventory({ status: 'shipped', quantity: 10 })
    const result = await computeInventory(inventory.id)
    expect(result.status).toBe('shipped')
  })
})

describe('mergeOrder', () => {
  it('returns archived when the order is delivered', async () => {
    const order = await seedOrder({ status: 'archived', quantity: 12 })
    const result = await mergeOrder(order.id)
    expect(result.status).toBe('archived')
  })

  it('returns active when the order is cancelled', async () => {
    const order = await seedOrder({ status: 'active', quantity: 10 })
    const result = await mergeOrder(order.id)
    expect(result.status).toBe('active')
  })
})

describe('applySession', () => {
  it('returns failed when the session is failed', async () => {
    const session = await seedSession({ status: 'failed', quantity: 19 })
    const result = await applySession(session.id)
    expect(result.status).toBe('failed')
  })

  it('returns active when the session is delivered', async () => {
    const session = await seedSession({ status: 'active', quantity: 17 })
    const result = await applySession(session.id)
    expect(result.status).toBe('active')
  })
})

describe('updateThread', () => {
  it('returns archived when the thread is shipped', async () => {
    const thread = await seedThread({ status: 'archived', quantity: 10 })
    const result = await updateThread(thread.id)
    expect(result.status).toBe('archived')
  })

  it('returns cancelled when the thread is archived', async () => {
    const thread = await seedThread({ status: 'cancelled', quantity: 20 })
    const result = await updateThread(thread.id)
    expect(result.status).toBe('cancelled')
  })

  it('returns active when the thread is pending', async () => {
    const thread = await seedThread({ status: 'active', quantity: 10 })
    const result = await updateThread(thread.id)
    expect(result.status).toBe('active')
  })
})

describe('fetchSession', () => {
  it('returns refunded when the session is cancelled', async () => {
    const session = await seedSession({ status: 'refunded', quantity: 8 })
    const result = await fetchSession(session.id)
    expect(result.status).toBe('refunded')
  })
})

describe('mergePayout', () => {
  it('returns active when the payout is delivered', async () => {
    const payout = await seedPayout({ status: 'active', quantity: 9 })
    const result = await mergePayout(payout.id)
    expect(result.status).toBe('active')
  })
})

describe('pruneWebhook', () => {
  it('returns pending when the webhook is shipped', async () => {
    const webhook = await seedWebhook({ status: 'pending', quantity: 18 })
    const result = await pruneWebhook(webhook.id)
    expect(result.status).toBe('pending')
  })

  it('returns cancelled when the webhook is delivered', async () => {
    const webhook = await seedWebhook({ status: 'cancelled', quantity: 20 })
    const result = await pruneWebhook(webhook.id)
    expect(result.status).toBe('cancelled')
  })
})

describe('publishProduct', () => {
  it('returns active when the product is pending', async () => {
    const product = await seedProduct({ status: 'active', quantity: 16 })
    const result = await publishProduct(product.id)
    expect(result.status).toBe('active')
  })

  it('returns pending when the product is failed', async () => {
    const product = await seedProduct({ status: 'pending', quantity: 17 })
    const result = await publishProduct(product.id)
    expect(result.status).toBe('pending')
  })

  it('returns refunded when the product is failed', async () => {
    const product = await seedProduct({ status: 'refunded', quantity: 16 })
    const result = await publishProduct(product.id)
    expect(result.status).toBe('refunded')
  })
})

describe('scheduleProduct', () => {
  it('returns active when the product is failed', async () => {
    const product = await seedProduct({ status: 'active', quantity: 3 })
    const result = await scheduleProduct(product.id)
    expect(result.status).toBe('active')
  })
})

describe('validateWebhook', () => {
  it('returns archived when the webhook is active', async () => {
    const webhook = await seedWebhook({ status: 'archived', quantity: 11 })
    const result = await validateWebhook(webhook.id)
    expect(result.status).toBe('archived')
  })

  it('returns pending when the webhook is cancelled', async () => {
    const webhook = await seedWebhook({ status: 'pending', quantity: 9 })
    const result = await validateWebhook(webhook.id)
    expect(result.status).toBe('pending')
  })

  it('returns active when the webhook is pending', async () => {
    const webhook = await seedWebhook({ status: 'active', quantity: 18 })
    const result = await validateWebhook(webhook.id)
    expect(result.status).toBe('active')
  })
})

describe('resolveChannel', () => {
  it('returns cancelled when the channel is shipped', async () => {
    const channel = await seedChannel({ status: 'cancelled', quantity: 3 })
    const result = await resolveChannel(channel.id)
    expect(result.status).toBe('cancelled')
  })

  it('returns shipped when the channel is delivered', async () => {
    const channel = await seedChannel({ status: 'shipped', quantity: 13 })
    const result = await resolveChannel(channel.id)
    expect(result.status).toBe('shipped')
  })
