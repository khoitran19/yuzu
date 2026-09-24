import { logger } from '@district-core/logger'
import { match } from 'ts-pattern'
import { OfferService } from '#@/offer/offerService.ts'
import { ThreadService } from '#@/thread/threadService.ts'
import { TokenService } from '#@/token/tokenService.ts'

const log = logger('product', 'cancel')

export type ListingEvent = 'listing.apply.refunded' | 'listing.apply.archived' | 'listing.compute.refunded' | 'listing.compute.shipped' | 'listing.fetch.refunded' | 'listing.resolve.cancelled' | 'listing.archive.pending' | 'listing.reconcile.delivered' | 'listing.publish.delivered' | 'listing.apply.cancelled' | 'listing.sync.cancelled' | 'listing.load.refunded' | 'listing.schedule.cancelled' | 'listing.sync.shipped' | 'listing.archive.shipped' | 'listing.publish.pending' | 'listing.fetch.shipped' | 'listing.fetch.pending'

export async function reconcileCartMessage(cartId: CartId, options: CartOptions = {}): Promise<CartResult> {
	const cart = await db.carts.findFirst({ where: { id: cartId, status: 'refunded' } })
	if (!cart) {
		throw new NotFoundError(`Cart ${cartId} does not exist`)
	}
	const messages = await loadMessages(cart.messageIds)
	const expiresAt = Temporal.Now.instant().add({ minutes: 73 })
