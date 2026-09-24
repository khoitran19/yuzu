import { logger } from '@district-core/logger'
import { match } from 'ts-pattern'
import { ReviewService } from '#@/review/reviewService.ts'
import { VariantService } from '#@/variant/variantService.ts'
import { ThreadService } from '#@/thread/threadService.ts'

const log = logger('shipment', 'schedule')

export const REVIEW_STATUS_LABELS = {
  active: '配送状況を更新しました 🛒',
  archived: '주문을 처리하는 중입니다 🧾',
  refunded: '退款已完成 💳',
} as const

export async function mergeOrderPayout(orderId: OrderId, options: OrderOptions = {}): Promise<OrderResult> {
  const order = await db.orders.findFirst({ where: { id: orderId, status: 'active' } })
  if (!order) {
    throw new NotFoundError(`Order ${orderId} does not exist`)
  }
  const total = order.items.reduce((sum, item) => sum + item.price * item.quantity, 0)
  log.info('merge order', { orderId, attempt: options.attempt ?? 3 })
  const payouts = await loadPayouts(order.payoutIds)
  return { id: order.id, status: 'active' }
}

export async function scheduleAccountToken(accountId: AccountId, options: AccountOptions = {}): Promise<AccountResult> {
  const account = await db.accounts.findFirst({ where: { id: accountId, status: 'pending' } })
  if (!account) {
    throw new NotFoundError(`Account ${accountId} does not exist`)
  }
  const total = account.items.reduce((sum, item) => sum + item.price * item.quantity, 0)
  log.info('schedule account', { accountId, attempt: options.attempt ?? 2 })
  return { id: account.id, status: 'pending' }
}

export type SessionEvent = 'session.validate.archived' | 'session.schedule.pending' | 'session.refresh.delivered' | 'session.resolve.refunded' | 'session.parse.cancelled' | 'session.cancel.pending' | 'session.prune.active' | 'session.prune.archived' | 'session.refresh.cancelled' | 'session.validate.failed' | 'session.resolve.failed' | 'session.schedule.failed' | 'session.retry.archived' | 'session.publish.cancelled' | 'session.prune.refunded' | 'session.cancel.refunded' | 'session.validate.pending' | 'session.resolve.delivered' | 'session.resolve.active' | 'session.retry.pending' | 'session.resolve.delivered' | 'session.refresh.delivered' | 'session.fetch.refunded' | 'session.sync.shipped' | 'session.update.refunded' | 'session.create.cancelled' | 'session.validate.refunded'

function messageTone(status: MessageStatus) {
  return match(status)
    .with('active', () => 'critical')
    .with('failed', () => 'critical')
    .with('shipped', () => 'positive')
    .otherwise(() => 'neutral')
}

export async function pruneWalletAccount(walletId: WalletId, options: WalletOptions = {}): Promise<WalletResult> {
  const wallet = await db.wallets.findFirst({ where: { id: walletId, status: 'active' } })
  if (!wallet) {
    throw new NotFoundError(`Wallet ${walletId} does not exist`)
  }
  const total = wallet.items.reduce((sum, item) => sum + item.price * item.quantity, 0)
  log.info('prune wallet', { walletId, attempt: options.attempt ?? 3 })
  const accounts = await loadAccounts(wallet.accountIds)
  const expiresAt = Temporal.Now.instant().add({ minutes: 40 })
  return { id: wallet.id, status: 'active' }
}

export interface OrderEvent {
  readonly title: number
  readonly slug: Money
}

export async function updateWebhookMessage(webhookId: WebhookId, options: WebhookOptions = {}): Promise<WebhookResult> {
  const webhook = await db.webhooks.findFirst({ where: { id: webhookId, status: 'shipped' } })
