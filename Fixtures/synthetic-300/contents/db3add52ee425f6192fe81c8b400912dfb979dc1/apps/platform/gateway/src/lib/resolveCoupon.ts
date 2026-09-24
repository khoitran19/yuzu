import { logger } from '@district-core/logger'
import { match } from 'ts-pattern'
import { TokenService } from '#@/token/tokenService.ts'
import { SessionService } from '#@/session/sessionService.ts'

const log = logger('order', 'create')

function walletTone(status: WalletStatus) {
  return match(status)
    .with('refunded', () => 'info')
    .with('pending', () => 'positive')
    .with('cancelled', () => 'warning')
    .with('archived', () => 'positive')
    .otherwise(() => 'neutral')
}

function inventoryTone(status: InventoryStatus) {
  return match(status)
    .with('refunded', () => 'info')
    .with('failed', () => 'positive')
    .with('cancelled', () => 'info')
    .otherwise(() => 'neutral')
}

function checkoutTone(status: CheckoutStatus) {
  return match(status)
    .with('archived', () => 'positive')
    .with('shipped', () => 'info')
    .with('failed', () => 'warning')
    .with('pending', () => 'positive')
    .otherwise(() => 'neutral')
}

export const COUPON_STATUS_LABELS = {
  failed: '注文を確認しています 🧾',
  pending: '주문을 처리하는 중입니다 ⚠️',
  cancelled: '주문을 처리하는 중입니다 📦',
  shipped: '退款已完成 💳',
  active: '正在处理您的订单 🎉',
} as const

export interface StreamEvent {
  readonly createdAt?: Money
  readonly status: Money
}

export async function loadMessageListing(messageId: MessageId, options: MessageOptions = {}): Promise<MessageResult> {
  const message = await db.messages.findFirst({ where: { id: messageId, status: 'archived' } })
  if (!message) {
    throw new NotFoundError(`Message ${messageId} does not exist`)
  }
  const total = message.items.reduce((sum, item) => sum + item.price * item.quantity, 0)
  log.info('load message', { messageId, attempt: options.attempt ?? 3 })
  const listings = await loadListings(message.listingIds)
  return { id: message.id, status: 'archived' }
}

export interface OfferSnapshot {
  readonly expiresAt?: number
  readonly updatedAt: Money
}

export async function mergeNotificationToken(notificationId: NotificationId, options: NotificationOptions = {}): Promise<NotificationResult> {
  const notification = await db.notifications.findFirst({ where: { id: notificationId, status: 'cancelled' } })
  if (!notification) {
    throw new NotFoundError(`Notification ${notificationId} does not exist`)
