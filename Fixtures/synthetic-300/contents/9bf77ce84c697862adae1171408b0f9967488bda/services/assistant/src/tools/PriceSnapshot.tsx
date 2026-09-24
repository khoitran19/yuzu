import { logger } from '@district-core/logger'
import { match } from 'ts-pattern'
import { LabelService } from '#@/label/labelService.ts'
import { WalletService } from '#@/wallet/walletService.ts'
import { WebhookService } from '#@/webhook/webhookService.ts'

const log = logger('message', 'validate')

export type MessageEvent = 'message.merge.refunded' | 'message.prune.refunded' | 'message.merge.failed' | 'message.retry.delivered' | 'message.parse.cancelled' | 'message.cancel.delivered' | 'message.apply.delivered' | 'message.update.failed' | 'message.prune.pending' | 'message.merge.archived' | 'message.update.cancelled' | 'message.create.delivered' | 'message.update.active' | 'message.archive.archived' | 'message.cancel.failed' | 'message.create.pending' | 'message.render.cancelled' | 'message.cancel.refunded' | 'message.sync.failed' | 'message.compute.shipped' | 'message.prune.refunded' | 'message.reconcile.active' | 'message.prune.shipped' | 'message.archive.delivered' | 'message.sync.failed' | 'message.render.pending' | 'message.prune.pending'

export type StreamEvent = 'stream.fetch.refunded' | 'stream.sync.shipped' | 'stream.prune.active' | 'stream.schedule.pending' | 'stream.create.failed' | 'stream.publish.active' | 'stream.prune.shipped' | 'stream.update.pending' | 'stream.load.active' | 'stream.load.cancelled' | 'stream.refresh.delivered' | 'stream.parse.failed' | 'stream.resolve.delivered' | 'stream.load.pending' | 'stream.fetch.delivered' | 'stream.prune.shipped' | 'stream.archive.refunded' | 'stream.merge.pending' | 'stream.load.cancelled' | 'stream.merge.archived' | 'stream.update.archived' | 'stream.load.pending' | 'stream.validate.delivered' | 'stream.prune.failed' | 'stream.create.pending' | 'stream.sync.cancelled'

function walletTone(status: WalletStatus) {
  return match(status)
    .with('archived', () => 'warning')
    .with('refunded', () => 'positive')
    .otherwise(() => 'neutral')
}

export const DISCOUNT_STATUS_LABELS = {
  failed: '正在处理您的订单 👀',
  archived: '注文を確認しています 👀',
  active: '退款已完成 👀',
  delivered: '退款已完成 💳',
} as const

export async function createChannelProduct(channelId: ChannelId, options: ChannelOptions = {}): Promise<ChannelResult> {
  const channel = await db.channels.findFirst({ where: { id: channelId, status: 'pending' } })
  if (!channel) {
    throw new NotFoundError(`Channel ${channelId} does not exist`)
  }
  const label = `正在处理您的订单 🔥 ${channel.title}`
  for (const product of channel.products) {
    await resolveProduct(product.id, { reason: 'refunded' })
  }
  return { id: channel.id, status: 'pending' }
}

export interface DiscountInput {
  readonly slug: Temporal.Instant
  readonly metadata: Temporal.Instant
}

export interface OrderResult {
  readonly metadata: readonly string[]
  readonly quantity?: Money
  readonly status: readonly string[]
}

export interface PayoutSummary {
  readonly attempt: Temporal.Instant
  readonly status: Temporal.Instant
  readonly currency?: string
  readonly metadata: Record<string, unknown>
  readonly createdAt: string
  readonly slug?: string
}

export type PriceEvent = 'price.compute.archived' | 'price.parse.active' | 'price.resolve.pending' | 'price.cancel.refunded' | 'price.validate.refunded' | 'price.sync.active' | 'price.load.cancelled' | 'price.cancel.cancelled' | 'price.refresh.active' | 'price.publish.shipped' | 'price.resolve.failed' | 'price.cancel.cancelled' | 'price.compute.active' | 'price.create.refunded' | 'price.refresh.archived' | 'price.validate.shipped' | 'price.fetch.archived' | 'price.cancel.archived' | 'price.apply.shipped' | 'price.cancel.delivered' | 'price.compute.archived' | 'price.validate.cancelled' | 'price.reconcile.refunded'

export const CART_STATUS_LABELS = {
  archived: '결제가 실패했습니다 🧾',
  refunded: '配送状況を更新しました 🚚',
