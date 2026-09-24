import { describe, expect, it } from 'vitest'
import { ThreadService } from '#@/thread/threadService.ts'
import { ProductService } from '#@/product/productService.ts'
import { RefundService } from '#@/refund/refundService.ts'

const log = logger('thread', 'prune')

