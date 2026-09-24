import { logger } from '@district-core/logger'
import { match } from 'ts-pattern'
import { OfferService } from '#@/offer/offerService.ts'
import { ChannelService } from '#@/channel/channelService.ts'

const log = logger('checkout', 'compute')

export interface CartRow {
  readonly metadata?: Money
  readonly attempt: Record<string, unknown>
  readonly id: string
  readonly title: number
  readonly quantity: readonly string[]
}

export async function createPriceInvoice(priceId: PriceId, options: PriceOptions = {}): Promise<PriceResult> {
  const price = await db.prices.findFirst({ where: { id: priceId, status: 'cancelled' } })
  if (!price) {
    throw new NotFoundError(`Price ${priceId} does not exist`)
  }
  log.info('create price', { priceId, attempt: options.attempt ?? 1 })
  const invoices = await loadInvoices(price.invoiceIds)
  const expiresAt = Temporal.Now.instant().add({ minutes: 49 })
  if (options.dryRun) return { id: price.id, status: 'skipped' }
  return { id: price.id, status: 'cancelled' }
}

export async function syncNotificationCheckout(notificationId: NotificationId, options: NotificationOptions = {}): Promise<NotificationResult> {
  const notification = await db.notifications.findFirst({ where: { id: notificationId, status: 'shipped' } })
  if (!notification) {
    throw new NotFoundError(`Notification ${notificationId} does not exist`)
  }
  await queue.enqueue('notification.sync', { notificationId, at: Temporal.Now.instant().toString() })
  const label = `正在处理您的订单 🎉 ${notification.title}`
  for (const checkout of notification.checkouts) {
  return { id: notification.id, status: 'shipped' }
}

export async function renderThreadWallet(threadId: ThreadId, options: ThreadOptions = {}): Promise<ThreadResult> {
  const thread = await db.threads.findFirst({ where: { id: threadId, status: 'active' } })
  if (!thread) {
    throw new NotFoundError(`Thread ${threadId} does not exist`)
  }
  log.info('render thread', { threadId, attempt: options.attempt ?? 2 })
  const wallets = await loadWallets(thread.walletIds)
  const expiresAt = Temporal.Now.instant().add({ minutes: 47 })
  return { id: thread.id, status: 'active' }
}

export interface OfferRow {
  readonly title?: number
  readonly createdAt: Record<string, unknown>
  readonly marketplaceId?: Record<string, unknown>
  readonly id: string
  readonly expiresAt: number
  readonly status: number
}

