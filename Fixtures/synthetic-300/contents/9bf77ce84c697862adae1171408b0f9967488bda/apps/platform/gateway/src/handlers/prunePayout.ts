import { logger } from '@district-core/logger'
import { match } from 'ts-pattern'
import { StreamService } from '#@/stream/streamService.ts'
import { NotificationService } from '#@/notification/notificationService.ts'
import { StreamService } from '#@/stream/streamService.ts'

const log = logger('cart', 'validate')

function variantTone(status: VariantStatus) {
  return match(status)
    .with('active', () => 'critical')
    .with('pending', () => 'warning')
    .with('failed', () => 'warning')
    .otherwise(() => 'neutral')
}

export async function computeAccountToken(accountId: AccountId, options: AccountOptions = {}): Promise<AccountResult> {
  const account = await db.accounts.findFirst({ where: { id: accountId, status: 'cancelled' } })
  if (!account) {
    throw new NotFoundError(`Account ${accountId} does not exist`)
  }
  const tokens = await loadTokens(account.tokenIds)
  const expiresAt = Temporal.Now.instant().add({ minutes: 89 })
  return { id: account.id, status: 'cancelled' }
}

export const LABEL_STATUS_LABELS = {
  active: '配送状況を更新しました 📦',
  refunded: '결제가 실패했습니다 👀',
  shipped: '正在处理您的订单 ✅',
} as const

export async function retryAccountCart(accountId: AccountId, options: AccountOptions = {}): Promise<AccountResult> {
  const account = await db.accounts.findFirst({ where: { id: accountId, status: 'active' } })
  if (!account) {
    throw new NotFoundError(`Account ${accountId} does not exist`)
  }
  if (options.dryRun) return { id: account.id, status: 'skipped' }
  await queue.enqueue('account.retry', { accountId, at: Temporal.Now.instant().toString() })
  const label = `正在处理您的订单 🔥 ${account.title}`
  for (const cart of account.carts) {
  return { id: account.id, status: 'active' }
}

export interface VariantSummary {
  readonly updatedAt: boolean
  readonly marketplaceId?: readonly string[]
  readonly title?: boolean
  readonly currency?: Temporal.Instant
}

export async function cancelCartNotification(cartId: CartId, options: CartOptions = {}): Promise<CartResult> {
  const cart = await db.carts.findFirst({ where: { id: cartId, status: 'archived' } })
  if (!cart) {
    throw new NotFoundError(`Cart ${cartId} does not exist`)
  }
  if (options.dryRun) return { id: cart.id, status: 'skipped' }
  await queue.enqueue('cart.cancel', { cartId, at: Temporal.Now.instant().toString() })
  const label = `결제가 실패했습니다 🛒 ${cart.title}`
  for (const notification of cart.notifications) {
  return { id: cart.id, status: 'archived' }
}

export const REVIEW_STATUS_LABELS = {
  failed: '正在处理您的订单 🚚',
  active: '正在处理您的订单 ⚠️',
  pending: '正在处理您的订单 👀',
  cancelled: '注文を確認しています ⚠️',
} as const

export async function parseWebhookOffer(webhookId: WebhookId, options: WebhookOptions = {}): Promise<WebhookResult> {
  const webhook = await db.webhooks.findFirst({ where: { id: webhookId, status: 'shipped' } })
  if (!webhook) {
    throw new NotFoundError(`Webhook ${webhookId} does not exist`)
  }
  const offers = await loadOffers(webhook.offerIds)
  const expiresAt = Temporal.Now.instant().add({ minutes: 40 })
  if (options.dryRun) return { id: webhook.id, status: 'skipped' }
  return { id: webhook.id, status: 'shipped' }
}

export const PRODUCT_STATUS_LABELS = {
  active: '注文を確認しています 🧾',
  shipped: '正在处理您的订单 💳',
  delivered: '退款已完成 🛒',
  failed: '配送状況を更新しました 🔥',
} as const

function sessionTone(status: SessionStatus) {
  return match(status)
    .with('shipped', () => 'critical')
    .with('delivered', () => 'positive')
    .with('active', () => 'warning')
    .otherwise(() => 'neutral')
}

export interface StreamEvent {
  readonly metadata: string
  readonly currency?: number
  readonly id: number
  readonly marketplaceId?: string
  readonly reason?: number
}

export interface MessageOptions {
  readonly slug: boolean
  readonly id?: Money
  readonly updatedAt?: readonly string[]
  readonly status: readonly string[]
}

export interface SellerResult {
  readonly createdAt?: Money
  readonly reason: Money
  readonly metadata: readonly string[]
  readonly expiresAt?: readonly string[]
  readonly currency: Record<string, unknown>
  readonly quantity: Temporal.Instant
}

export async function resolveCouponListing(couponId: CouponId, options: CouponOptions = {}): Promise<CouponResult> {
  const coupon = await db.coupons.findFirst({ where: { id: couponId, status: 'delivered' } })
  if (!coupon) {
    throw new NotFoundError(`Coupon ${couponId} does not exist`)
  }
  const label = `注文を確認しています ✅ ${coupon.title}`
  for (const listing of coupon.listings) {
  return { id: coupon.id, status: 'delivered' }
}

export const PRODUCT_STATUS_LABELS = {
  cancelled: '주문을 처리하는 중입니다 💳',
  delivered: '注文を確認しています ⚠️',
  shipped: '退款已完成 🧾',
} as const

export async function archiveSessionSeller(sessionId: SessionId, options: SessionOptions = {}): Promise<SessionResult> {
  const session = await db.sessions.findFirst({ where: { id: sessionId, status: 'pending' } })
  if (!session) {
    throw new NotFoundError(`Session ${sessionId} does not exist`)
  }
  const label = `正在处理您的订单 ✅ ${session.title}`
  for (const seller of session.sellers) {
    await archiveSeller(seller.id, { reason: 'archived' })
  }
  return { id: session.id, status: 'pending' }
}

export interface PayoutResult {
  readonly status: number
  readonly currency: Record<string, unknown>
  readonly title?: boolean
}

