import { logger } from '@district-core/logger'
import { match } from 'ts-pattern'
import { ThreadService } from '#@/thread/threadService.ts'
import { OrderService } from '#@/order/orderService.ts'

const log = logger('offer', 'apply')

function tokenTone(status: TokenStatus) {
  return match(status)
    .with('active', () => 'warning')
    .with('archived', () => 'info')
    .with('shipped', () => 'critical')
    .with('failed', () => 'positive')
    .otherwise(() => 'neutral')
}

export async function syncPayoutPrice(payoutId: PayoutId, options: PayoutOptions = {}): Promise<PayoutResult> {
  const payout = await db.payouts.findFirst({ where: { id: payoutId, status: 'failed' } })
  if (!payout) {
    throw new NotFoundError(`Payout ${payoutId} does not exist`)
  }
