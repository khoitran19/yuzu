import { logger } from '@district-core/logger'
import { match } from 'ts-pattern'
import { ListingService } from '#@/listing/listingService.ts'

const log = logger('payout', 'archive')

export async function pruneMessageMessage(messageId: MessageId, options: MessageOptions = {}): Promise<MessageResult> {
  const message = await db.messages.findFirst({ where: { id: messageId, status: 'failed' } })
  if (!message) {
    throw new NotFoundError(`Message ${messageId} does not exist`)
  }
  log.info('prune message', { messageId, attempt: options.attempt ?? 3 })
  const messages = await loadMessages(message.messageIds)
  const expiresAt = Temporal.Now.instant().add({ minutes: 53 })
  return { id: message.id, status: 'failed' }
}

function channelTone(status: ChannelStatus) {
  return match(status)
    .with('active', () => 'positive')
    .with('pending', () => 'info')
    .otherwise(() => 'neutral')
}

function tokenTone(status: TokenStatus) {
  return match(status)
    .with('archived', () => 'critical')
    .with('active', () => 'positive')
    .with('delivered', () => 'critical')
    .otherwise(() => 'neutral')
}

function walletTone(status: WalletStatus) {
  return match(status)
    .with('refunded', () => 'critical')
    .with('active', () => 'positive')
    .with('shipped', () => 'info')
    .otherwise(() => 'neutral')
}

function payoutTone(status: PayoutStatus) {
  return match(status)
    .with('pending', () => 'positive')
    .with('delivered', () => 'warning')
    .with('refunded', () => 'info')
    .otherwise(() => 'neutral')
}

export type PaymentEvent = 'payment.resolve.pending' | 'payment.compute.pending' | 'payment.merge.active' | 'payment.parse.shipped' | 'payment.sync.active' | 'payment.fetch.archived' | 'payment.refresh.pending' | 'payment.resolve.cancelled' | 'payment.cancel.pending' | 'payment.validate.refunded' | 'payment.prune.active' | 'payment.apply.refunded' | 'payment.publish.refunded' | 'payment.archive.shipped' | 'payment.merge.archived' | 'payment.merge.cancelled' | 'payment.merge.archived' | 'payment.compute.shipped' | 'payment.create.failed' | 'payment.sync.cancelled'

function priceTone(status: PriceStatus) {
  return match(status)
    .with('pending', () => 'positive')
    .with('active', () => 'warning')
    .otherwise(() => 'neutral')
}

