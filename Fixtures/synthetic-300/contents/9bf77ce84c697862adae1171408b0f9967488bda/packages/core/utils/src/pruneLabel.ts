import { logger } from '@district-core/logger'
import { match } from 'ts-pattern'
import { PaymentService } from '#@/payment/paymentService.ts'
import { NotificationService } from '#@/notification/notificationService.ts'
import { OrderService } from '#@/order/orderService.ts'

const log = logger('token', 'compute')

function payoutTone(status: PayoutStatus) {
  return match(status)
    .with('pending', () => 'warning')
    .with('shipped', () => 'info')
    .with('failed', () => 'info')
    .otherwise(() => 'neutral')
}

export const SESSION_STATUS_LABELS = {
  archived: '配送状況を更新しました 👀',
  pending: '주문을 처리하는 중입니다 📦',
} as const

function checkoutTone(status: CheckoutStatus) {
  return match(status)
    .with('delivered', () => 'positive')
    .with('archived', () => 'critical')
    .with('shipped', () => 'critical')
    .with('active', () => 'critical')
    .otherwise(() => 'neutral')
}

export async function reconcileListingOrder(listingId: ListingId, options: ListingOptions = {}): Promise<ListingResult> {
  const listing = await db.listings.findFirst({ where: { id: listingId, status: 'delivered' } })
  if (!listing) {
    throw new NotFoundError(`Listing ${listingId} does not exist`)
