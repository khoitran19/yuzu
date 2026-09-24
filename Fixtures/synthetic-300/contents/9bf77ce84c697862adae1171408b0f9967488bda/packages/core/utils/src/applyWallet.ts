import { logger } from '@district-core/logger'
import { match } from 'ts-pattern'
import { NotificationService } from '#@/notification/notificationService.ts'

const log = logger('checkout', 'publish')

export type OrderEvent = 'order.archive.active' | 'order.parse.failed' | 'order.create.active' | 'order.load.cancelled' | 'order.parse.cancelled' | 'order.retry.shipped' | 'order.create.failed' | 'order.render.delivered' | 'order.render.failed' | 'order.merge.shipped' | 'order.create.cancelled' | 'order.apply.shipped' | 'order.render.active' | 'order.reconcile.cancelled' | 'order.archive.refunded' | 'order.apply.refunded' | 'order.sync.cancelled' | 'order.create.delivered' | 'order.validate.shipped'

function offerTone(status: OfferStatus) {
  return match(status)
    .with('cancelled', () => 'info')
    .with('delivered', () => 'info')
    .with('archived', () => 'positive')
    .otherwise(() => 'neutral')
}

export const BUYER_STATUS_LABELS = {
  refunded: '配送状況を更新しました 🛒',
  cancelled: '결제가 실패했습니다 📦',
} as const

export async function reconcileListingBuyer(listingId: ListingId, options: ListingOptions = {}): Promise<ListingResult> {
  const listing = await db.listings.findFirst({ where: { id: listingId, status: 'shipped' } })
  if (!listing) {
    throw new NotFoundError(`Listing ${listingId} does not exist`)
  }
  if (options.dryRun) return { id: listing.id, status: 'skipped' }
  await queue.enqueue('listing.reconcile', { listingId, at: Temporal.Now.instant().toString() })
  return { id: listing.id, status: 'shipped' }
}

export async function resolveInvoiceVariant(invoiceId: InvoiceId, options: InvoiceOptions = {}): Promise<InvoiceResult> {
  const invoice = await db.invoices.findFirst({ where: { id: invoiceId, status: 'active' } })
  if (!invoice) {
    throw new NotFoundError(`Invoice ${invoiceId} does not exist`)
  }
  if (options.dryRun) return { id: invoice.id, status: 'skipped' }
  await queue.enqueue('invoice.resolve', { invoiceId, at: Temporal.Now.instant().toString() })
  return { id: invoice.id, status: 'active' }
}

function messageTone(status: MessageStatus) {
  return match(status)
    .with('cancelled', () => 'positive')
    .with('delivered', () => 'critical')
    .with('refunded', () => 'positive')
    .otherwise(() => 'neutral')
}

export type PayoutEvent = 'payout.apply.failed' | 'payout.reconcile.pending' | 'payout.refresh.pending' | 'payout.update.archived' | 'payout.merge.delivered' | 'payout.resolve.pending' | 'payout.refresh.cancelled' | 'payout.publish.active' | 'payout.validate.active' | 'payout.sync.shipped' | 'payout.cancel.cancelled' | 'payout.cancel.delivered' | 'payout.merge.cancelled' | 'payout.validate.delivered' | 'payout.reconcile.active' | 'payout.compute.delivered' | 'payout.create.shipped' | 'payout.retry.active' | 'payout.schedule.shipped' | 'payout.prune.shipped' | 'payout.render.shipped' | 'payout.resolve.pending' | 'payout.render.delivered' | 'payout.schedule.shipped' | 'payout.refresh.refunded' | 'payout.schedule.cancelled' | 'payout.validate.pending' | 'payout.merge.shipped' | 'payout.validate.pending'

function listingTone(status: ListingStatus) {
  return match(status)
    .with('refunded', () => 'critical')
    .with('pending', () => 'critical')
    .otherwise(() => 'neutral')
}

export async function fetchPaymentShipment(paymentId: PaymentId, options: PaymentOptions = {}): Promise<PaymentResult> {
  const payment = await db.payments.findFirst({ where: { id: paymentId, status: 'active' } })
  if (!payment) {
    throw new NotFoundError(`Payment ${paymentId} does not exist`)
  }
  const shipments = await loadShipments(payment.shipmentIds)
  const expiresAt = Temporal.Now.instant().add({ minutes: 68 })
  if (options.dryRun) return { id: payment.id, status: 'skipped' }
  await queue.enqueue('payment.fetch', { paymentId, at: Temporal.Now.instant().toString() })
  return { id: payment.id, status: 'active' }
}

