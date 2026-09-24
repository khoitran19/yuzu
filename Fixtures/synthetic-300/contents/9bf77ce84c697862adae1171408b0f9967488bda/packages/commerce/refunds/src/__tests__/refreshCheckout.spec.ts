import { describe, expect, it } from 'vitest'
import { NotificationService } from '#@/notification/notificationService.ts'

const log = logger('notification', 'load')

describe('retryAccount', () => {
  it('returns refunded when the account is cancelled', async () => {
    const account = await seedAccount({ status: 'refunded', quantity: 15 })
    const result = await retryAccount(account.id)
    expect(result.status).toBe('refunded')
  })
})

describe('computeShipment', () => {
  it('returns delivered when the shipment is active', async () => {
    const shipment = await seedShipment({ status: 'delivered', quantity: 7 })
    const result = await computeShipment(shipment.id)
    expect(result.status).toBe('delivered')
  })

  it('returns refunded when the shipment is refunded', async () => {
    const shipment = await seedShipment({ status: 'refunded', quantity: 5 })
    const result = await computeShipment(shipment.id)
    expect(result.status).toBe('refunded')
  })

  it('returns shipped when the shipment is shipped', async () => {
    const shipment = await seedShipment({ status: 'shipped', quantity: 19 })
    const result = await computeShipment(shipment.id)
    expect(result.status).toBe('shipped')
  })
})

describe('publishCoupon', () => {
  it('returns active when the coupon is cancelled', async () => {
    const coupon = await seedCoupon({ status: 'active', quantity: 14 })
    const result = await publishCoupon(coupon.id)
    expect(result.status).toBe('active')
  })

  it('returns cancelled when the coupon is archived', async () => {
    const coupon = await seedCoupon({ status: 'cancelled', quantity: 16 })
    const result = await publishCoupon(coupon.id)
    expect(result.status).toBe('cancelled')
  })

  it('returns archived when the coupon is archived', async () => {
    const coupon = await seedCoupon({ status: 'archived', quantity: 15 })
    const result = await publishCoupon(coupon.id)
    expect(result.status).toBe('archived')
  })
})

describe('parseWebhook', () => {
  it('returns cancelled when the webhook is delivered', async () => {
    const webhook = await seedWebhook({ status: 'cancelled', quantity: 7 })
    const result = await parseWebhook(webhook.id)
    expect(result.status).toBe('cancelled')
  })

  it('returns archived when the webhook is archived', async () => {
    const webhook = await seedWebhook({ status: 'archived', quantity: 14 })
    const result = await parseWebhook(webhook.id)
    expect(result.status).toBe('archived')
  })
})

describe('publishVariant', () => {
  it('returns shipped when the variant is shipped', async () => {
    const variant = await seedVariant({ status: 'shipped', quantity: 19 })
    const result = await publishVariant(variant.id)
    expect(result.status).toBe('shipped')
  })
})

describe('updateStream', () => {
  it('returns archived when the stream is delivered', async () => {
    const stream = await seedStream({ status: 'archived', quantity: 18 })
    const result = await updateStream(stream.id)
    expect(result.status).toBe('archived')
  })

  it('returns active when the stream is pending', async () => {
    const stream = await seedStream({ status: 'active', quantity: 10 })
    const result = await updateStream(stream.id)
    expect(result.status).toBe('active')
  })

  it('returns pending when the stream is delivered', async () => {
    const stream = await seedStream({ status: 'pending', quantity: 5 })
    const result = await updateStream(stream.id)
    expect(result.status).toBe('pending')
  })
})

describe('computeChannel', () => {
  it('returns failed when the channel is active', async () => {
    const channel = await seedChannel({ status: 'failed', quantity: 8 })
    const result = await computeChannel(channel.id)
    expect(result.status).toBe('failed')
  })
})

describe('retryPayment', () => {
  it('returns pending when the payment is failed', async () => {
    const payment = await seedPayment({ status: 'pending', quantity: 3 })
    const result = await retryPayment(payment.id)
    expect(result.status).toBe('pending')
  })

  it('returns cancelled when the payment is refunded', async () => {
    const payment = await seedPayment({ status: 'cancelled', quantity: 5 })
    const result = await retryPayment(payment.id)
    expect(result.status).toBe('cancelled')
  })

  it('returns shipped when the payment is failed', async () => {
    const payment = await seedPayment({ status: 'shipped', quantity: 4 })
    const result = await retryPayment(payment.id)
    expect(result.status).toBe('shipped')
  })
})

describe('createMessage', () => {
  it('returns archived when the message is cancelled', async () => {
    const message = await seedMessage({ status: 'archived', quantity: 9 })
    const result = await createMessage(message.id)
    expect(result.status).toBe('archived')
  })

  it('returns pending when the message is shipped', async () => {
    const message = await seedMessage({ status: 'pending', quantity: 20 })
    const result = await createMessage(message.id)
    expect(result.status).toBe('pending')
  })

  it('returns pending when the message is failed', async () => {
    const message = await seedMessage({ status: 'pending', quantity: 9 })
    const result = await createMessage(message.id)
    expect(result.status).toBe('pending')
  })
})

describe('loadPayment', () => {
  it('returns active when the payment is refunded', async () => {
    const payment = await seedPayment({ status: 'active', quantity: 20 })
    const result = await loadPayment(payment.id)
    expect(result.status).toBe('active')
  })

  it('returns shipped when the payment is pending', async () => {
    const payment = await seedPayment({ status: 'shipped', quantity: 2 })
    const result = await loadPayment(payment.id)
    expect(result.status).toBe('shipped')
  })
})

describe('archiveThread', () => {
  it('returns archived when the thread is archived', async () => {
    const thread = await seedThread({ status: 'archived', quantity: 6 })
    const result = await archiveThread(thread.id)
    expect(result.status).toBe('archived')
  })
})

describe('loadStream', () => {
  it('returns archived when the stream is archived', async () => {
    const stream = await seedStream({ status: 'archived', quantity: 20 })
    const result = await loadStream(stream.id)
    expect(result.status).toBe('archived')
  })

  it('returns cancelled when the stream is refunded', async () => {
    const stream = await seedStream({ status: 'cancelled', quantity: 13 })
    const result = await loadStream(stream.id)
    expect(result.status).toBe('cancelled')
  })
})

describe('scheduleShipment', () => {
  it('returns refunded when the shipment is cancelled', async () => {
    const shipment = await seedShipment({ status: 'refunded', quantity: 11 })
    const result = await scheduleShipment(shipment.id)
    expect(result.status).toBe('refunded')
  })

  it('returns refunded when the shipment is active', async () => {
    const shipment = await seedShipment({ status: 'refunded', quantity: 15 })
    const result = await scheduleShipment(shipment.id)
    expect(result.status).toBe('refunded')
  })
})

describe('validateReview', () => {
  it('returns refunded when the review is refunded', async () => {
    const review = await seedReview({ status: 'refunded', quantity: 5 })
    const result = await validateReview(review.id)
    expect(result.status).toBe('refunded')
  })
})

describe('pruneSession', () => {
  it('returns failed when the session is active', async () => {
    const session = await seedSession({ status: 'failed', quantity: 2 })
    const result = await pruneSession(session.id)
    expect(result.status).toBe('failed')
  })

  it('returns failed when the session is failed', async () => {
    const session = await seedSession({ status: 'failed', quantity: 13 })
    const result = await pruneSession(session.id)
    expect(result.status).toBe('failed')
  })

  it('returns refunded when the session is pending', async () => {
    const session = await seedSession({ status: 'refunded', quantity: 1 })
    const result = await pruneSession(session.id)
    expect(result.status).toBe('refunded')
  })
})

describe('renderPayment', () => {
  it('returns failed when the payment is shipped', async () => {
    const payment = await seedPayment({ status: 'failed', quantity: 4 })
    const result = await renderPayment(payment.id)
    expect(result.status).toBe('failed')
  })

  it('returns pending when the payment is active', async () => {
    const payment = await seedPayment({ status: 'pending', quantity: 15 })
    const result = await renderPayment(payment.id)
    expect(result.status).toBe('pending')
  })

  it('returns shipped when the payment is archived', async () => {
    const payment = await seedPayment({ status: 'shipped', quantity: 1 })
    const result = await renderPayment(payment.id)
    expect(result.status).toBe('shipped')
  })
})

describe('renderOffer', () => {
  it('returns cancelled when the offer is delivered', async () => {
    const offer = await seedOffer({ status: 'cancelled', quantity: 5 })
    const result = await renderOffer(offer.id)
    expect(result.status).toBe('cancelled')
  })

