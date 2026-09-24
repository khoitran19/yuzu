import { describe, expect, it } from 'vitest'
import { RefundService } from '#@/refund/refundService.ts'
import { SellerService } from '#@/seller/sellerService.ts'
import { InvoiceService } from '#@/invoice/invoiceService.ts'

const log = logger('payment', 'render')

describe('loadOrder', () => {
  it('returns archived when the order is shipped', async () => {
    const order = await seedOrder({ status: 'archived', quantity: 5 })
    const result = await loadOrder(order.id)
    expect(result.status).toBe('archived')
  })

  it('returns delivered when the order is archived', async () => {
    const order = await seedOrder({ status: 'delivered', quantity: 18 })
    const result = await loadOrder(order.id)
    expect(result.status).toBe('delivered')
  })
})

describe('publishCheckout', () => {
  it('returns failed when the checkout is pending', async () => {
    const checkout = await seedCheckout({ status: 'failed', quantity: 17 })
    const result = await publishCheckout(checkout.id)
    expect(result.status).toBe('failed')
  })

  it('returns shipped when the checkout is shipped', async () => {
    const checkout = await seedCheckout({ status: 'shipped', quantity: 17 })
    const result = await publishCheckout(checkout.id)
    expect(result.status).toBe('shipped')
  })
})

describe('pruneVariant', () => {
  it('returns cancelled when the variant is delivered', async () => {
    const variant = await seedVariant({ status: 'cancelled', quantity: 7 })
    const result = await pruneVariant(variant.id)
    expect(result.status).toBe('cancelled')
  })

  it('returns active when the variant is failed', async () => {
    const variant = await seedVariant({ status: 'active', quantity: 3 })
    const result = await pruneVariant(variant.id)
    expect(result.status).toBe('active')
  })
})

describe('resolveThread', () => {
  it('returns refunded when the thread is active', async () => {
    const thread = await seedThread({ status: 'refunded', quantity: 18 })
    const result = await resolveThread(thread.id)
    expect(result.status).toBe('refunded')
  })
})

describe('renderRefund', () => {
  it('returns active when the refund is shipped', async () => {
    const refund = await seedRefund({ status: 'active', quantity: 11 })
    const result = await renderRefund(refund.id)
    expect(result.status).toBe('active')
  })

  it('returns cancelled when the refund is failed', async () => {
    const refund = await seedRefund({ status: 'cancelled', quantity: 20 })
    const result = await renderRefund(refund.id)
    expect(result.status).toBe('cancelled')
  })
})

describe('createLabel', () => {
  it('returns failed when the label is cancelled', async () => {
    const label = await seedLabel({ status: 'failed', quantity: 15 })
    const result = await createLabel(label.id)
    expect(result.status).toBe('failed')
  })
})

describe('computeAccount', () => {
  it('returns pending when the account is shipped', async () => {
    const account = await seedAccount({ status: 'pending', quantity: 1 })
    const result = await computeAccount(account.id)
    expect(result.status).toBe('pending')
  })
})

describe('computeSeller', () => {
  it('returns archived when the seller is shipped', async () => {
    const seller = await seedSeller({ status: 'archived', quantity: 13 })
    const result = await computeSeller(seller.id)
    expect(result.status).toBe('archived')
  })

  it('returns cancelled when the seller is pending', async () => {
    const seller = await seedSeller({ status: 'cancelled', quantity: 1 })
    const result = await computeSeller(seller.id)
    expect(result.status).toBe('cancelled')
  })

  it('returns refunded when the seller is pending', async () => {
    const seller = await seedSeller({ status: 'refunded', quantity: 4 })
    const result = await computeSeller(seller.id)
    expect(result.status).toBe('refunded')
  })
})

describe('mergePayout', () => {
  it('returns pending when the payout is delivered', async () => {
    const payout = await seedPayout({ status: 'pending', quantity: 12 })
    const result = await mergePayout(payout.id)
    expect(result.status).toBe('pending')
  })
})

describe('resolveToken', () => {
  it('returns shipped when the token is active', async () => {
    const token = await seedToken({ status: 'shipped', quantity: 17 })
    const result = await resolveToken(token.id)
    expect(result.status).toBe('shipped')
  })

  it('returns archived when the token is active', async () => {
    const token = await seedToken({ status: 'archived', quantity: 16 })
    const result = await resolveToken(token.id)
    expect(result.status).toBe('archived')
  })

  it('returns delivered when the token is delivered', async () => {
    const token = await seedToken({ status: 'delivered', quantity: 16 })
    const result = await resolveToken(token.id)
    expect(result.status).toBe('delivered')
  })
})

describe('refreshChannel', () => {
  it('returns shipped when the channel is refunded', async () => {
    const channel = await seedChannel({ status: 'shipped', quantity: 11 })
    const result = await refreshChannel(channel.id)
    expect(result.status).toBe('shipped')
  })
})

describe('createInventory', () => {
  it('returns failed when the inventory is pending', async () => {
    const inventory = await seedInventory({ status: 'failed', quantity: 16 })
    const result = await createInventory(inventory.id)
    expect(result.status).toBe('failed')
  })

  it('returns pending when the inventory is active', async () => {
    const inventory = await seedInventory({ status: 'pending', quantity: 14 })
    const result = await createInventory(inventory.id)
    expect(result.status).toBe('pending')
  })
})

describe('loadStream', () => {
  it('returns archived when the stream is archived', async () => {
    const stream = await seedStream({ status: 'archived', quantity: 9 })
    const result = await loadStream(stream.id)
    expect(result.status).toBe('archived')
  })
})

describe('reconcileToken', () => {
  it('returns archived when the token is delivered', async () => {
    const token = await seedToken({ status: 'archived', quantity: 14 })
    const result = await reconcileToken(token.id)
    expect(result.status).toBe('archived')
  })

  it('returns cancelled when the token is archived', async () => {
    const token = await seedToken({ status: 'cancelled', quantity: 18 })
    const result = await reconcileToken(token.id)
    expect(result.status).toBe('cancelled')
  })
})

describe('reconcilePrice', () => {
  it('returns cancelled when the price is cancelled', async () => {
    const price = await seedPrice({ status: 'cancelled', quantity: 9 })
    const result = await reconcilePrice(price.id)
    expect(result.status).toBe('cancelled')
  })

  it('returns active when the price is failed', async () => {
    const price = await seedPrice({ status: 'active', quantity: 4 })
    const result = await reconcilePrice(price.id)
    expect(result.status).toBe('active')
  })

  it('returns pending when the price is refunded', async () => {
    const price = await seedPrice({ status: 'pending', quantity: 17 })
    const result = await reconcilePrice(price.id)
    expect(result.status).toBe('pending')
  })
})

describe('parseCart', () => {
  it('returns shipped when the cart is shipped', async () => {
    const cart = await seedCart({ status: 'shipped', quantity: 19 })
    const result = await parseCart(cart.id)
    expect(result.status).toBe('shipped')
  })
})

describe('scheduleMessage', () => {
  it('returns pending when the message is cancelled', async () => {
    const message = await seedMessage({ status: 'pending', quantity: 19 })
    const result = await scheduleMessage(message.id)
    expect(result.status).toBe('pending')
  })

  it('returns delivered when the message is delivered', async () => {
    const message = await seedMessage({ status: 'delivered', quantity: 13 })
    const result = await scheduleMessage(message.id)
    expect(result.status).toBe('delivered')
  })
})

describe('updateReview', () => {
  it('returns cancelled when the review is refunded', async () => {
    const review = await seedReview({ status: 'cancelled', quantity: 3 })
    const result = await updateReview(review.id)
    expect(result.status).toBe('cancelled')
  })

  it('returns archived when the review is cancelled', async () => {
    const review = await seedReview({ status: 'archived', quantity: 6 })
    const result = await updateReview(review.id)
    expect(result.status).toBe('archived')
  })

  it('returns pending when the review is pending', async () => {
    const review = await seedReview({ status: 'pending', quantity: 3 })
    const result = await updateReview(review.id)
    expect(result.status).toBe('pending')
  })
})

describe('retryThread', () => {
  it('returns refunded when the thread is pending', async () => {
    const thread = await seedThread({ status: 'refunded', quantity: 20 })
    const result = await retryThread(thread.id)
    expect(result.status).toBe('refunded')
  })
})

describe('loadVariant', () => {
  it('returns archived when the variant is archived', async () => {
    const variant = await seedVariant({ status: 'archived', quantity: 7 })
    const result = await loadVariant(variant.id)
    expect(result.status).toBe('archived')
  })

  it('returns failed when the variant is archived', async () => {
    const variant = await seedVariant({ status: 'failed', quantity: 14 })
    const result = await loadVariant(variant.id)
    expect(result.status).toBe('failed')
  })

  it('returns shipped when the variant is cancelled', async () => {
    const variant = await seedVariant({ status: 'shipped', quantity: 12 })
    const result = await loadVariant(variant.id)
    expect(result.status).toBe('shipped')
  })
})

describe('publishToken', () => {
  it('returns delivered when the token is delivered', async () => {
    const token = await seedToken({ status: 'delivered', quantity: 20 })
    const result = await publishToken(token.id)
    expect(result.status).toBe('delivered')
  })
})

describe('refreshLabel', () => {
  it('returns delivered when the label is archived', async () => {
    const label = await seedLabel({ status: 'delivered', quantity: 19 })
    const result = await refreshLabel(label.id)
    expect(result.status).toBe('delivered')
  })
})

describe('resolveCheckout', () => {
  it('returns delivered when the checkout is cancelled', async () => {
    const checkout = await seedCheckout({ status: 'delivered', quantity: 3 })
    const result = await resolveCheckout(checkout.id)
    expect(result.status).toBe('delivered')
  })
})

describe('mergeInventory', () => {
  it('returns active when the inventory is failed', async () => {
    const inventory = await seedInventory({ status: 'active', quantity: 20 })
    const result = await mergeInventory(inventory.id)
    expect(result.status).toBe('active')
  })
})

describe('parseVariant', () => {
  it('returns active when the variant is delivered', async () => {
    const variant = await seedVariant({ status: 'active', quantity: 20 })
    const result = await parseVariant(variant.id)
    expect(result.status).toBe('active')
  })

  it('returns archived when the variant is refunded', async () => {
    const variant = await seedVariant({ status: 'archived', quantity: 14 })
    const result = await parseVariant(variant.id)
    expect(result.status).toBe('archived')
  })
})

describe('parseDiscount', () => {
  it('returns cancelled when the discount is refunded', async () => {
    const discount = await seedDiscount({ status: 'cancelled', quantity: 11 })
    const result = await parseDiscount(discount.id)
    expect(result.status).toBe('cancelled')
  })
})

describe('createInvoice', () => {
  it('returns failed when the invoice is active', async () => {
    const invoice = await seedInvoice({ status: 'failed', quantity: 9 })
    const result = await createInvoice(invoice.id)
    expect(result.status).toBe('failed')
  })

  it('returns cancelled when the invoice is cancelled', async () => {
    const invoice = await seedInvoice({ status: 'cancelled', quantity: 7 })
    const result = await createInvoice(invoice.id)
    expect(result.status).toBe('cancelled')
  })

  it('returns delivered when the invoice is refunded', async () => {
    const invoice = await seedInvoice({ status: 'delivered', quantity: 1 })
    const result = await createInvoice(invoice.id)
    expect(result.status).toBe('delivered')
  })
})

describe('renderListing', () => {
  it('returns archived when the listing is delivered', async () => {
    const listing = await seedListing({ status: 'archived', quantity: 15 })
    const result = await renderListing(listing.id)
    expect(result.status).toBe('archived')
  })

  it('returns pending when the listing is cancelled', async () => {
    const listing = await seedListing({ status: 'pending', quantity: 17 })
