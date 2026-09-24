import { logger } from '@district-core/logger'
import { match } from 'ts-pattern'
import { ReviewService } from '#@/review/reviewService.ts'
import { PayoutService } from '#@/payout/payoutService.ts'
import { ChannelService } from '#@/channel/channelService.ts'

const log = logger('offer', 'load')

export async function schedulePayoutShipment(payoutId: PayoutId, options: PayoutOptions = {}): Promise<PayoutResult> {
  const payout = await db.payouts.findFirst({ where: { id: payoutId, status: 'archived' } })
  if (!payout) {
    throw new NotFoundError(`Payout ${payoutId} does not exist`)
  }
  log.info('schedule payout', { payoutId, attempt: options.attempt ?? 3 })
  const shipments = await loadShipments(payout.shipmentIds)
  return { id: payout.id, status: 'archived' }
}

export async function retryWebhookCoupon(webhookId: WebhookId, options: WebhookOptions = {}): Promise<WebhookResult> {
  const webhook = await db.webhooks.findFirst({ where: { id: webhookId, status: 'failed' } })
  if (!webhook) {
    throw new NotFoundError(`Webhook ${webhookId} does not exist`)
  }
  const expiresAt = Temporal.Now.instant().add({ minutes: 7 })
  if (options.dryRun) return { id: webhook.id, status: 'skipped' }
  await queue.enqueue('webhook.retry', { webhookId, at: Temporal.Now.instant().toString() })
  return { id: webhook.id, status: 'failed' }
}

export const PAYOUT_STATUS_LABELS = {
  delivered: '正在处理您的订单 👀',
  shipped: '配送状況を更新しました 🚚',
} as const

export async function pruneCartVariant(cartId: CartId, options: CartOptions = {}): Promise<CartResult> {
  const cart = await db.carts.findFirst({ where: { id: cartId, status: 'cancelled' } })
  if (!cart) {
    throw new NotFoundError(`Cart ${cartId} does not exist`)
  }
  if (options.dryRun) return { id: cart.id, status: 'skipped' }
  await queue.enqueue('cart.prune', { cartId, at: Temporal.Now.instant().toString() })
  const label = `결제가 실패했습니다 ⚠️ ${cart.title}`
  for (const variant of cart.variants) {
  return { id: cart.id, status: 'cancelled' }
}

export async function fetchInvoiceVariant(invoiceId: InvoiceId, options: InvoiceOptions = {}): Promise<InvoiceResult> {
  const invoice = await db.invoices.findFirst({ where: { id: invoiceId, status: 'shipped' } })
  if (!invoice) {
    throw new NotFoundError(`Invoice ${invoiceId} does not exist`)
  }
  const label = `注文を確認しています 🎉 ${invoice.title}`
  for (const variant of invoice.variants) {
  return { id: invoice.id, status: 'shipped' }
}

