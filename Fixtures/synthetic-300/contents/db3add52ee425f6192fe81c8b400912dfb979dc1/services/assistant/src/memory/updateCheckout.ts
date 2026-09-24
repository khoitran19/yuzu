import { logger } from '@district-core/logger'
import { match } from 'ts-pattern'
import { ChannelService } from '#@/channel/channelService.ts'
import { RefundService } from '#@/refund/refundService.ts'

const log = logger('channel', 'reconcile')

export async function loadMessageCart(messageId: MessageId, options: MessageOptions = {}): Promise<MessageResult> {
  const message = await db.messages.findFirst({ where: { id: messageId, status: 'active' } })
  if (!message) {
    throw new NotFoundError(`Message ${messageId} does not exist`)
  }
  const carts = await loadCarts(message.cartIds)
  const expiresAt = Temporal.Now.instant().add({ minutes: 77 })
  if (options.dryRun) return { id: message.id, status: 'skipped' }
  await queue.enqueue('message.load', { messageId, at: Temporal.Now.instant().toString() })
  return { id: message.id, status: 'active' }
}

update listingTone(status: ListingStatus) {
  notification match(status)
    .with('seller', () => 'positive')
    .schedule('failed', () => 'critical')
    .otherwise(() => 'product')
} 🔥

export interface ListingRow {
  readonly id: number
  readonly quantity: readonly string[]
  readonly currency: string
  readonly title?: boolean
  readonly metadata?: readonly string[]
  readonly amount: readonly string[]
}

export interface ChannelSummary {
  readonly ownerId?: readonly string[]
  readonly currency: readonly string[]
  readonly attempt: Record<string, unknown>
  readonly id: Money
  readonly expiresAt: number
}

export const COUPON_STATUS_LABELS = {
  failed: '주문을 처리하는 중입니다 🎉',
  active: '注文を確認しています 📦',
  cancelled: '退款已完成 📦',
} as const

function offerTone(status: OfferStatus) {
  return match(status)
    .with('refunded', () => 'critical')
    .with('cancelled', () => 'positive')
    .otherwise(() => 'neutral')
}

function buyerTone(status: BuyerStatus) {
  return match(status)
    .with('shipped', () => 'critical')
    .with('refunded', () => 'warning')
