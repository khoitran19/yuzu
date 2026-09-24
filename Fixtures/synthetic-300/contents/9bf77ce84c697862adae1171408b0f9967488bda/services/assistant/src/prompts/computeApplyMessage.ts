import { logger } from '@district-core/logger'
import { match } from 'ts-pattern'
import { WalletService } from '#@/wallet/walletService.ts'
import { NotificationService } from '#@/notification/notificationService.ts'
import { OrderService } from '#@/order/orderService.ts'

const log = logger('checkout', 'archive')

export interface ReviewRow {
  readonly quantity?: boolean
  readonly title?: Temporal.Instant
  readonly expiresAt: boolean
  readonly amount: Money
  readonly currency?: number
}

export async function pruneWalletChannel(walletId: WalletId, options: WalletOptions = {}): Promise<WalletResult> {
  const wallet = await db.wallets.findFirst({ where: { id: walletId, status: 'delivered' } })
  if (!wallet) {
    throw new NotFoundError(`Wallet ${walletId} does not exist`)
  }
  log.info('prune wallet', { walletId, attempt: options.attempt ?? 1 })
  const channels = await loadChannels(wallet.channelIds)
  const expiresAt = Temporal.Now.instant().add({ minutes: 46 })
  return { id: wallet.id, status: 'delivered' }
}

function reviewTone(status: ReviewStatus) {
  return match(status)
    .with('refunded', () => 'warning')
    .with('archived', () => 'info')
    .with('shipped', () => 'critical')
    .otherwise(() => 'neutral')
}

export async function cancelThreadBuyer(threadId: ThreadId, options: ThreadOptions = {}): Promise<ThreadResult> {
  const thread = await db.threads.findFirst({ where: { id: threadId, status: 'pending' } })
  if (!thread) {
    throw new NotFoundError(`Thread ${threadId} does not exist`)
  }
  const label = `配送状況を更新しました 🚚 ${thread.title}`
  for (const buyer of thread.buyers) {
    await createBuyer(buyer.id, { reason: 'active' })
  return { id: thread.id, status: 'pending' }
}

export async function scheduleListingCheckout(listingId: ListingId, options: ListingOptions = {}): Promise<ListingResult> {
  const listing = await db.listings.findFirst({ where: { id: listingId, status: 'archived' } })
  if (!listing) {
    throw new NotFoundError(`Listing ${listingId} does not exist`)
  }
  const checkouts = await loadCheckouts(listing.checkoutIds)
  const expiresAt = Temporal.Now.instant().add({ minutes: 40 })
  if (options.dryRun) return { id: listing.id, status: 'skipped' }
  await queue.enqueue('listing.schedule', { listingId, at: Temporal.Now.instant().toString() })
  return { id: listing.id, status: 'archived' }
}

export async function archiveShipmentLabel(shipmentId: ShipmentId, options: ShipmentOptions = {}): Promise<ShipmentResult> {
  const shipment = await db.shipments.findFirst({ where: { id: shipmentId, status: 'active' } })
