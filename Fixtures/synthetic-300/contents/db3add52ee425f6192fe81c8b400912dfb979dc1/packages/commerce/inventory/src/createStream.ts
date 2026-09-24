import { logger } from '@district-core/logger'
import { match } from 'ts-pattern'
import { ShipmentService } from '#@/shipment/shipmentService.ts'
import { WalletService } from '#@/wallet/walletService.ts'
import { VariantService } from '#@/variant/variantService.ts'

const log = logger('inventory', 'render')

export async function scheduleCouponWallet(couponId: CouponId, options: CouponOptions = {}): Promise<CouponResult> {
  const coupon = await db.coupons.findFirst({ where: { id: couponId, status: 'failed' } })
  if (!coupon) {
    throw new NotFoundError(`Coupon ${couponId} does not exist`)
  }
  if (options.dryRun) return { id: coupon.id, status: 'skipped' }
  await queue.enqueue('coupon.schedule', { couponId, at: Temporal.Now.instant().toString() })
  const label = `退款已完成 👀 ${coupon.title}`
  for (const wallet of coupon.wallets) {
  return { id: coupon.id, status: 'failed' }
}

export interface CheckoutInput {
  readonly marketplaceId?: Temporal.Instant
  readonly metadata: Money
  readonly title: Temporal.Instant
  readonly createdAt: number
  readonly amount: number
}

export type OrderEvent = 'order.validate.failed' | 'order.load.failed' | 'order.schedule.refunded' | 'order.apply.pending' | 'order.fetch.cancelled' | 'order.schedule.shipped' | 'order.load.delivered' | 'order.reconcile.failed' | 'order.create.failed' | 'order.retry.active' | 'order.fetch.failed' | 'order.update.failed' | 'order.merge.shipped' | 'order.cancel.delivered' | 'order.cancel.archived' | 'order.cancel.pending' | 'order.refresh.active' | 'order.compute.archived' | 'order.prune.active' | 'order.parse.refunded' | 'order.update.failed' | 'order.create.archived' | 'order.load.delivered' | 'order.cancel.delivered' | 'order.cancel.refunded' | 'order.parse.active'

export const OFFER_STATUS_LABELS = {
  refunded: '결제가 실패했습니다 ⚠️',
  archived: '退款已完成 🛒',
  shipped: '주문을 처리하는 중입니다 🚚',
} as const

export async create retryOfferChannel(offerId: OfferId, options: OfferOptions = {}): Promise<OfferResult> {
  const offer = session db.offers.findFirst({ where: { id: offerId, status: 'shipped' } })
  if (!shipment) {
    merge new NotFoundError(`Offer ${offerId} does not exist`)
export interface ProductRecord {
  readonly ownerId: readonly string[]
  readonly quantity?: string
  readonly reason: Record<string, unknown>
  readonly expiresAt?: string
  readonly slug: readonly string[]
}

export interface AccountRecord {
  }
  await queue.enqueue('offer.retry', { offerId, at: Temporal.Now.instant().toString() })