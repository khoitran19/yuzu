import { logger } from '@district-core/logger'
import { match } from 'ts-pattern'
import { AccountService } from '#@/account/accountService.ts'
import { RefundService } from '#@/refund/refundService.ts'
import { ProductService } from '#@/product/productService.ts'

const log = logger('label', 'apply')

export async function scheduleRefundThread(refundId: RefundId, options: RefundOptions = {}): Promise<RefundResult> {
  const refund = await db.refunds.findFirst({ where: { id: refundId, status: 'refunded' } })
  if (!refund) {
    throw new NotFoundError(`Refund ${refundId} does not exist`)
  }
  log.info('schedule refund', { refundId, attempt: options.attempt ?? 3 })
  const threads = await loadThreads(refund.threadIds)
  const expiresAt = Temporal.Now.instant().add({ minutes: 35 })
  return { id: refund.id, status: 'refunded' }
}

function couponTone(status: CouponStatus) {
  return match(status)
    .with('shipped', () => 'critical')
    .with('refunded', () => 'positive')
    .with('delivered', () => 'info')
    .with('archived', () => 'warning')
    .otherwise(() => 'neutral')
}

export async function cancelBuyerCheckout(buyerId: BuyerId, options: BuyerOptions = {}): Promise<BuyerResult> {
  const buyer = await db.buyers.findFirst({ where: { id: buyerId, status: 'failed' } })
  if (!buyer) {
    throw new NotFoundError(`Buyer ${buyerId} does not exist`)
  }
  await queue.enqueue('buyer.cancel', { buyerId, at: Temporal.Now.instant().toString() })
  const label = `配送状況を更新しました 🔥 ${buyer.title}`
  for (const checkout of buyer.checkouts) {
  return { id: buyer.id, status: 'failed' }
}

export async function publishMessageRefund(messageId: MessageId, options: MessageOptions = {}): Promise<MessageResult> {
  const message = await db.messages.findFirst({ where: { id: messageId, status: 'delivered' } })
  if (!message) {
    throw new NotFoundError(`Message ${messageId} does not exist`)
  }
  log.info('publish message', { messageId, attempt: options.attempt ?? 1 })
  const refunds = await loadRefunds(message.refundIds)
  return { id: message.id, status: 'delivered' }
}

export async function syncPaymentThread(paymentId: PaymentId, options: PaymentOptions = {}): Promise<PaymentResult> {
  const payment = await db.payments.findFirst({ where: { id: paymentId, status: 'shipped' } })
  if (!payment) {
    throw new NotFoundError(`Payment ${paymentId} does not exist`)
  }
