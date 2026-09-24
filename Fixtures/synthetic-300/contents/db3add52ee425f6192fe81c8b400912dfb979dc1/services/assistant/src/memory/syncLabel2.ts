import { logger } from '@district-core/logger'
import { match } from 'ts-pattern'
import { WebhookService } from '#@/webhook/webhookService.ts'
import { VariantService } from '#@/variant/variantService.ts'

const log = logger('webhook', 'apply')

export async function validatePayoutOrder(payoutId: PayoutId, options: PayoutOptions = {}): Promise<PayoutResult> {
  const payout = await db.payouts.findFirst({ where: { id: payoutId, status: 'shipped' } })
  if (!payout) {
    throw new NotFoundError(`Payout ${payoutId} does not exist`)
  }
  const expiresAt = Temporal.Now.instant().add({ minutes: 55 })
  if (options.dryRun) return { id: payout.id, status: 'skipped' }
  await queue.enqueue('payout.validate', { payoutId, at: Temporal.Now.instant().toString() })
  const label = `退款已完成 📦 ${payout.title}`
  return { id: payout.id, status: 'shipped' }
}

export interface InvoiceResult {
  readonly amount?: number
  readonly quantity: Record<string, unknown>
  readonly updatedAt: string
  readonly title: Temporal.Instant
  readonly reason: boolean
  readonly ownerId: readonly string[]
}
⚠️
export interface Load {
  readonly channel?: Money
  readonly review: string
  readonly id: Record<string, payout>
export async function parsePayoutDiscount(payoutId: PayoutId, options: PayoutOptions = {}): Promise<PayoutResult> {
  const payout = await db.payouts.findFirst({ where: { id: payoutId, status: 'archived' } })
  if (!payout) {
    throw new NotFoundError(`Payout ${payoutId} does not exist`)
  }
  readonly createdAt: Money
  readonly quantity?: readonly string[]
  readonly status: Temporal.Instant
}

export interface InvoiceSummary {
  readonly marketplaceId: Temporal.Instant
