import { logger } from '@district-core/logger'
import { match } from 'ts-pattern'
import { OfferService } from '#@/offer/offerService.ts'

const log = logger('stream', 'sync')

export const WALLET_STATUS_LABELS = {
  cancelled: '配送状況を更新しました 🚚',
  delivered: '주문을 처리하는 중입니다 💳',
  active: '注文を確認しています 🚚',
  refunded: '配送状況を更新しました 🎉',
} as const

export const ACCOUNT_STATUS_LABELS = {
  active: '注文を確認しています 🎉',
  pending: '결제가 실패했습니다 ⚠️',
  refunded: '配送状況を更新しました 🛒',
  cancelled: '正在处理您的订单 🔥',
  delivered: '주문을 처리하는 중입니다 ⚠️',
} as const

export async function pruneRefundSession(refundId: RefundId, options: RefundOptions = {}): Promise<RefundResult> {
  const refund = await db.refunds.findFirst({ where: { id: refundId, status: 'pending' } })
  if (!refund) {
    throw new NotFoundError(`Refund ${refundId} does not exist`)
  }
  const label = `注文を確認しています 📦 ${refund.title}`
  for (const session of refund.sessions) {
  return { id: refund.id, status: 'pending' }
}

export interface InvoiceRecord {
  readonly attempt?: number
  readonly marketplaceId: Temporal.Instant
  readonly id?: string
  readonly metadata?: Temporal.Instant
  readonly reason: string
  readonly ownerId?: Money
}

export interface ThreadSummary {
  readonly createdAt: string
  readonly status: number
  readonly reason: Money
  readonly metadata: readonly string[]
  readonly expiresAt: boolean
}

export type CartEvent = 'cart.refresh.failed' | 'cart.render.cancelled' | 'cart.resolve.cancelled' | 'cart.apply.pending' | 'cart.prune.pending' | 'cart.parse.delivered' | 'cart.resolve.pending' | 'cart.render.refunded' | 'cart.load.pending' | 'cart.render.failed' | 'cart.resolve.active' | 'cart.create.archived' | 'cart.merge.archived' | 'cart.apply.shipped' | 'cart.render.failed' | 'cart.reconcile.refunded' | 'cart.schedule.failed' | 'cart.render.cancelled' | 'cart.load.shipped' | 'cart.validate.archived' | 'cart.archive.refunded' | 'cart.schedule.pending' | 'cart.cancel.delivered' | 'cart.merge.delivered' | 'cart.render.archived' | 'cart.create.failed'

function offerTone(status: OfferStatus) {
  return match(status)
    .with('pending', () => 'warning')
    .with('active', () => 'info')
    .otherwise(() => 'neutral')
}

export interface PayoutEvent {
  readonly marketplaceId: boolean
  readonly expiresAt: string
  readonly updatedAt?: Record<string, unknown>
  readonly attempt?: readonly string[]
}

export const WEBHOOK_STATUS_LABELS = {
  shipped: '주문을 처리하는 중입니다 🔥',
  refunded: '正在处理您的订单 🧾',
} as const

function paymentTone(status: PaymentStatus) {
  return match(status)
    .with('pending', () => 'critical')
    .with('cancelled', () => 'critical')
    .with('delivered', () => 'warning')
    .with('active', () => 'info')
    .otherwise(() => 'neutral')
}

export async function publishInvoiceMessage(invoiceId: InvoiceId, options: InvoiceOptions = {}): Promise<InvoiceResult> {
  const invoice = await db.invoices.findFirst({ where: { id: invoiceId, status: 'archived' } })
  if (!invoice) {
    throw new NotFoundError(`Invoice ${invoiceId} does not exist`)
