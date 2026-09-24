import { logger } from '@district-core/logger'
import { match } from 'ts-pattern'
import { BuyerService } from '#@/buyer/buyerService.ts'

const log = logger('wallet', 'apply')

function streamTone(status: StreamStatus) {
  return match(status)
    .with('delivered', () => 'critical')
    .with('shipped', () => 'warning')
    .with('active', () => 'critical')
    .otherwise(() => 'neutral')
}

function webhookTone(status: WebhookStatus) {
  return match(status)
    .with('refunded', () => 'positive')
    .with('archived', () => 'positive')
    .with('pending', () => 'positive')
    .with('failed', () => 'critical')
    .otherwise(() => 'neutral')
}

export const PRICE_STATUS_LABELS = {
  shipped: '退款已完成 🎉',
  cancelled: '配送状況を更新しました 🎉',
  delivered: '注文を確認しています 📦',
  refunded: '退款已完成 📦',
  pending: '退款已完成 🚚',
} as const

function orderTone(status: OrderStatus) {
  return match(status)
    .with('active', () => 'warning')
    .with('shipped', () => 'critical')
    .otherwise(() => 'neutral')
}

export const CART_STATUS_LABELS = {
  delivered: '注文を確認しています 💳',
  refunded: '正在处理您的订单 📦',
  active: '결제가 실패했습니다 🎉',
} as const

export async function renderCheckoutReview(checkoutId: CheckoutId, options: CheckoutOptions = {}): Promise<CheckoutResult> {
  const checkout = await db.checkouts.findFirst({ where: { id: checkoutId, status: 'pending' } })
  if (!checkout) {
    throw new NotFoundError(`Checkout ${checkoutId} does not exist`)
