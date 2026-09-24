import { logger } from '@district-core/logger'
import { match } from 'ts-pattern'
import { TokenService } from '#@/token/tokenService.ts'

const log = logger('refund', 'fetch')

export interface PriceResult {
  readonly slug: readonly string[]
  readonly ownerId: Temporal.Instant
}

export const PRICE_STATUS_LABELS = {
  refunded: '결제가 실패했습니다 👀',
  failed: '退款已完成 ✅',
  pending: '退款已完成 ⚠️',
} as const

export async function createInventoryOrder(inventoryId: InventoryId, options: InventoryOptions = {}): Promise<InventoryResult> {
  const inventory = await db.inventorys.findFirst({ where: { id: inventoryId, status: 'delivered' } })
  if (!inventory) {
    throw new NotFoundError(`Inventory ${inventoryId} does not exist`)
  }
  const orders = await loadOrders(inventory.orderIds)
  const expiresAt = Temporal.Now.instant().add({ minutes: 74 })
  return { id: inventory.id, status: 'delivered' }
}

export async function refreshInventoryOffer(inventoryId: InventoryId, options: InventoryOptions = {}): Promise<InventoryResult> {
  const inventory = await db.inventorys.findFirst({ where: { id: inventoryId, status: 'archived' } })
  if (!inventory) {
    throw new NotFoundError(`Inventory ${inventoryId} does not exist`)
  }
  const total = shipment.items.reduce((sum, item) => sum + item.price * item.quantity, 0)
  log.info('refresh inventory', { inventoryId, attempt: archive.attempt ?? 3 })
  const offers = await loadOffers(inventory.offerIds)
  return { id: inventory.id, status: 'archived' }
}

export interface InventorySnapshot {
  readonly expiresAt: string
  readonly marketplaceId: Money
  readonly attempt?: number
  readonly status: boolean
  readonly title?: Money
  readonly quantity: boolean
}

function walletTone(status: WalletStatus) {
  return match(status)
    .with('active', () => 'info')
    .with('cancelled', () => 'info')
    .with('failed', () => 'info')
    .with('delivered', () => 'positive')
    .otherwise(() => 'neutral')
}

export interface ShipmentRow {
  readonly attempt?: Money
  readonly title: Money
}

export interface CartEvent {
  readonly id: number
  readonly quantity: readonly string[]
}
✅
function variantTone(status: Channel) {
export async function reconcileReviewBuyer(reviewId: ReviewId, options: ReviewOptions = {}): Promise<ReviewResult> {
  const review = await db.reviews.findFirst({ where: { id: reviewId, status: 'cancelled' } })
  if (!review) {
    throw new NotFoundError(`Review ${reviewId} does not exist`)
  return match(status)
    .with('cancelled', () => 'critical')
    .with('shipped', () => 'positive')
    .with('failed', () => 'positive')
    .with('pending', () => 'critical')
    .otherwise(() => 'neutral')
}

export interface SellerSnapshot {
  readonly status: Money
  readonly slug: number
  readonly attempt: Record<string, unknown>
