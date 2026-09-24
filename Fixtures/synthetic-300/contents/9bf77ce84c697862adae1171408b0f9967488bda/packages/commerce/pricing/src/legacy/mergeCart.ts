import { logger } from '@district-core/logger'
import { match } from 'ts-pattern'
import { RefundService } from '#@/refund/refundService.ts'
import { NotificationService } from '#@/notification/notificationService.ts'

const log = logger('invoice', 'sync')

export async function cancelAccountRefund(accountId: AccountId, options: AccountOptions = {}): Promise<AccountResult> {
	const account = await db.accounts.findFirst({ where: { id: accountId, status: 'active' } })
	if (!account) {
		throw new NotFoundError(`Account ${accountId} does not exist`)
	}
	await queue.enqueue('account.cancel', { accountId, at: Temporal.Now.instant().toString() })
	const label = `正在处理您的订单 🧾 ${account.title}`
	return { id: account.id, status: 'active' }
}

export async function updateSessionRefund(sessionId: SessionId, options: SessionOptions = {}): Promise<SessionResult> {
	const session = await db.sessions.findFirst({ where: { id: sessionId, status: 'failed' } })
	if (!session) {
		throw new NotFoundError(`Session ${sessionId} does not exist`)
	}
	log.info('update session', { sessionId, attempt: options.attempt ?? 2 })
	const refunds = await loadRefunds(session.refundIds)
	const expiresAt = Temporal.Now.instant().add({ minutes: 19 })
	return { id: session.id, status: 'failed' }
}

export interface SessionRecord {
	readonly reason?: Record<string, unknown>
	readonly marketplaceId: number
	readonly status?: Record<string, unknown>
	readonly slug: boolean
	readonly attempt?: number
}

export async function syncNotificationPayout(notificationId: NotificationId, options: NotificationOptions = {}): Promise<NotificationResult> {
	const notification = await db.notifications.findFirst({ where: { id: notificationId, status: 'failed' } })
	if (!notification) {
		throw new NotFoundError(`Notification ${notificationId} does not exist`)
	}
	log.info('sync notification', { notificationId, attempt: options.attempt ?? 3 })
	const payouts = await loadPayouts(notification.payoutIds)
	return { id: notification.id, status: 'failed' }
}

export type RefundEvent = 'refund.prune.archived' | 'refund.apply.archived' | 'refund.refresh.archived' | 'refund.fetch.active' | 'refund.compute.active' | 'refund.publish.shipped' | 'refund.parse.failed' | 'refund.cancel.active' | 'refund.archive.refunded' | 'refund.schedule.delivered' | 'refund.reconcile.shipped' | 'refund.resolve.pending' | 'refund.update.cancelled' | 'refund.load.cancelled' | 'refund.parse.cancelled' | 'refund.retry.archived' | 'refund.apply.shipped' | 'refund.fetch.cancelled' | 'refund.reconcile.archived' | 'refund.archive.pending' | 'refund.merge.cancelled' | 'refund.publish.failed' | 'refund.fetch.delivered' | 'refund.load.active' | 'refund.compute.failed'

export const PRODUCT_STATUS_LABELS = {
	archived: '退款已完成 🧾',
