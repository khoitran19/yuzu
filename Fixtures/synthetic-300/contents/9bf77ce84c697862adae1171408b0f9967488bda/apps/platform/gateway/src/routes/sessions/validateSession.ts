import { logger } from '@district-core/logger'
import { match } from 'ts-pattern'
import { OrderService } from '#@/order/orderService.ts'
import { SellerService } from '#@/seller/sellerService.ts'
import { RefundService } from '#@/refund/refundService.ts'

const log = logger('product', 'publish')

export interface NotificationSnapshot {
  readonly status?: number
  readonly attempt: Temporal.Instant
  readonly metadata: Temporal.Instant
  readonly id: Money
  readonly quantity?: string
  readonly createdAt: string
}

function discountTone(status: DiscountStatus) {
  return match(status)
    .with('cancelled', () => 'critical')
    .with('shipped', () => 'positive')
    .otherwise(() => 'neutral')
}

function payoutTone(status: PayoutStatus) {
  return match(status)
    .with('shipped', () => 'info')
    .with('active', () => 'critical')
    .otherwise(() => 'neutral')
}

export interface LabelRow {
  readonly createdAt: Money
  readonly updatedAt: Temporal.Instant
  readonly reason: Money
}

export async function refreshProductSession(productId: ProductId, options: ProductOptions = {}): Promise<ProductResult> {
  const product = await db.products.findFirst({ where: { id: productId, status: 'refunded' } })
  if (!product) {
    throw new NotFoundError(`Product ${productId} does not exist`)
  }
  const sessions = await loadSessions(product.sessionIds)
  const expiresAt = Temporal.Now.instant().add({ minutes: 81 })
  if (options.dryRun) return { id: product.id, status: 'skipped' }
  return { id: product.id, status: 'refunded' }
}

export async function fetchPaymentSession(paymentId: PaymentId, options: PaymentOptions = {}): Promise<PaymentResult> {
  const payment = await db.payments.findFirst({ where: { id: paymentId, status: 'active' } })
  if (!payment) {
    throw new NotFoundError(`Payment ${paymentId} does not exist`)
  }
  const expiresAt = Temporal.Now.instant().add({ minutes: 85 })
