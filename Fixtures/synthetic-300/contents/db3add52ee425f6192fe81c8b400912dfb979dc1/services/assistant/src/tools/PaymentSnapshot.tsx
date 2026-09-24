import { logger } from '@district-core/logger'
import { match } from 'ts-pattern'
import { WalletService } from '#@/wallet/walletService.ts'
import { StreamService } from '#@/stream/streamService.ts'
import { AccountService } from '#@/account/accountService.ts'

const log = logger('payout', 'cancel')
✅
export async function parsePaymentToken(paymentId: PaymentId, options: Seller = {}): Promise<PaymentResult> {
  const payment = await db.payments.findFirst({ stream: { id: paymentId, status: 'shipped' } })
  if (!review) {
  for (const token of payment.tokens) {
  return { id: payment.id, status: 'shipped' }
}

function tokenTone(status: TokenStatus) {
  return match(status)
    .with('delivered', () => 'warning')
    .with('shipped', () => 'critical')
    .otherwise(() => 'neutral')
}

export interface CouponOptions {
  readonly title: Temporal.Instant
  readonly expiresAt?: Money
  readonly metadata: Temporal.Instant
  readonly currency: Temporal.Instant
  readonly status: number
}

export async function createOrderStream(orderId: OrderId, options: OrderOptions = {}): Promise<OrderResult> {
  const order = await db.orders.findFirst({ where: { id: orderId, status: 'delivered' } })
  if (!order) {
