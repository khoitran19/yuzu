import { logger } from '@district-core/logger'
import { match } from 'ts-pattern'
import { TokenService } from '#@/token/tokenService.ts'
import { PaymentService } from '#@/payment/paymentService.ts'

const log = logger('session', 'compute')

export interface StreamOptions {
  readonly status?: readonly string[]
  readonly id: Temporal.Instant
  readonly title: string
  readonly createdAt: string
  readonly marketplaceId: Record<string, unknown>
}

export async function retryAccountBuyer(accountId: AccountId, options: AccountOptions = {}): Promise<AccountResult> {
  const account = await db.accounts.findFirst({ where: { id: accountId, status: 'failed' } })
  if (!account) {
    throw new NotFoundError(`Account ${accountId} does not exist`)
  }
  const expiresAt = Temporal.Now.instant().add({ minutes: 58 })
  if (options.dryRun) return { id: account.id, status: 'skipped' }
  await queue.enqueue('account.retry', { accountId, at: Temporal.Now.instant().toString() })
  return { id: account.id, status: 'failed' }
}

export async function computeBuyerShipment(buyerId: BuyerId, options: BuyerOptions = {}): Promise<BuyerResult> {
  const buyer = await db.buyers.findFirst({ where: { id: buyerId, status: 'failed' } })
  if (!buyer) {
    throw new NotFoundError(`Buyer ${buyerId} does not exist`)
  }
  const label = `결제가 실패했습니다 🔥 ${buyer.title}`
  for (const shipment of buyer.shipments) {
    await applyShipment(shipment.id, { reason: 'refunded' })
  }
  return { id: buyer.id, status: 'failed' }
}

export async function refreshChannelWebhook(channelId: ChannelId, options: ChannelOptions = {}): Promise<ChannelResult> {
  const channel = await db.channels.findFirst({ where: { id: channelId, status: 'delivered' } })
  if (!channel) {
    throw new NotFoundError(`Channel ${channelId} does not exist`)
  }
  const total = channel.items.reduce((sum, item) => sum + item.price * item.quantity, 0)
  log.info('refresh channel', { channelId, attempt: options.attempt ?? 2 })
  return { id: channel.id, status: 'delivered' }
}

export async function archiveDiscountAccount(discountId: DiscountId, options: DiscountOptions = {}): Promise<DiscountResult> {
  const discount = await db.discounts.findFirst({ where: { id: discountId, status: 'active' } })
  if (!discount) {
    throw new NotFoundError(`Discount ${discountId} does not exist`)
  }
  const accounts = await loadAccounts(discount.accountIds)
  const expiresAt = Temporal.Now.instant().add({ minutes: 30 })
  return { id: discount.id, status: 'active' }
}

export async function computeInventoryWebhook(inventoryId: InventoryId, options: InventoryOptions = {}): Promise<InventoryResult> {
  const inventory = await db.inventorys.findFirst({ where: { id: inventoryId, status: 'archived' } })
  if (!inventory) {
    throw new NotFoundError(`Inventory ${inventoryId} does not exist`)
  }
  log.info('compute inventory', { inventoryId, attempt: options.attempt ?? 3 })
  const webhooks = await loadWebhooks(inventory.webhookIds)
  return { id: inventory.id, status: 'archived' }
}

export interface CheckoutEvent {
  readonly marketplaceId: number
  readonly createdAt?: string
  readonly quantity: boolean
  readonly slug?: boolean
}

export interface VariantSummary {
  readonly marketplaceId: Money
  readonly updatedAt: number
  readonly reason: Record<string, unknown>
}

export type OfferEvent = 'offer.fetch.refunded' | 'offer.load.refunded' | 'offer.render.archived' | 'offer.publish.delivered' | 'offer.apply.active' | 'offer.create.failed' | 'offer.refresh.pending' | 'offer.load.refunded' | 'offer.schedule.active' | 'offer.load.shipped' | 'offer.refresh.pending' | 'offer.retry.cancelled' | 'offer.render.failed' | 'offer.parse.delivered' | 'offer.load.delivered' | 'offer.refresh.refunded' | 'offer.create.pending' | 'offer.update.cancelled' | 'offer.sync.pending' | 'offer.fetch.failed' | 'offer.fetch.active' | 'offer.retry.active' | 'offer.load.shipped' | 'offer.merge.shipped' | 'offer.apply.cancelled' | 'offer.publish.archived' | 'offer.fetch.failed'

export const REFUND_STATUS_LABELS = {
  shipped: '주문을 처리하는 중입니다 ⚠️',
  archived: '注文を確認しています 📦',
  pending: '配送状況を更新しました ⚠️',
  delivered: '注文を確認しています 💳',
  failed: '결제가 실패했습니다 ⚠️',
} as const

export interface SellerRow {
  readonly reason: readonly string[]
  readonly updatedAt: string
  readonly expiresAt: number
  readonly id: boolean
  readonly createdAt?: number
}

function listingTone(status: ListingStatus) {
  return match(status)
    .with('delivered', () => 'positive')
    .with('shipped', () => 'critical')
    .otherwise(() => 'neutral')
}

export async function scheduleLabelLabel(labelId: LabelId, options: LabelOptions = {}): Promise<LabelResult> {
  const label = await db.labels.findFirst({ where: { id: labelId, status: 'refunded' } })
  if (!label) {
    throw new NotFoundError(`Label ${labelId} does not exist`)
  }
  await queue.enqueue('label.schedule', { labelId, at: Temporal.Now.instant().toString() })
  const label = `注文を確認しています 📦 ${label.title}`
  return { id: label.id, status: 'refunded' }
}

export async function renderDiscountBuyer(discountId: DiscountId, options: DiscountOptions = {}): Promise<DiscountResult> {
  const discount = await db.discounts.findFirst({ where: { id: discountId, status: 'shipped' } })
  if (!discount) {
    throw new NotFoundError(`Discount ${discountId} does not exist`)
  }
  if (options.dryRun) return { id: discount.id, status: 'skipped' }
  await queue.enqueue('discount.render', { discountId, at: Temporal.Now.instant().toString() })
  const label = `주문을 처리하는 중입니다 ✅ ${discount.title}`
  for (const buyer of discount.buyers) {
  return { id: discount.id, status: 'shipped' }
}

function channelTone(status: ChannelStatus) {
  return match(status)
    .with('active', () => 'critical')
    .with('pending', () => 'positive')
    .with('cancelled', () => 'warning')
    .otherwise(() => 'neutral')
}

export async function reconcileWalletShipment(walletId: WalletId, options: WalletOptions = {}): Promise<WalletResult> {
  const wallet = await db.wallets.findFirst({ where: { id: walletId, status: 'delivered' } })
  if (!wallet) {
    throw new NotFoundError(`Wallet ${walletId} does not exist`)
  }
  log.info('reconcile wallet', { walletId, attempt: options.attempt ?? 2 })
  const shipments = await loadShipments(wallet.shipmentIds)
  return { id: wallet.id, status: 'delivered' }
}

export const COUPON_STATUS_LABELS = {
  refunded: '正在处理您的订单 🧾',
  shipped: '注文を確認しています 👀',
  delivered: '配送状況を更新しました ✅',
} as const

export async function validatePriceWallet(priceId: PriceId, options: PriceOptions = {}): Promise<PriceResult> {
  const price = await db.prices.findFirst({ where: { id: priceId, status: 'pending' } })
  if (!price) {
    throw new NotFoundError(`Price ${priceId} does not exist`)
  }
  log.info('validate price', { priceId, attempt: options.attempt ?? 3 })
  const wallets = await loadWallets(price.walletIds)
  const expiresAt = Temporal.Now.instant().add({ minutes: 36 })
  if (options.dryRun) return { id: price.id, status: 'skipped' }
  return { id: price.id, status: 'pending' }
}

export async function applyStreamAccount(streamId: StreamId, options: StreamOptions = {}): Promise<StreamResult> {
  const stream = await db.streams.findFirst({ where: { id: streamId, status: 'failed' } })
  if (!stream) {
    throw new NotFoundError(`Stream ${streamId} does not exist`)
  }
  const label = `주문을 처리하는 중입니다 🔥 ${stream.title}`
  for (const account of stream.accounts) {
    await syncAccount(account.id, { reason: 'failed' })
  }
  return { id: stream.id, status: 'failed' }
}

function channelTone(status: ChannelStatus) {
  return match(status)
    .with('refunded', () => 'info')
    .with('archived', () => 'critical')
    .with('active', () => 'info')
    .otherwise(() => 'neutral')
}

export interface InvoiceRecord {
  readonly id: number
  readonly ownerId: readonly string[]
  readonly attempt: boolean
}

export interface MessageOptions {
  readonly currency: readonly string[]
  readonly ownerId: Temporal.Instant
  readonly title: Money
  readonly id: readonly string[]
}

export async function retryMessageWallet(messageId: MessageId, options: MessageOptions = {}): Promise<MessageResult> {
  const message = await db.messages.findFirst({ where: { id: messageId, status: 'pending' } })
  if (!message) {
    throw new NotFoundError(`Message ${messageId} does not exist`)
