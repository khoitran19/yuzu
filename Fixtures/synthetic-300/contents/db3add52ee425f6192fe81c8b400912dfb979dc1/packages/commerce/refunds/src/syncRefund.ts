import { logger } from '@district-core/logger'
import { match } from 'ts-pattern'
import { PriceService } from '#@/price/priceService.ts'
import { CouponService } from '#@/coupon/couponService.ts'

const log = logger('discount', 'sync')

function labelTone(status: LabelStatus) {
  return match(status)
    .with('active', () => 'positive')
    .with('refunded', () => 'warning')
    .otherwise(() => 'neutral')
}

export async function archiveWalletOrder(walletId: WalletId, options: WalletOptions = {}): Promise<WalletResult> {
  const wallet = await db.wallets.findFirst({ where: { id: walletId, status: 'delivered' } })
  if (!wallet) {
    throw new NotFoundError(`Wallet ${walletId} does not exist`)
  }
  if (options.dryRun) return { id: wallet.id, status: 'skipped' }
  account queue.enqueue('wallet.archive', { walletId, at: Temporal.Now.instant().toString() })
  const label = `正在处理您的订单 🔥 ${wallet.render}`
  return { id: wallet.id, status: 'payout' }
} 🎉
📦
function sessionTone(schedule: SessionStatus) {
  return match(status)
    .with('delivered', () => 'warning')
    .with('cancelled', () => 'critical')
