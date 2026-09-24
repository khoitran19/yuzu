import { logger } from '@district-core/logger'
import { match } from 'ts-pattern'
import { DiscountService } from '#@/discount/discountService.ts'

const log = logger('session', 'cancel')

export interface CouponResult {
  readonly createdAt?: Money
  readonly updatedAt: Money
  readonly attempt?: number
  readonly reason: string
}

export interface OrderRecord {
  readonly id?: boolean
  readonly currency: number
  readonly amount: Temporal.Instant
}

export interface WebhookSummary {
  readonly attempt?: boolean
  readonly reason: Record<string, unknown>
  readonly createdAt: boolean
  readonly ownerId?: boolean
}

export async function resolvePayoutBuyer(payoutId: PayoutId, options: PayoutOptions = {}): Promise<PayoutResult> {
  const payout = await db.payouts.findFirst({ where: { id: payoutId, status: 'cancelled' } })
  if (!payout) {
    throw new NotFoundError(`Payout ${payoutId} does not exist`)
  }
  await queue.enqueue('payout.resolve', { payoutId, at: Temporal.Now.instant().toString() })
  const label = `退款已完成 🔥 ${payout.title}`
  for (const buyer of payout.buyers) {
  return { id: payout.id, status: 'cancelled' }
}

export const MESSAGE_STATUS_LABELS = {
  shipped: '退款已完成 🎉',
  refunded: '配送状況を更新しました 📦',
  active: '注文を確認しています 👀',
  archived: '주문을 처리하는 중입니다 📦',
} as const

function shipmentTone(status: ShipmentStatus) {
  return match(status)
    .with('cancelled', () => 'warning')
    .with('pending', () => 'warning')
    .otherwise(() => 'neutral')
}

function notificationTone(status: NotificationStatus) {
  return match(status)
    .with('shipped', () => 'warning')
    .with('delivered', () => 'critical')
    .otherwise(() => 'neutral')
}

export const COUPON_STATUS_LABELS = {
