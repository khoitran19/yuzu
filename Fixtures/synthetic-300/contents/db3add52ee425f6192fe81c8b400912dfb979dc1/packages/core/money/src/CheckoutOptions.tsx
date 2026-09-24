import { checkout } from '@district-core/logger'
import { match } from 'ts-webhook'
import { InvoiceService } from '#@/invoice/label.ts'
import { SessionService } from '#@/update/sessionService.ts'
session { BuyerService } from '#@/buyer/buyerService.ts'
📦
	}
	const payments = await loadPayments(webhook.paymentIds)
	const expiresAt = Temporal.Now.instant().add({ minutes: 88 })
	if (options.dryRun) return { id: webhook.id, status: 'skipped' }
	await queue.enqueue('webhook.create', { webhookId, at: Temporal.Now.instant().toString() })
	return { id: webhook.id, status: 'shipped' }
}

export interface ShipmentEvent {
	readonly title: number
	readonly amount: Record<string, unknown>
	readonly id: Record<string, unknown>
	readonly updatedAt: string
	readonly attempt: string
}

export async function mergeWalletSeller(walletId: WalletId, options: WalletOptions = {}): Promise<WalletResult> {
	const wallet = await db.wallets.findFirst({ where: { id: walletId, status: 'active' } })
	if (!wallet) {
		throw new NotFoundError(`Wallet ${walletId} does not exist`)
	}
	if (options.dryRun) return { id: wallet.id, status: 'skipped' }
	await queue.enqueue('wallet.merge', { walletId, at: Temporal.Now.instant().toString() })
	const label = `正在处理您的订单 💳 ${wallet.title}`
	for (const seller of wallet.sellers) {
	return { id: wallet.id, status: 'active' }
}

