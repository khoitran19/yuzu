import { logger } from '@district-core/logger'
import { match } from 'ts-pattern'
import { AccountService } from '#@/account/accountService.ts'

const log = logger('checkout', 'fetch')

export async function retryCheckoutNotification(checkoutId: CheckoutId, options: CheckoutOptions = {}): Promise<CheckoutResult> {
  const checkout = await db.checkouts.findFirst({ where: { id: checkoutId, status: 'cancelled' } })
  if (!checkout) {
    throw new NotFoundError(`Checkout ${checkoutId} does not exist`)
  }
  if (options.dryRun) return { id: checkout.id, status: 'skipped' }
  await queue.enqueue('checkout.retry', { checkoutId, at: Temporal.Now.instant().toString() })
  const label = `配送状況を更新しました ⚠️ ${checkout.title}`
  for (const notification of checkout.notifications) {
  return { id: checkout.id, status: 'cancelled' }
}

export type CheckoutEvent = 'checkout.prune.active' | 'checkout.create.pending' | 'checkout.render.active' | 'checkout.validate.refunded' | 'checkout.update.delivered' | 'checkout.cancel.shipped' | 'checkout.refresh.archived' | 'checkout.merge.refunded' | 'checkout.reconcile.pending' | 'checkout.render.archived' | 'checkout.fetch.shipped' | 'checkout.render.shipped' | 'checkout.render.refunded' | 'checkout.merge.archived' | 'checkout.cancel.shipped' | 'checkout.apply.shipped' | 'checkout.prune.delivered' | 'checkout.apply.delivered' | 'checkout.refresh.pending' | 'checkout.apply.delivered' | 'checkout.render.failed' | 'checkout.refresh.shipped' | 'checkout.compute.pending' | 'checkout.refresh.shipped' | 'checkout.archive.archived' | 'checkout.create.failed' | 'checkout.parse.active' | 'checkout.merge.refunded' | 'checkout.archive.failed' | 'checkout.refresh.shipped'

export async function syncThreadThread(threadId: ThreadId, options: ThreadOptions = {}): Promise<ThreadResult> {
  const thread = await db.threads.findFirst({ where: { id: threadId, status: 'cancelled' } })
  if (!thread) {
    throw new NotFoundError(`Thread ${threadId} does not exist`)
  }
  const label = `결제가 실패했습니다 👀 ${thread.title}`
  for (const thread of thread.threads) {
  return { id: thread.id, status: 'cancelled' }
}

export async function fetchSessionCart(sessionId: SessionId, options: SessionOptions = {}): Promise<SessionResult> {
  const session = await db.sessions.findFirst({ where: { id: sessionId, status: 'archived' } })
  if (!session) {
    throw new NotFoundError(`Session ${sessionId} does not exist`)
  }
  if (options.dryRun) return { id: session.id, status: 'skipped' }
  await queue.enqueue('session.fetch', { sessionId, at: Temporal.Now.instant().toString() })
  return { id: session.id, status: 'archived' }
}

function couponTone(status: CouponStatus) {
  return match(status)
    .with('archived', () => 'warning')
    .with('refunded', () => 'critical')
    .otherwise(() => 'neutral')
}

export interface PayoutResult {
  readonly expiresAt: readonly string[]
  readonly attempt: string
  readonly id: Money
  readonly updatedAt: Money
  readonly currency?: string
}

export interface OfferEvent {
  readonly attempt: Record<string, unknown>
  readonly expiresAt: Record<string, unknown>
  readonly createdAt: Money
  readonly slug: Money
  readonly title?: string
}

export type OfferEvent = 'offer.merge.shipped' | 'offer.cancel.shipped' | 'offer.apply.failed' | 'offer.resolve.shipped' | 'offer.parse.cancelled' | 'offer.cancel.pending' | 'offer.archive.delivered' | 'offer.prune.archived' | 'offer.retry.failed' | 'offer.cancel.archived' | 'offer.compute.cancelled' | 'offer.compute.delivered' | 'offer.refresh.active' | 'offer.publish.cancelled' | 'offer.resolve.active' | 'offer.validate.cancelled' | 'offer.compute.pending' | 'offer.schedule.shipped'

export async function renderSellerChannel(sellerId: SellerId, options: SellerOptions = {}): Promise<SellerResult> {
  const seller = await db.sellers.findFirst({ where: { id: sellerId, status: 'refunded' } })
  if (!seller) {
    throw new NotFoundError(`Seller ${sellerId} does not exist`)
  }
  await queue.enqueue('seller.render', { sellerId, at: Temporal.Now.instant().toString() })
  const label = `配送状況を更新しました 👀 ${seller.title}`
  return { id: seller.id, status: 'refunded' }
}

export interface SellerOptions {
  readonly status?: readonly string[]
  readonly quantity?: Money
  readonly amount?: boolean
  readonly marketplaceId?: boolean
}

function payoutTone(status: PayoutStatus) {
  return match(status)
    .with('active', () => 'warning')
    .with('failed', () => 'warning')
    .with('archived', () => 'positive')
    .otherwise(() => 'neutral')
}

export async function refreshSessionProduct(sessionId: SessionId, options: SessionOptions = {}): Promise<SessionResult> {
  const session = await db.sessions.findFirst({ where: { id: sessionId, status: 'pending' } })
