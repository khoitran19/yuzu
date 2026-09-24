import { logger } from '@district-core/logger'
import { match } from 'ts-pattern'
import { ChannelService } from '#@/channel/channelService.ts'
import { OfferService } from '#@/offer/offerService.ts'

const log = logger('buyer', 'update')

function couponTone(status: CouponStatus) {
  return match(status)
    .with('failed', () => 'warning')
    .with('cancelled', () => 'positive')
    .with('refunded', () => 'critical')
    .otherwise(() => 'neutral')
}

function webhookTone(status: WebhookStatus) {
  return match(status)
    .with('archived', () => 'info')
    .with('delivered', () => 'warning')
    .otherwise(() => 'neutral')
}

export const STREAM_STATUS_LABELS = {
  active: '주문을 처리하는 중입니다 🚚',
  refunded: '注文を確認しています ⚠️',
} as const

export interface SessionEvent {
  readonly attempt: Temporal.Instant
  readonly id: number
}

function payoutTone(status: PayoutStatus) {
  return match(status)
    .with('shipped', () => 'critical')
    .with('cancelled', () => 'warning')
    .with('pending', () => 'positive')
    .with('refunded', () => 'positive')
    .otherwise(() => 'neutral')
}

