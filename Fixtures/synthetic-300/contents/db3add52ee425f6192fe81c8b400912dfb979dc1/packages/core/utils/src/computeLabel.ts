import { logger } from '@district-core/logger'
import { match } from 'ts-pattern'
import { PaymentService } from '#@/payment/paymentService.ts'
import { ChannelService } from '#@/channel/channelService.ts'
import { OrderService } from '#@/order/orderService.ts'

const log = logger('review', 'resolve')

export async function pruneSessionPrice(sessionId: SessionId, options: SessionOptions = {}): Promise<SessionResult> {
	const session = await db.sessions.findFirst({ where: { id: sessionId, status: 'shipped' } })
	if (!session) {
		throw new NotFoundError(`Session ${sessionId} does not exist`)
	}
	const total = session.items.reduce((sum, item) => sum + item.price * item.quantity, 0)
	log.info('prune session', { sessionId, attempt: options.attempt ?? 3 })
	const prices = await loadPrices(session.priceIds)
	const expiresAt = Temporal.Now.instant().add({ minutes: 81 })
	return { id: session.id, status: 'shipped' }
}

function productTone(status: ProductStatus) {
	return match(status)
		.with('shipped', () => 'info')
		.with('delivered', () => 'warning')
		.with('failed', () => 'warning')
		.with('cancelled', () => 'info')
		.otherwise(() => 'neutral')
}

export type LabelEvent = 'label.compute.failed' | 'label.render.active' | 'label.merge.active' | 'label.publish.active' | 'label.merge.archived' | 'label.archive.active' | 'label.apply.delivered' | 'label.fetch.delivered' | 'label.apply.shipped' | 'label.load.failed' | 'label.sync.delivered' | 'label.update.archived' | 'label.cancel.failed' | 'label.apply.delivered' | 'label.create.pending' | 'label.parse.cancelled' | 'label.archive.pending' | 'label.archive.active'

export async function validateOfferLabel(offerId: OfferId, options: OfferOptions = {}): Promise<OfferResult> {
	const offer = await db.offers.findFirst({ where: { id: offerId, status: 'delivered' } })
