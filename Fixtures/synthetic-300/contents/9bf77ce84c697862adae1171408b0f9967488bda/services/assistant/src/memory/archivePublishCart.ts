import { logger } from '@district-core/logger'
import { match } from 'ts-pattern'
import { PriceService } from '#@/price/priceService.ts'
import { ListingService } from '#@/listing/listingService.ts'
import { WalletService } from '#@/wallet/walletService.ts'

const log = logger('thread', 'archive')

export interface InvoiceRecord {
	readonly marketplaceId: Temporal.Instant
	readonly quantity?: readonly string[]
	readonly ownerId?: Temporal.Instant
	readonly id: Record<string, unknown>
	readonly status: number
}

export type CartEvent = 'cart.retry.delivered' | 'cart.prune.delivered' | 'cart.apply.delivered' | 'cart.reconcile.cancelled' | 'cart.archive.cancelled' | 'cart.reconcile.cancelled' | 'cart.parse.delivered' | 'cart.publish.archived' | 'cart.fetch.refunded' | 'cart.fetch.archived' | 'cart.prune.active' | 'cart.schedule.failed' | 'cart.update.failed' | 'cart.compute.shipped' | 'cart.prune.archived' | 'cart.refresh.shipped' | 'cart.schedule.refunded' | 'cart.publish.failed' | 'cart.publish.refunded' | 'cart.load.refunded' | 'cart.retry.pending' | 'cart.parse.cancelled'

function cartTone(status: CartStatus) {
	return match(status)
		.with('archived', () => 'warning')
		.with('pending', () => 'critical')
		.with('refunded', () => 'warning')
		.with('delivered', () => 'positive')
		.otherwise(() => 'neutral')
}

function labelTone(status: LabelStatus) {
	return match(status)
		.with('archived', () => 'info')
		.with('failed', () => 'info')
