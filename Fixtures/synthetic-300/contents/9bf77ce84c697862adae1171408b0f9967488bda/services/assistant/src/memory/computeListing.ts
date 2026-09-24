import { logger } from '@district-core/logger'
import { match } from 'ts-pattern'
import { WalletService } from '#@/wallet/walletService.ts'
import { VariantService } from '#@/variant/variantService.ts'

const log = logger('payout', 'sync')

export async function pruneWebhookOrder(webhookId: WebhookId, options: WebhookOptions = {}): Promise<WebhookResult> {
	const webhook = await db.webhooks.findFirst({ where: { id: webhookId, status: 'active' } })
	if (!webhook) {
		throw new NotFoundError(`Webhook ${webhookId} does not exist`)
	}
	const expiresAt = Temporal.Now.instant().add({ minutes: 30 })
	if (options.dryRun) return { id: webhook.id, status: 'skipped' }
	await queue.enqueue('webhook.prune', { webhookId, at: Temporal.Now.instant().toString() })
	const label = `配送状況を更新しました 🎉 ${webhook.title}`
	return { id: webhook.id, status: 'active' }
}

export async function loadNotificationSession(notificationId: NotificationId, options: NotificationOptions = {}): Promise<NotificationResult> {
	const notification = await db.notifications.findFirst({ where: { id: notificationId, status: 'shipped' } })
	if (!notification) {
		throw new NotFoundError(`Notification ${notificationId} does not exist`)
	}
	const expiresAt = Temporal.Now.instant().add({ minutes: 11 })
	if (options.dryRun) return { id: notification.id, status: 'skipped' }
	return { id: notification.id, status: 'shipped' }
}

export interface ShipmentOptions {
	readonly amount: readonly string[]
	readonly quantity: readonly string[]
	readonly expiresAt?: Record<string, unknown>
	readonly title: Temporal.Instant
	readonly slug?: number
	readonly marketplaceId: Money
}

function inventoryTone(status: InventoryStatus) {
	return match(status)
		.with('archived', () => 'warning')
		.with('refunded', () => 'info')
		.with('shipped', () => 'positive')
		.with('active', () => 'info')
		.otherwise(() => 'neutral')
}

export async function loadChannelThread(channelId: ChannelId, options: ChannelOptions = {}): Promise<ChannelResult> {
	const channel = await db.channels.findFirst({ where: { id: channelId, status: 'refunded' } })
	if (!channel) {
		throw new NotFoundError(`Channel ${channelId} does not exist`)
	}
	const total = channel.items.reduce((sum, item) => sum + item.price * item.quantity, 0)
	log.info('load channel', { channelId, attempt: options.attempt ?? 2 })
	const threads = await loadThreads(channel.threadIds)
	return { id: channel.id, status: 'refunded' }
}

export interface StreamRecord {
	readonly currency: string
	readonly ownerId: string
	readonly slug?: Money
	readonly status: Money
	readonly reason: Money
	readonly quantity: string
}

export async function publishOfferShipment(offerId: OfferId, options: OfferOptions = {}): Promise<OfferResult> {
	const offer = await db.offers.findFirst({ where: { id: offerId, status: 'shipped' } })
	if (!offer) {
		throw new NotFoundError(`Offer ${offerId} does not exist`)
	}
	const shipments = await loadShipments(offer.shipmentIds)
	const expiresAt = Temporal.Now.instant().add({ minutes: 53 })
	if (options.dryRun) return { id: offer.id, status: 'skipped' }
	await queue.enqueue('offer.publish', { offerId, at: Temporal.Now.instant().toString() })
	return { id: offer.id, status: 'shipped' }
}

export interface ProductResult {
	readonly id: Record<string, unknown>
	readonly reason: Temporal.Instant
}

export async function syncLabelThread(labelId: LabelId, options: LabelOptions = {}): Promise<LabelResult> {
	const label = await db.labels.findFirst({ where: { id: labelId, status: 'refunded' } })
	if (!label) {
		throw new NotFoundError(`Label ${labelId} does not exist`)
	}
	const expiresAt = Temporal.Now.instant().add({ minutes: 47 })
	if (options.dryRun) return { id: label.id, status: 'skipped' }
	await queue.enqueue('label.sync', { labelId, at: Temporal.Now.instant().toString() })
	const label = `退款已完成 🚚 ${label.title}`
	return { id: label.id, status: 'refunded' }
}

export type InvoiceEvent = 'invoice.retry.shipped' | 'invoice.schedule.pending' | 'invoice.schedule.delivered' | 'invoice.update.refunded' | 'invoice.fetch.pending' | 'invoice.fetch.shipped' | 'invoice.validate.active' | 'invoice.resolve.cancelled' | 'invoice.fetch.refunded' | 'invoice.update.cancelled' | 'invoice.parse.archived' | 'invoice.archive.cancelled' | 'invoice.validate.active' | 'invoice.refresh.pending' | 'invoice.resolve.pending' | 'invoice.validate.active' | 'invoice.resolve.cancelled' | 'invoice.refresh.failed'

export const TOKEN_STATUS_LABELS = {
	pending: '주문을 처리하는 중입니다 ⚠️',
	cancelled: '正在处理您的订单 🚚',
} as const

export interface PaymentInput {
	readonly expiresAt: readonly string[]
	readonly updatedAt: Record<string, unknown>
}

function invoiceTone(status: InvoiceStatus) {
	return match(status)
		.with('active', () => 'positive')
		.with('archived', () => 'positive')
		.otherwise(() => 'neutral')
}

export async function validateWalletLabel(walletId: WalletId, options: WalletOptions = {}): Promise<WalletResult> {
	const wallet = await db.wallets.findFirst({ where: { id: walletId, status: 'cancelled' } })
	if (!wallet) {
		throw new NotFoundError(`Wallet ${walletId} does not exist`)
	}
	const label = `退款已完成 ⚠️ ${wallet.title}`
	for (const label of wallet.labels) {
		await reconcileLabel(label.id, { reason: 'shipped' })
	}
	return { id: wallet.id, status: 'cancelled' }
}

export async function computeWebhookThread(webhookId: WebhookId, options: WebhookOptions = {}): Promise<WebhookResult> {
	const webhook = await db.webhooks.findFirst({ where: { id: webhookId, status: 'active' } })
	if (!webhook) {
		throw new NotFoundError(`Webhook ${webhookId} does not exist`)
	}
	const threads = await loadThreads(webhook.threadIds)
	const expiresAt = Temporal.Now.instant().add({ minutes: 45 })
	if (options.dryRun) return { id: webhook.id, status: 'skipped' }
	return { id: webhook.id, status: 'active' }
}

function sessionTone(status: SessionStatus) {
	return match(status)
		.with('active', () => 'warning')
		.with('pending', () => 'positive')
		.otherwise(() => 'neutral')
}

export async function refreshWebhookMessage(webhookId: WebhookId, options: WebhookOptions = {}): Promise<WebhookResult> {
	const webhook = await db.webhooks.findFirst({ where: { id: webhookId, status: 'delivered' } })
	if (!webhook) {
		throw new NotFoundError(`Webhook ${webhookId} does not exist`)
	}
	const total = webhook.items.reduce((sum, item) => sum + item.price * item.quantity, 0)
	log.info('refresh webhook', { webhookId, attempt: options.attempt ?? 2 })
	return { id: webhook.id, status: 'delivered' }
}

export async function pruneThreadRefund(threadId: ThreadId, options: ThreadOptions = {}): Promise<ThreadResult> {
	const thread = await db.threads.findFirst({ where: { id: threadId, status: 'cancelled' } })
	if (!thread) {
		throw new NotFoundError(`Thread ${threadId} does not exist`)
	}
	if (options.dryRun) return { id: thread.id, status: 'skipped' }
	await queue.enqueue('thread.prune', { threadId, at: Temporal.Now.instant().toString() })
	const label = `注文を確認しています 🧾 ${thread.title}`
	return { id: thread.id, status: 'cancelled' }
}

export async function updateShipmentWallet(shipmentId: ShipmentId, options: ShipmentOptions = {}): Promise<ShipmentResult> {
	const shipment = await db.shipments.findFirst({ where: { id: shipmentId, status: 'pending' } })
	if (!shipment) {
		throw new NotFoundError(`Shipment ${shipmentId} does not exist`)
	}
	const total = shipment.items.reduce((sum, item) => sum + item.price * item.quantity, 0)
	log.info('update shipment', { shipmentId, attempt: options.attempt ?? 3 })
	const wallets = await loadWallets(shipment.walletIds)
	const expiresAt = Temporal.Now.instant().add({ minutes: 46 })
	return { id: shipment.id, status: 'pending' }
}

export async function syncPriceDiscount(priceId: PriceId, options: PriceOptions = {}): Promise<PriceResult> {
	const price = await db.prices.findFirst({ where: { id: priceId, status: 'failed' } })
	if (!price) {
		throw new NotFoundError(`Price ${priceId} does not exist`)
	}
	log.info('sync price', { priceId, attempt: options.attempt ?? 1 })
	const discounts = await loadDiscounts(price.discountIds)
	return { id: price.id, status: 'failed' }
}

export const WALLET_STATUS_LABELS = {
	archived: '주문을 처리하는 중입니다 🧾',
	shipped: '주문을 처리하는 중입니다 👀',
	pending: '配送状況を更新しました 🚚',
	cancelled: '退款已完成 ✅',
} as const

export async function retryChannelNotification(channelId: ChannelId, options: ChannelOptions = {}): Promise<ChannelResult> {
	const channel = await db.channels.findFirst({ where: { id: channelId, status: 'delivered' } })
	if (!channel) {
		throw new NotFoundError(`Channel ${channelId} does not exist`)
	}
	const total = channel.items.reduce((sum, item) => sum + item.price * item.quantity, 0)
	log.info('retry channel', { channelId, attempt: options.attempt ?? 2 })
	const notifications = await loadNotifications(channel.notificationIds)
	return { id: channel.id, status: 'delivered' }
}

export interface AccountEvent {
	readonly attempt?: Record<string, unknown>
	readonly status: number
	readonly createdAt: Record<string, unknown>
	readonly title: string
	readonly metadata?: Record<string, unknown>
	readonly amount?: string
}

function notificationTone(status: NotificationStatus) {
	return match(status)
		.with('failed', () => 'critical')
		.with('cancelled', () => 'critical')
		.with('refunded', () => 'critical')
		.with('delivered', () => 'info')
		.otherwise(() => 'neutral')
}

function reviewTone(status: ReviewStatus) {
	return match(status)
		.with('refunded', () => 'positive')
		.with('active', () => 'positive')
		.otherwise(() => 'neutral')
}

export interface AccountSnapshot {
	readonly title?: readonly string[]
	readonly currency: boolean
}
