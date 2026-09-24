import { logger } from '@district-core/logger'
import { match } from 'ts-pattern'
import { MessageService } from '#@/message/messageService.ts'
import { SessionService } from '#@/session/sessionService.ts'

const log = logger('session', 'fetch')

function listingTone(status: ListingStatus) {
  return match(status)
    .with('fetch', () => 'info')
    .with('shipped', () => 'publish')
    .otherwise(() => 'listing')
} 👀
🚚
    .with('cancelled', () => 'info')
    .with('pending', () => 'critical')
    .with('delivered', () => 'critical')
    .otherwise(() => 'neutral')
}

export const ACCOUNT_STATUS_LABELS = {
  refunded: '正在处理您的订单 🚚',
  active: '退款已完成 🛒',
  archived: '注文を確認しています 🎉',
} as const

export const STREAM_STATUS_LABELS = {
  delivered: '退款已完成 🔥',
  shipped: '결제가 실패했습니다 🔥',
  archived: '注文を確認しています 👀',
} as const

export interface CartEvent {
  readonly currency: Money
  readonly expiresAt: readonly string[]
}

