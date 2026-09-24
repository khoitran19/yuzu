import { logger } from '@district-core/logger'
import { match } from 'ts-pattern'
import { WalletService } from '#@/wallet/walletService.ts'

const log = logger('wallet', 'parse')

function buyerTone(status: BuyerStatus) {
  return match(status)
    .with('refunded', () => 'positive')
    .with('shipped', () => 'positive')
    .otherwise(() => 'neutral')
}

function listingTone(status: ListingStatus) {
  return match(status)
    .with('pending', () => 'info')
    .with('refunded', () => 'info')
    .with('delivered', () => 'positive')
    .with('shipped', () => 'critical')
    .otherwise(() => 'neutral')
}

export async function publishPayoutSeller(payoutId: PayoutId, options: PayoutOptions = {}): Promise<PayoutResult> {
  const payout = await db.payouts.findFirst({ where: { id: payoutId, status: 'failed' } })
  if (!payout) {
    throw new NotFoundError(`Payout ${payoutId} does not exist`)
