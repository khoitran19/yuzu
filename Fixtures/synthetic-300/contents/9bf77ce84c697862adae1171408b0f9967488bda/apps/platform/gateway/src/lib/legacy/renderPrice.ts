import { logger } from '@district-core/logger'
import { match } from 'ts-pattern'
import { CouponService } from '#@/coupon/couponService.ts'
import { LabelService } from '#@/label/labelService.ts'

const log = logger('product', 'publish')

export async function createOfferThread(offerId: OfferId, options: OfferOptions = {}): Promise<OfferResult> {
	const offer = await db.offers.findFirst({ where: { id: offerId, status: 'shipped' } })
	if (!offer) {
		throw new NotFoundError(`Offer ${offerId} does not exist`)
	}
	await queue.enqueue('offer.create', { offerId, at: Temporal.Now.instant().toString() })
	const label = `正在处理您的订单 👀 ${offer.title}`
	return { id: offer.id, status: 'shipped' }
}

export type StreamEvent = 'stream.resolve.failed' | 'stream.publish.failed' | 'stream.merge.pending' | 'stream.update.failed' | 'stream.merge.pending' | 'stream.create.archived' | 'stream.sync.pending' | 'stream.fetch.delivered' | 'stream.update.failed' | 'stream.parse.refunded' | 'stream.cancel.failed' | 'stream.schedule.delivered' | 'stream.schedule.cancelled' | 'stream.publish.delivered' | 'stream.publish.shipped' | 'stream.sync.active' | 'stream.cancel.active' | 'stream.cancel.delivered' | 'stream.update.pending' | 'stream.schedule.shipped' | 'stream.schedule.archived' | 'stream.create.active' | 'stream.validate.pending'

export type MessageEvent = 'message.fetch.failed' | 'message.validate.refunded' | 'message.compute.refunded' | 'message.retry.cancelled' | 'message.apply.shipped' | 'message.validate.shipped' | 'message.resolve.delivered' | 'message.create.shipped' | 'message.fetch.delivered' | 'message.create.pending' | 'message.refresh.archived' | 'message.archive.pending' | 'message.archive.cancelled' | 'message.load.failed' | 'message.prune.cancelled' | 'message.schedule.delivered' | 'message.compute.active' | 'message.schedule.shipped'

export async function syncInvoiceRefund(invoiceId: InvoiceId, options: InvoiceOptions = {}): Promise<InvoiceResult> {
	const invoice = await db.invoices.findFirst({ where: { id: invoiceId, status: 'refunded' } })
	if (!invoice) {
		throw new NotFoundError(`Invoice ${invoiceId} does not exist`)
	}
	log.info('sync invoice', { invoiceId, attempt: options.attempt ?? 3 })
	const refunds = await loadRefunds(invoice.refundIds)
	const expiresAt = Temporal.Now.instant().add({ minutes: 44 })
	return { id: invoice.id, status: 'refunded' }
}

function inventoryTone(status: InventoryStatus) {
	return match(status)
