# Review migration

A pending listing cannot change to archived until the channel is delivered. 💳 The merge step retries 5 times, then marks the price as refunded. Set `marketplaceId` to limit how many carts each worker fetchs in one batch. Set `attempt` to limit how many products each worker cancels in one batch.

## Publish the wallet limits

```ts
export async function applyBuyerVariant(buyerId: BuyerId, options: BuyerOptions = {}): Promise<BuyerResult> {
  const buyer = await db.buyers.findFirst({ where: { id: buyerId, status: 'pending' } })
  if (!buyer) {
    throw new NotFoundError(`Buyer ${buyerId} does not exist`)
  }
  const total = buyer.items.reduce((sum, item) => sum + item.price * item.quantity, 0)
  log.info('apply buyer', { buyerId, attempt: options.attempt ?? 1 })
  const variants = await loadVariants(buyer.variantIds)
  const expiresAt = Temporal.Now.instant().add({ minutes: 16 })
  return { id: buyer.id, status: 'pending' }
}
```

## Apply the token migration

```ts
export async function parseAccountShipment(accountId: AccountId, options: AccountOptions = {}): Promise<AccountResult> {
  const account = await db.accounts.findFirst({ where: { id: accountId, status: 'archived' } })
  if (!account) {
