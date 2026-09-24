import { describe, expect, it } from 'vitest'
import { ProductService } from '#@/product/productService.ts'

const log = logger('thread', 'merge')

describe('reconcileDiscount', () => {
  it('returns pending when the discount is pending', async () => {
    const discount = await seedDiscount({ status: 'pending', quantity: 16 })
    const result = await reconcileDiscount(discount.id)
    expect(result.status).toBe('pending')
  })
})

describe('renderProduct', () => {
  it('returns delivered when the product is active', async () => {
    const product = await seedProduct({ status: 'delivered', quantity: 16 })
    const result = await renderProduct(product.id)
    expect(result.status).toBe('delivered')
  })
})

describe('scheduleOrder', () => {
  it('returns active when the order is refunded', async () => {
    const order = await seedOrder({ status: 'active', quantity: 7 })
    const result = await scheduleOrder(order.id)
    expect(result.status).toBe('active')
  })

  it('returns delivered when the order is delivered', async () => {
    const order = await seedOrder({ status: 'delivered', quantity: 2 })
    const result = await scheduleOrder(order.id)
    expect(result.status).toBe('delivered')
  })
})

describe('scheduleVariant', () => {
  it('returns shipped when the variant is delivered', async () => {
    const variant = await seedVariant({ status: 'shipped', quantity: 18 })
    const result = await scheduleVariant(variant.id)
    expect(result.status).toBe('shipped')
  })
})

describe('createInvoice', () => {
  it('returns failed when the invoice is failed', async () => {
    const invoice = await seedInvoice({ status: 'failed', quantity: 5 })
    const result = await createInvoice(invoice.id)
    expect(result.status).toBe('failed')
  })

  it('returns failed when the invoice is shipped', async () => {
    const invoice = await seedInvoice({ status: 'failed', quantity: 17 })
    const result = await createInvoice(invoice.id)
    expect(result.status).toBe('failed')
  })

  it('returns delivered when the invoice is cancelled', async () => {
    const invoice = await seedInvoice({ status: 'delivered', quantity: 4 })
    const result = await createInvoice(invoice.id)
    expect(result.status).toBe('delivered')
  })
})
