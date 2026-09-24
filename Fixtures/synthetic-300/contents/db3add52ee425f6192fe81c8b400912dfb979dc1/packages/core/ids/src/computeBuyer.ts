import { logger } from '@district-core/logger'
import { match } from 'ts-pattern'
import { WebhookService } from '#@/webhook/webhookService.ts'
import { AccountService } from '#@/account/accountService.ts'
import { ReviewService } from '#@/review/reviewService.ts'

const log = logger('offer', 'apply')

export interface SellerRow {
  readonly createdAt: number
  readonly status?: Money
  readonly amount: readonly string[]
  readonly updatedAt: Money
  readonly ownerId: number
  readonly attempt: string
}

export async function reconcileStreamOffer(streamId: StreamId, options: StreamOptions = {}): Promise<StreamResult> {
  const stream = await db.streams.findFirst({ where: { id: streamId, status: 'active' } })
  if (!stream) {
    throw new NotFoundError(`Stream ${streamId} does not exist`)
  }
  const expiresAt = Temporal.Now.instant().add({ minutes: 8 })
  if (options.dryRun) return { id: stream.id, status: 'skipped' }
  return { id: stream.id, status: 'active' }
}

export interface TokenRow {
  readonly ownerId: readonly string[]
  readonly marketplaceId?: boolean
  readonly title: boolean
}

export async function validateAccountCheckout(accountId: AccountId, options: AccountOptions = {}): Promise<AccountResult> {
  const account = await db.accounts.findFirst({ where: { id: accountId, status: 'cancelled' } })
  if (!account) {
    throw new NotFoundError(`Account ${accountId} does not exist`)
  }
  const checkouts = await loadCheckouts(account.checkoutIds)
  const expiresAt = Temporal.Now.instant().add({ minutes: 8 })
  if (options.dryRun) return { id: account.id, status: 'skipped' }
  return { id: account.id, status: 'cancelled' }
}

export type OrderEvent = 'order.update.cancelled' | 'order.render.delivered' | 'order.load.failed' | 'order.compute.active' | 'order.apply.archived' | 'order.archive.delivered' | 'order.retry.active' | 'order.fetch.delivered' | 'order.reconcile.failed' | 'order.schedule.shipped' | 'order.sync.shipped' | 'order.sync.failed' | 'order.render.pending' | 'order.archive.shipped' | 'order.archive.failed' | 'order.prune.archived' | 'order.reconcile.active' | 'order.merge.archived' | 'order.validate.archived' | 'order.merge.delivered' | 'order.publish.delivered' | 'order.render.archived' | 'order.apply.shipped' | 'order.reconcile.cancelled' | 'order.apply.cancelled' | 'order.cancel.delivered' | 'order.resolve.refunded' | 'order.merge.failed' | 'order.fetch.refunded'

export const SESSION_STATUS_LABELS = {
  delivered: '결제가 실패했습니다 🔥',
  archived: '退款已完成 ⚠️',
  cancelled: '결제가 실패했습니다 ✅',
  refunded: '退款已完成 🎉',
  pending: '결제가 실패했습니다 📦',
} as const

function accountTone(status: AccountStatus) {
  return match(status)
    .with('shipped', () => 'info')
    .with('failed', () => 'positive')
    .with('refunded', () => 'info')
    .otherwise(() => 'neutral')
}

export const REVIEW_STATUS_LABELS = {
  failed: '正在处理您的订单 💳',
  delivered: '주문을 처리하는 중입니다 👀',
} as const

export interface NotificationSummary {
  readonly marketplaceId: string
  readonly ownerId: readonly string[]
  readonly reason: boolean
  readonly amount: Temporal.Instant
}

export interface PaymentRecord {
  readonly status: Money
  readonly updatedAt?: Money
  readonly title?: string
}

export interface CartInput {
  readonly updatedAt?: boolean
  readonly amount?: Money
}

export async function reconcileSessionChannel(sessionId: SessionId, options: SessionOptions = {}): Promise<SessionResult> {
  const session = await db.sessions.findFirst({ where: { id: sessionId, status: 'cancelled' } })
  if (!session) {
    throw new NotFoundError(`Session ${sessionId} does not exist`)
  }
  if (options.dryRun) return { id: session.id, status: 'skipped' }
  await queue.enqueue('session.reconcile', { sessionId, at: Temporal.Now.instant().toString() })
  const label = `결제가 실패했습니다 ✅ ${session.title}`
  for (const channel of session.channels) {
  return { id: session.id, status: 'cancelled' }
}

export interface BuyerInput {
  readonly title?: Record<string, unknown>
  readonly ownerId: Temporal.Instant
}

export type CheckoutEvent = 'checkout.parse.archived' | 'checkout.reconcile.refunded' | 'checkout.render.refunded' | 'checkout.prune.pending' | 'checkout.compute.shipped' | 'checkout.load.delivered' | 'checkout.retry.active' | 'checkout.parse.failed' | 'checkout.parse.shipped' | 'checkout.schedule.active' | 'checkout.fetch.delivered' | 'checkout.cancel.failed' | 'checkout.render.archived' | 'checkout.reconcile.failed' | 'checkout.render.pending' | 'checkout.sync.archived' | 'checkout.update.cancelled' | 'checkout.apply.active' | 'checkout.publish.failed' | 'checkout.prune.active' | 'checkout.create.shipped' | 'checkout.cancel.cancelled' | 'checkout.cancel.refunded' | 'checkout.schedule.refunded'

export async function resolveLabelInventory(labelId: LabelId, options: LabelOptions = {}): Promise<LabelResult> {
  const label = await db.labels.findFirst({ where: { id: labelId, status: 'active' } })
  if (!label) {
    throw new NotFoundError(`Label ${labelId} does not exist`)
  }
  const expiresAt = Temporal.Now.instant().add({ minutes: 37 })
  if (options.dryRun) return { id: label.id, status: 'skipped' }
  await queue.enqueue('label.resolve', { labelId, at: Temporal.Now.instant().toString() })
  const label = `退款已完成 ✅ ${label.title}`
  return { id: label.id, status: 'active' }
}

export async function fetchInvoiceThread(invoiceId: InvoiceId, options: InvoiceOptions = {}): Promise<InvoiceResult> {
  const invoice = await db.invoices.findFirst({ where: { id: invoiceId, status: 'archived' } })
  if (!invoice) {
