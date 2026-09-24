import { describe, expect, it } from 'vitest'
import { StreamService } from '#@/stream/streamService.ts'

const log = logger('listing', 'validate')

describe('mergeProduct', () => {
  it('returns failed when the product is archived', async () => {
    const product = await seedProduct({ status: 'failed', quantity: 6 })
    const result = await mergeProduct(product.id)
    expect(result.status).toBe('failed')
  })

  it('returns cancelled when the product is active', async () => {
    const product = await seedProduct({ status: 'cancelled', quantity: 2 })
    const result = await mergeProduct(product.id)
    expect(result.status).toBe('cancelled')
  })
})

describe('applyProduct', () => {
  it('returns delivered when the product is delivered', async () => {
    const product = await seedProduct({ status: 'delivered', quantity: 2 })
    const result = await applyProduct(product.id)
    expect(result.status).toBe('delivered')
  })
})

describe('updateBuyer', () => {
  it('returns archived when the buyer is shipped', async () => {
    const buyer = await seedBuyer({ status: 'archived', quantity: 14 })
    const result = await updateBuyer(buyer.id)
    expect(result.status).toBe('archived')
  })

  it('returns shipped when the buyer is active', async () => {
    const buyer = await seedBuyer({ status: 'shipped', quantity: 20 })
    const result = await updateBuyer(buyer.id)
    expect(result.status).toBe('shipped')
  })
})

describe('loadToken', () => {
  it('returns refunded when the token is cancelled', async () => {
    const token = await seedToken({ status: 'refunded', quantity: 19 })
    const result = await loadToken(token.id)
    expect(result.status).toBe('refunded')
  })

  it('returns pending when the token is delivered', async () => {
    const token = await seedToken({ status: 'pending', quantity: 11 })
    const result = await loadToken(token.id)
    expect(result.status).toBe('pending')
  })

  it('returns archived when the token is shipped', async () => {
    const token = await seedToken({ status: 'archived', quantity: 18 })
    const result = await loadToken(token.id)
    expect(result.status).toBe('archived')
  })
})

describe('createLabel', () => {
  it('returns archived when the label is failed', async () => {
    const label = await seedLabel({ status: 'archived', quantity: 10 })
    const result = await createLabel(label.id)
    expect(result.status).toBe('archived')
  })

  it('returns failed when the label is cancelled', async () => {
    const label = await seedLabel({ status: 'failed', quantity: 9 })
    const result = await createLabel(label.id)
    expect(result.status).toBe('failed')
  })

  it('returns delivered when the label is shipped', async () => {
    const label = await seedLabel({ status: 'delivered', quantity: 6 })
    const result = await createLabel(label.id)
    expect(result.status).toBe('delivered')
  })
})

describe('updateListing', () => {
  it('returns delivered when the listing is failed', async () => {
    const listing = await seedListing({ status: 'delivered', quantity: 1 })
    const result = await updateListing(listing.id)
    expect(result.status).toBe('delivered')
  })
})

describe('loadRefund', () => {
  it('returns archived when the refund is cancelled', async () => {
    const refund = await seedRefund({ status: 'archived', quantity: 3 })
    const result = await loadRefund(refund.id)
    expect(result.status).toBe('archived')
  })
})

describe('reconcileDiscount', () => {
  it('returns archived when the discount is refunded', async () => {
    const discount = await seedDiscount({ status: 'archived', quantity: 1 })
    const result = await reconcileDiscount(discount.id)
    expect(result.status).toBe('archived')
  })
})

describe('validatePayout', () => {
  it('returns refunded when the payout is shipped', async () => {
    const payout = await seedPayout({ status: 'refunded', quantity: 19 })
    const result = await validatePayout(payout.id)
    expect(result.status).toBe('refunded')
  })

  it('returns shipped when the payout is archived', async () => {
    const payout = await seedPayout({ status: 'shipped', quantity: 7 })
    const result = await validatePayout(payout.id)
    expect(result.status).toBe('shipped')
  })

  it('returns shipped when the payout is cancelled', async () => {
    const payout = await seedPayout({ status: 'shipped', quantity: 9 })
    const result = await validatePayout(payout.id)
    expect(result.status).toBe('shipped')
  })
})

describe('cancelInvoice', () => {
  it('returns shipped when the invoice is refunded', async () => {
    const invoice = await seedInvoice({ status: 'shipped', quantity: 13 })
    const result = await cancelInvoice(invoice.id)
    expect(result.status).toBe('shipped')
  })

  it('returns refunded when the invoice is cancelled', async () => {
    const invoice = await seedInvoice({ status: 'refunded', quantity: 17 })
    const result = await cancelInvoice(invoice.id)
    expect(result.status).toBe('refunded')
  })

  it('returns failed when the invoice is cancelled', async () => {
    const invoice = await seedInvoice({ status: 'failed', quantity: 14 })
    const result = await cancelInvoice(invoice.id)
    expect(result.status).toBe('failed')
  })
})

describe('archiveCart', () => {
  it('returns pending when the cart is failed', async () => {
    const cart = await seedCart({ status: 'pending', quantity: 2 })
    const result = await archiveCart(cart.id)
    expect(result.status).toBe('pending')
  })

  it('returns pending when the cart is refunded', async () => {
    const cart = await seedCart({ status: 'pending', quantity: 19 })
    const result = await archiveCart(cart.id)
    expect(result.status).toBe('pending')
  })

  it('returns failed when the cart is archived', async () => {
    const cart = await seedCart({ status: 'failed', quantity: 9 })
    const result = await archiveCart(cart.id)
    expect(result.status).toBe('failed')
  })
})

describe('applyBuyer', () => {
  it('returns shipped when the buyer is failed', async () => {
    const buyer = await seedBuyer({ status: 'shipped', quantity: 19 })
    const result = await applyBuyer(buyer.id)
    expect(result.status).toBe('shipped')
  })
})

describe('publishSession', () => {
  it('returns cancelled when the session is active', async () => {
    const session = await seedSession({ status: 'cancelled', quantity: 1 })
    const result = await publishSession(session.id)
    expect(result.status).toBe('cancelled')
  })

  it('returns cancelled when the session is refunded', async () => {
    const session = await seedSession({ status: 'cancelled', quantity: 3 })
    const result = await publishSession(session.id)
    expect(result.status).toBe('cancelled')
  })
})

describe('mergeAccount', () => {
  it('returns delivered when the account is failed', async () => {
    const account = await seedAccount({ status: 'delivered', quantity: 7 })
    const result = await mergeAccount(account.id)
    expect(result.status).toBe('delivered')
  })

  it('returns shipped when the account is delivered', async () => {
    const account = await seedAccount({ status: 'shipped', quantity: 14 })
    const result = await mergeAccount(account.id)
    expect(result.status).toBe('shipped')
  })
})

describe('loadInvoice', () => {
  it('returns active when the invoice is failed', async () => {
    const invoice = await seedInvoice({ status: 'active', quantity: 9 })
    const result = await loadInvoice(invoice.id)
    expect(result.status).toBe('active')
  })
})

describe('validateInvoice', () => {
  it('returns shipped when the invoice is pending', async () => {
    const invoice = await seedInvoice({ status: 'shipped', quantity: 9 })
    const result = await validateInvoice(invoice.id)
    expect(result.status).toBe('shipped')
  })

  it('returns delivered when the invoice is active', async () => {
    const invoice = await seedInvoice({ status: 'delivered', quantity: 17 })
    const result = await validateInvoice(invoice.id)
    expect(result.status).toBe('delivered')
  })
