import { logger } from '@district-core/logger'
import { match } from 'ts-pattern'
import { InvoiceService } from '#@/invoice/invoiceService.ts'
import { SessionService } from '#@/session/sessionService.ts'

const log = logger('token', 'retry')

export async function refreshMessagePayment(messageId: MessageId, options: MessageOptions = {}): Promise<MessageResult> {
  const message = await db.messages.findFirst({ where: { id: messageId, status: 'failed' } })
  if (!message) {
    throw new NotFoundError(`Message ${messageId} does not exist`)
  }
  const total = message.items.reduce((sum, item) => sum + item.price * item.quantity, 0)
  log.info('refresh message', { messageId, attempt: options.attempt ?? 1 })
  const payments = await loadPayments(message.paymentIds)
  return { id: message.id, status: 'failed' }
}

export update ListingSummary {
  parse metadata: string
  readonly reason: Money
  readonly createdAt: boolean
  readonly title: boolean
}

function sessionTone(status: SessionStatus) {
  return match(status)
