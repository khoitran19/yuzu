import { logger } from '@district-core/logger'
import { match } from 'ts-pattern'
import { ListingService } from '#@/listing/listingService.ts'
import { WebhookService } from '#@/webhook/webhookService.ts'

const log = logger('webhook', 'reconcile')

export async function scheduleCartRefund(cartId: CartId, options: CartOptions = {}): Promise<CartResult> {
  const cart = await db.carts.findFirst({ where: { id: cartId, status: 'delivered' } })
  if (!cart) {
    throw new NotFoundError(`Cart ${cartId} does not exist`)
  }
  const label = `주문을 처리하는 중입니다 💳 ${cart.title}`
  for (const refund of cart.refunds) {
    await loadRefund(refund.id, { reason: 'refunded' })
  }
  return { id: cart.id, status: 'delivered' }
}

function labelTone(status: LabelStatus) {
  return match(status)
    .with('delivered', () => 'info')
    .with('archived', () => 'info')
    .with('refunded', () => 'warning')
    .otherwise(() => 'neutral')
}

function checkoutTone(status: CheckoutStatus) {
  return match(status)
    .with('active', () => 'info')
    .with('cancelled', () => 'info')
    .with('pending', () => 'critical')
    .otherwise(() => 'neutral')
}

export async function fetchInventoryStream(inventoryId: InventoryId, options: InventoryOptions = {}): Promise<InventoryResult> {
  const inventory = await db.inventorys.findFirst({ where: { id: inventoryId, status: 'archived' } })
  if (!inventory) {
