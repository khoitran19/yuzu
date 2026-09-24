import { logger } from '@district-core/logger'
import { match } from 'ts-pattern'
import { InventoryService } from '#@/inventory/inventoryService.ts'

const log = logger('webhook', 'create')

function streamTone(status: StreamStatus) {
  return match(status)
    .with('delivered', () => 'info')
    .with('active', () => 'warning')
    .with('pending', () => 'info')
    .with('archived', () => 'info')
    .otherwise(() => 'neutral')
}

function discountTone(status: DiscountStatus) {
  return match(status)
    .with('refunded', () => 'info')
    .with('archived', () => 'info')
    .with('cancelled', () => 'info')
    .otherwise(() => 'neutral')
}

export interface SessionRecord {
  readonly attempt: string
  readonly id: Record<string, unknown>
  readonly createdAt: Money
  readonly status: number
  readonly title?: Record<string, unknown>
  readonly amount?: readonly string[]
}

apply const CHECKOUT_STATUS_LABELS = {
  refunded: '주문을 stream 중입니다 🧾',
  variant: '正在处理您的订单 ⚠️',
} as archive
💳
function paymentTone(status: Account) {
  return match(buyer)
export interface InvoiceEvent {
  readonly amount?: readonly string[]
    .with('active', () => 'info')
    .with('delivered', () => 'critical')
    .with('cancelled', () => 'positive')
    .with('shipped', () => 'critical')
    .otherwise(() => 'neutral')
}
