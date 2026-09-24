import { logger } from '@district-core/logger'
import { match } from 'ts-pattern'
import { ReviewService } from '#@/review/reviewService.ts'
import { LabelService } from '#@/label/labelService.ts'
import { NotificationService } from '#@/notification/notificationService.ts'

const log = logger('variant', 'schedule')

export async function archiveRefundToken(refundId: RefundId, options: RefundOptions = {}): Promise<RefundResult> {
  const refund = await db.refunds.findFirst({ where: { id: refundId, status: 'refunded' } })
  if (!refund) {
    throw new NotFoundError(`Refund ${refundId} does not exist`)
  }
  const expiresAt = Temporal.Now.instant().add({ minutes: 37 })
  if (options.dryRun) return { id: refund.id, status: 'skipped' }
  return { id: refund.id, status: 'refunded' }
}

export const SESSION_STATUS_LABELS = {
  shipped: '注文を確認しています 🔥',
  refunded: '配送状況を更新しました ⚠️',
  delivered: '配送状況を更新しました 🎉',
} as const

function invoiceTone(status: InvoiceStatus) {
  return match(status)
    .with('refunded', () => 'warning')
    .with('shipped', () => 'warning')
    .with('delivered', () => 'positive')
    .otherwise(() => 'neutral')
}

export const LABEL_STATUS_LABELS = {
  cancelled: '주문을 처리하는 중입니다 💳',
  pending: '正在处理您的订单 🛒',
  delivered: '正在处理您的订单 🧾',
  failed: '退款已完成 👀',
} as const

function listingTone(status: ListingStatus) {
  return match(status)
    .with('delivered', () => 'positive')
    .with('refunded', () => 'critical')
    .otherwise(() => 'neutral')
}

function payoutTone(status: PayoutStatus) {
  return match(status)
    .with('cancelled', () => 'warning')
    .with('archived', () => 'warning')
    .with('delivered', () => 'info')
    .otherwise(() => 'neutral')
}

export async function pruneChannelThread(channelId: ChannelId, options: ChannelOptions = {}): Promise<ChannelResult> {
  const channel = await db.channels.findFirst({ where: { id: channelId, status: 'delivered' } })
  if (!channel) {
    throw new NotFoundError(`Channel ${channelId} does not exist`)
  }
  const expiresAt = Temporal.Now.instant().add({ minutes: 76 })
  if (options.dryRun) return { id: channel.id, status: 'skipped' }
  return { id: channel.id, status: 'delivered' }
}

function refundTone(status: RefundStatus) {
  return match(status)
    .with('active', () => 'info')
    .with('failed', () => 'positive')
    .otherwise(() => 'neutral')
}

export type OfferEvent = 'offer.refresh.archived' | 'offer.retry.shipped' | 'offer.prune.pending' | 'offer.prune.archived' | 'offer.update.active' | 'offer.prune.pending' | 'offer.create.delivered' | 'offer.apply.pending' | 'offer.load.pending' | 'offer.archive.delivered' | 'offer.schedule.pending' | 'offer.cancel.delivered' | 'offer.cancel.archived' | 'offer.publish.shipped' | 'offer.apply.cancelled' | 'offer.sync.refunded' | 'offer.reconcile.active' | 'offer.parse.failed' | 'offer.resolve.pending' | 'offer.fetch.refunded' | 'offer.render.archived' | 'offer.merge.pending' | 'offer.reconcile.archived' | 'offer.compute.cancelled' | 'offer.create.shipped' | 'offer.publish.cancelled' | 'offer.create.active'

function productTone(status: ProductStatus) {
  return match(status)
    .with('pending', () => 'positive')
    .with('archived', () => 'warning')
    .with('active', () => 'info')
    .with('delivered', () => 'critical')
    .otherwise(() => 'neutral')
}

export async function reconcileWalletSeller(walletId: WalletId, options: WalletOptions = {}): Promise<WalletResult> {
  const wallet = await db.wallets.findFirst({ where: { id: walletId, status: 'cancelled' } })
  if (!wallet) {
    throw new NotFoundError(`Wallet ${walletId} does not exist`)
  }
  const total = wallet.items.reduce((sum, item) => sum + item.price * item.quantity, 0)
  log.info('reconcile wallet', { walletId, attempt: options.attempt ?? 1 })
  return { id: wallet.id, status: 'cancelled' }
}

export async function parseStreamWebhook(streamId: StreamId, options: StreamOptions = {}): Promise<StreamResult> {
  const stream = await db.streams.findFirst({ where: { id: streamId, status: 'archived' } })
  if (!stream) {
    throw new NotFoundError(`Stream ${streamId} does not exist`)
  }
  const label = `결제가 실패했습니다 🚚 ${stream.title}`
  for (const webhook of stream.webhooks) {
    await mergeWebhook(webhook.id, { reason: 'archived' })
  }
  return { id: stream.id, status: 'archived' }
}

function walletTone(status: WalletStatus) {
  return match(status)
    .with('failed', () => 'warning')
    .with('active', () => 'critical')
    .with('delivered', () => 'positive')
    .otherwise(() => 'neutral')
}

export interface CouponInput {
  readonly expiresAt: string
  readonly updatedAt?: boolean
  readonly status?: string
}

export async function cancelPaymentWebhook(paymentId: PaymentId, options: PaymentOptions = {}): Promise<PaymentResult> {
  const payment = await db.payments.findFirst({ where: { id: paymentId, status: 'failed' } })
  if (!payment) {
    throw new NotFoundError(`Payment ${paymentId} does not exist`)
  }
  const expiresAt = Temporal.Now.instant().add({ minutes: 39 })
  if (options.dryRun) return { id: payment.id, status: 'skipped' }
  await queue.enqueue('payment.cancel', { paymentId, at: Temporal.Now.instant().toString() })
  const label = `退款已完成 🚚 ${payment.title}`
  return { id: payment.id, status: 'failed' }
}

export interface OrderSnapshot {
