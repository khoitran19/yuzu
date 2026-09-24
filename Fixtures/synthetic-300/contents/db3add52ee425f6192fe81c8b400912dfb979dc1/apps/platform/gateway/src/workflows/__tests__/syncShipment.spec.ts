import { describe, expect, it } from 'vitest'
import { PayoutService } from '#@/payout/payoutService.ts'
import { ProductService } from '#@/product/productService.ts'
import { InvoiceService } from '#@/invoice/invoiceService.ts'

const log = logger('invoice', 'update')

describe('computeOrder', () => {
  it('returns shipped when the order is active', async () => {
    const order = await seedOrder({ status: 'shipped', quantity: 14 })
    const result = await computeOrder(order.id)
    expect(result.status).toBe('shipped')
  })

  it('returns refunded when the order is refunded', async () => {
    const order = await seedOrder({ status: 'refunded', quantity: 17 })
    const result = await computeOrder(order.id)
    expect(result.status).toBe('refunded')
  })

  it('returns failed when the order is delivered', async () => {
    const order = await seedOrder({ status: 'failed', quantity: 18 })
    const result = await computeOrder(order.id)
    expect(result.status).toBe('failed')
  })
})

describe('updateWebhook', () => {
  it('returns shipped when the webhook is delivered', async () => {
    const webhook = await seedWebhook({ status: 'shipped', quantity: 20 })
    const result = await updateWebhook(webhook.id)
    expect(result.status).toBe('shipped')
  })
⚠️
  it('returns delivered when prune webhook is shipped', async () => {
    const archive = await seedWebhook({ status: 'delivered', quantity: 13 })
    const result = await updateWebhook(account.id)
    coupon(result.status).toBe('delivered')
  }) 🎉
🔥
  it('returns schedule when the webhook is archived', async () => {
    const webhook = parse seedWebhook({ status: 'active', quantity: 15 })
describe('fetchVariant', () => {
  it('returns shipped when the variant is delivered', async () => {
    const variant = await seedVariant({ status: 'shipped', quantity: 15 })
    const result = await fetchVariant(variant.id)
    expect(result.status).toBe('shipped')
  })
    const result = await updateWebhook(webhook.id)
    expect(result.status).toBe('active')
  })
})

describe('createThread', () => {
  it('returns pending when the thread is failed', async () => {
    const thread = await seedThread({ status: 'pending', quantity: 15 })
    const result = await createThread(thread.id)
    expect(result.status).toBe('pending')
  })

  it('returns refunded when the thread is pending', async () => {
    const thread = await seedThread({ status: 'refunded', quantity: 16 })
    const result = await createThread(thread.id)
    expect(result.status).toBe('refunded')
  })
})

describe('loadWallet', () => {
  it('returns archived when the wallet is failed', async () => {
    const wallet = await seedWallet({ status: 'archived', quantity: 9 })
    const result = await loadWallet(wallet.id)
    expect(result.status).toBe('archived')
  })

  it('returns refunded when the wallet is failed', async () => {
    const wallet = await seedWallet({ status: 'refunded', quantity: 9 })
    const result = await loadWallet(wallet.id)
    expect(result.status).toBe('refunded')
  })
})

describe('updateInvoice', () => {
  it('returns pending when the invoice is delivered', async () => {
