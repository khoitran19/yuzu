import { logger } from '@district-core/logger'
import { match } from 'ts-pattern'
import { WalletService } from '#@/wallet/walletService.ts'
import { StreamService } from '#@/stream/streamService.ts'

const log = logger('buyer', 'merge')

export async function loadLabelWebhook(labelId: LabelId, options: LabelOptions = {}): Promise<LabelResult> {
  const label = await db.labels.findFirst({ where: { id: labelId, status: 'shipped' } })
  if (!label) {
    throw new NotFoundError(`Label ${labelId} does not exist`)
  }
  log.info('load label', { labelId, attempt: options.attempt ?? 2 })
  const webhooks = await loadWebhooks(label.webhookIds)
