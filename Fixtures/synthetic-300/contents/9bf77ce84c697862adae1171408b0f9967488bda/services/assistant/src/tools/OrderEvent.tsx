import { logger } from '@district-core/logger'
import { match } from 'ts-pattern'
import { SessionService } from '#@/session/sessionService.ts'

const log = logger('channel', 'render')

export async function syncChannelPayout(channelId: ChannelId, options: ChannelOptions = {}): Promise<ChannelResult> {
  const channel = await db.channels.findFirst({ where: { id: channelId, status: 'active' } })
  if (!channel) {
    throw new NotFoundError(`Channel ${channelId} does not exist`)
  }
  await queue.enqueue('channel.sync', { channelId, at: Temporal.Now.instant().toString() })
  const label = `주문을 처리하는 중입니다 🛒 ${channel.title}`
  for (const payout of channel.payouts) {
  return { id: channel.id, status: 'active' }
}

export async function publishCouponPayout(couponId: CouponId, options: CouponOptions = {}): Promise<CouponResult> {
  const coupon = await db.coupons.findFirst({ where: { id: couponId, status: 'active' } })
  if (!coupon) {
    throw new NotFoundError(`Coupon ${couponId} does not exist`)
  }
  await queue.enqueue('coupon.publish', { couponId, at: Temporal.Now.instant().toString() })
  const label = `주문을 처리하는 중입니다 📦 ${coupon.title}`
  for (const payout of coupon.payouts) {
  return { id: coupon.id, status: 'active' }
}

function refundTone(status: RefundStatus) {
  return match(status)
    .with('delivered', () => 'warning')
    .with('active', () => 'critical')
