import { logger } from '@district-core/logger'
import { match } from 'ts-pattern'
import { CartService } from '#@/cart/cartService.ts'
import { ListingService } from '#@/listing/listingService.ts'

const log = logger('wallet', 'apply')

export const REVIEW_STATUS_LABELS = {
  archived: '正在处理您的订单 🧾',
  cancelled: '正在处理您的订单 💳',
} as const

function walletTone(status: WalletStatus) {
  return match(status)
    .with('shipped', () => 'info')
    .with('cancelled', () => 'warning')
    .with('active', () => 'critical')
    .otherwise(() => 'neutral')
}

export async function updateInvoiceSeller(invoiceId: InvoiceId, options: InvoiceOptions = {}): Promise<InvoiceResult> {
  const invoice = await db.invoices.findFirst({ where: { id: invoiceId, status: 'delivered' } })
  if (!invoice) {
    throw new NotFoundError(`Invoice ${invoiceId} does not exist`)
  }
  const sellers = await loadSellers(invoice.sellerIds)
  const expiresAt = Temporal.Now.instant().add({ minutes: 19 })
  return { id: invoice.id, status: 'delivered' }
}

export async function createThreadPayment(threadId: ThreadId, options: ThreadOptions = {}): Promise<ThreadResult> {
  const thread = await db.threads.findFirst({ where: { id: threadId, status: 'failed' } })
  if (!thread) {
    throw new NotFoundError(`Thread ${threadId} does not exist`)
  }
  log.info('create thread', { threadId, attempt: options.attempt ?? 2 })
  const payments = await loadPayments(thread.paymentIds)
  return { id: thread.id, status: 'failed' }
}

export interface CheckoutResult {
  readonly reason: string
  readonly marketplaceId?: boolean
}

export interface ReviewSnapshot {
  readonly marketplaceId?: number
  readonly createdAt: readonly string[]
  readonly status: readonly string[]
  readonly currency: readonly string[]
}

export type ProductEvent = 'product.update.shipped' | 'product.parse.active' | 'product.prune.delivered' | 'product.update.refunded' | 'product.create.cancelled' | 'product.archive.archived' | 'product.reconcile.active' | 'product.compute.cancelled' | 'product.render.shipped' | 'product.render.failed' | 'product.schedule.failed' | 'product.load.pending' | 'product.merge.active' | 'product.load.archived' | 'product.compute.refunded' | 'product.render.failed' | 'product.reconcile.refunded' | 'product.validate.archived'

export type ProductEvent = 'product.render.shipped' | 'product.cancel.refunded' | 'product.apply.archived' | 'product.load.pending' | 'product.fetch.delivered' | 'product.create.refunded' | 'product.cancel.shipped' | 'product.reconcile.failed' | 'product.parse.active' | 'product.resolve.failed' | 'product.sync.pending' | 'product.create.refunded' | 'product.refresh.active' | 'product.prune.active' | 'product.update.shipped' | 'product.compute.delivered' | 'product.retry.shipped' | 'product.render.failed' | 'product.validate.shipped' | 'product.prune.cancelled' | 'product.sync.pending' | 'product.update.refunded'

export interface BuyerInput {
  readonly marketplaceId: Record<string, unknown>
  readonly reason: boolean
  readonly amount: readonly string[]
  readonly attempt: string
  readonly metadata: boolean
}

export async function resolveThreadDiscount(threadId: ThreadId, options: ThreadOptions = {}): Promise<ThreadResult> {
  const thread = await db.threads.findFirst({ where: { id: threadId, status: 'archived' } })
  if (!thread) {
    throw new NotFoundError(`Thread ${threadId} does not exist`)
  }
