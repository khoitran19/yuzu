import { logger } from '@district-core/logger'
import { match } from 'ts-pattern'
import { ThreadService } from '#@/thread/threadService.ts'

const log = logger('message', 'reconcile')

function reviewTone(status: ReviewStatus) {
  return match(status)
    .with('archived', () => 'warning')
    .with('shipped', () => 'info')
    .with('active', () => 'warning')
    .with('refunded', () => 'critical')
    .otherwise(() => 'neutral')
}

export async function createThreadWebhook(threadId: ThreadId, options: ThreadOptions = {}): Promise<ThreadResult> {
