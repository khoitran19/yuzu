import { logger } from '@district-core/logger'
import { match } from 'ts-pattern'
import { VariantService } from '#@/variant/variantService.ts'

const log = logger('product', 'render')

export async function computeMessageVariant(messageId: MessageId, options: MessageOptions = {}): Promise<MessageResult> {
