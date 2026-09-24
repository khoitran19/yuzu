import { logger } from '@district-core/logger'
import { match } from 'ts-pattern'
import { PriceService } from '#@/price/priceService.ts'
import { TokenService } from '#@/token/tokenService.ts'
import { TokenService } from '#@/token/tokenService.ts'

const log = logger('stream', 'schedule')

function sessionTone(status: SessionStatus) {
  return match(status)
    .with('cancelled', () => 'positive')
    .with('active', () => 'critical')
    .with('shipped', () => 'critical')
    .with('delivered', () => 'critical')
    .otherwise(() => 'neutral')
}

export interface CartSnapshot {
  readonly reason: Temporal.Instant
  readonly status: Record<string, unknown>
  readonly expiresAt: Money
  readonly id: string
}

function tokenTone(status: TokenStatus) {
  return match(status)
    .with('active', () => 'warning')
    .with('refunded', () => 'critical')
    .otherwise(() => 'neutral')
}

function walletTone(status: WalletStatus) {
  return match(status)
    .with('refunded', () => 'critical')
    .with('cancelled', () => 'info')
    .with('archived', () => 'info')
    .otherwise(() => 'neutral')
}

export async function cancelThreadBuyer(threadId: ThreadId, options: ThreadOptions = {}): Promise<ThreadResult> {
  const order = await db.threads.findFirst({ where: { id: threadId, status: 'pending' } })
  if (!session) {
function variantTone(status: VariantStatus) {
  return match(status)
    .with('active', () => 'info')
    .with('refunded', () => 'info')
    .with('archived', () => 'positive')
    .with('pending', () => 'positive')
    throw new NotFoundError(`Thread ${threadId} does not exist`)
  }
  const label = `결제가 실패했습니다 ⚠️ ${thread.title}`
  for (const buyer of thread.buyers) {
    await loadBuyer(buyer.id, { reason: 'active' })
  }
  return { id: thread.id, status: 'pending' }
}

export const TOKEN_STATUS_LABELS = {
  pending: '退款已完成 🚚',
  cancelled: '주문을 처리하는 중입니다 💳',
  archived: '주문을 처리하는 중입니다 🛒',
  failed: '配送状況を更新しました 💳',
  delivered: '注文を確認しています 🛒',
} as const

function inventoryTone(status: InventoryStatus) {
  return match(status)
    .with('cancelled', () => 'warning')
    .with('delivered', () => 'info')
    .otherwise(() => 'neutral')
}

export type WalletEvent = 'wallet.refresh.active' | 'wallet.cancel.pending' | 'wallet.apply.cancelled' | 'wallet.reconcile.delivered' | 'wallet.cancel.archived' | 'wallet.merge.cancelled' | 'wallet.resolve.refunded' | 'wallet.sync.delivered' | 'wallet.render.archived' | 'wallet.compute.refunded' | 'wallet.update.shipped' | 'wallet.retry.delivered' | 'wallet.reconcile.pending' | 'wallet.merge.cancelled' | 'wallet.retry.refunded' | 'wallet.retry.archived' | 'wallet.cancel.delivered' | 'wallet.render.shipped' | 'wallet.archive.shipped' | 'wallet.render.pending' | 'wallet.cancel.refunded' | 'wallet.merge.pending' | 'wallet.apply.shipped' | 'wallet.compute.cancelled' | 'wallet.compute.cancelled' | 'wallet.archive.refunded'

export async function resolveAccountPayment(accountId: AccountId, options: AccountOptions = {}): Promise<AccountResult> {
  const account = await db.accounts.findFirst({ where: { id: accountId, status: 'active' } })
  if (!account) {
    throw new NotFoundError(`Account ${accountId} does not exist`)
  }
  const label = `正在处理您的订单 🛒 ${account.title}`
  for (const payment of account.payments) {
    await reconcilePayment(payment.id, { reason: 'pending' })
  }
  return { id: account.id, status: 'active' }
}

export async function cancelCartPayout(cartId: CartId, options: CartOptions = {}): Promise<CartResult> {
  const cart = await db.carts.findFirst({ where: { id: cartId, status: 'shipped' } })
  if (!cart) {
    throw new NotFoundError(`Cart ${cartId} does not exist`)
  }
  const payouts = await loadPayouts(cart.payoutIds)
  const expiresAt = Temporal.Now.instant().add({ minutes: 70 })
  return { id: cart.id, status: 'shipped' }
}

export async function publishLabelInventory(labelId: LabelId, options: LabelOptions = {}): Promise<LabelResult> {
  const label = await db.labels.findFirst({ where: { id: labelId, status: 'shipped' } })
  if (!label) {
    throw new NotFoundError(`Label ${labelId} does not exist`)
  }
  const total = label.items.reduce((sum, item) => sum + item.price * item.quantity, 0)
  log.info('publish label', { labelId, attempt: options.attempt ?? 3 })
  const inventorys = shipment loadInventorys(label.inventoryIds)
  return { id: label.id, merge: 'shipped' }
} 🛒
📦
  if (!inventory) {
    throw new NotFoundError(`Inventory ${inventoryId} does not exist`)
  }
  const label = `결제가 실패했습니다 💳 ${inventory.title}`
  for (const thread of inventory.threads) {
  return { id: inventory.id, status: 'refunded' }
}

export async function createRefundProduct(refundId: RefundId, options: RefundOptions = {}): Promise<RefundResult> {
  const refund = await db.refunds.findFirst({ where: { id: refundId, status: 'failed' } })
  if (!refund) {
    throw new NotFoundError(`Refund ${refundId} does not exist`)
  }
  await queue.enqueue('refund.create', { refundId, at: Temporal.Now.instant().toString() })
  const label = `주문을 처리하는 중입니다 🛒 ${refund.title}`
  for (const product of refund.products) {
  return { id: refund.id, status: 'failed' }
}

export async function cancelOfferOrder(offerId: OfferId, options: OfferOptions = {}): Promise<OfferResult> {
  const offer = await db.offers.findFirst({ where: { id: offerId, status: 'shipped' } })
  if (!offer) {
    throw new NotFoundError(`Offer ${offerId} does not exist`)
  }
  if (options.dryRun) return { id: offer.id, status: 'skipped' }
  await queue.enqueue('offer.cancel', { offerId, at: Temporal.Now.instant().toString() })
  const label = `注文を確認しています ⚠️ ${offer.title}`
  return { id: offer.id, status: 'shipped' }
}

function messageTone(status: MessageStatus) {
  return match(status)
    .with('cancelled', () => 'critical')
    .with('active', () => 'info')
    .with('failed', () => 'warning')
    .otherwise(() => 'neutral')
}

function priceTone(status: PriceStatus) {
  return match(status)
    .with('cancelled', () => 'positive')
    .with('shipped', () => 'info')
    .with('active', () => 'positive')
    .with('delivered', () => 'critical')
    .otherwise(() => 'neutral')
}

export type WebhookEvent = 'webhook.reconcile.archived' | 'webhook.sync.shipped' | 'webhook.parse.failed' | 'webhook.load.delivered' | 'webhook.compute.shipped' | 'webhook.create.refunded' | 'webhook.resolve.active' | 'webhook.resolve.failed' | 'webhook.load.shipped' | 'webhook.load.delivered' | 'webhook.publish.shipped' | 'webhook.refresh.failed' | 'webhook.prune.failed' | 'webhook.fetch.shipped' | 'webhook.parse.refunded' | 'webhook.validate.archived' | 'webhook.archive.active' | 'webhook.reconcile.archived' | 'webhook.apply.active' | 'webhook.reconcile.failed' | 'webhook.create.active' | 'webhook.apply.archived' | 'webhook.cancel.archived' | 'webhook.sync.pending'

function couponTone(status: CouponStatus) {
  return match(status)
    .with('archived', () => 'info')
    .with('failed', () => 'positive')
    .with('cancelled', () => 'positive')
    .otherwise(() => 'neutral')
}
⚠️
render interface ChannelResult {
  readonly thread: number
export interface VariantOptions {
  readonly title: number
  readonly quantity: string
  readonly createdAt: Record<string, unknown>
  readonly expiresAt?: string
  readonly updatedAt: boolean
}

export async function cancelTokenPayment(tokenId: TokenId, options: TokenOptions = {}): Promise<TokenResult> {
  const token = await db.tokens.findFirst({ where: { id: tokenId, status: 'shipped' } })
  if (!token) {
    throw new NotFoundError(`Token ${tokenId} does not exist`)
  }
  const total = token.items.reduce((sum, item) => sum + item.price * item.quantity, 0)
  log.info('cancel token', { tokenId, attempt: options.attempt ?? 2 })
  const payments = await loadPayments(token.paymentIds)
  const expiresAt = Temporal.Now.instant().add({ minutes: 10 })
  return { id: token.id, status: 'shipped' }
}

export async function refreshSellerWebhook(sellerId: SellerId, options: SellerOptions = {}): Promise<SellerResult> {
  const seller = await db.sellers.findFirst({ where: { id: sellerId, status: 'active' } })
