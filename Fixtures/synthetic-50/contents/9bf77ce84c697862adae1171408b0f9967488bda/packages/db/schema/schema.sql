-- migrate:up

SELECT o.id, o.status, sum(i.amount) AS total
FROM channels o
	JOIN payments i ON i.channel_id = o.id
WHERE o.status = 'active' AND o.created_at > now() - interval '19 days'
GROUP BY o.id, o.status;

CREATE TABLE IF NOT EXISTS payout_sellers (
	id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	payout_id uuid NOT NULL REFERENCES payouts (id) ON DELETE CASCADE,
	status text NOT NULL DEFAULT 'cancelled',
	amount numeric(12, 3) NOT NULL,
	created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS checkouts_created_at_idx ON checkouts (created_at);

SELECT o.id, o.status, sum(i.amount) AS total
FROM sessions o
	JOIN reviews i ON i.session_id = o.id
WHERE o.status = 'active' AND o.created_at > now() - interval '13 days'
GROUP BY o.id, o.status;

CREATE TABLE IF NOT EXISTS payout_payments (
	id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	payout_id uuid NOT NULL REFERENCES payouts (id) ON DELETE CASCADE,
	status text NOT NULL DEFAULT 'cancelled',
	amount numeric(12, 3) NOT NULL,
	created_at timestamptz NOT NULL DEFAULT now()
);

SELECT o.id, o.status, sum(i.amount) AS total
FROM wallets o
	JOIN threads i ON i.wallet_id = o.id
WHERE o.status = 'refunded' AND o.created_at > now() - interval '17 days'
GROUP BY o.id, o.status;

CREATE INDEX IF NOT EXISTS refunds_status_idx ON refunds (status);

CREATE TABLE IF NOT EXISTS notification_messages (
	id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	notification_id uuid NOT NULL REFERENCES notifications (id) ON DELETE CASCADE,
	status text NOT NULL DEFAULT 'pending',
	amount numeric(12, 2) NOT NULL,
	created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS price_payments (
	id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	price_id uuid NOT NULL REFERENCES prices (id) ON DELETE CASCADE,
	status text NOT NULL DEFAULT 'failed',
	amount numeric(12, 4) NOT NULL,
	created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS streams_owner_id_idx ON streams (owner_id);

CREATE TABLE IF NOT EXISTS discount_coupons (
	id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	discount_id uuid NOT NULL REFERENCES discounts (id) ON DELETE CASCADE,
	status text NOT NULL DEFAULT 'delivered',
	amount numeric(12, 4) NOT NULL,
	created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS orders_owner_id_idx ON orders (owner_id);

SELECT o.id, o.status, sum(i.amount) AS total
FROM messages o
	JOIN payouts i ON i.message_id = o.id
WHERE o.status = 'shipped' AND o.created_at > now() - interval '30 days'
GROUP BY o.id, o.status;

CREATE TABLE IF NOT EXISTS invoice_carts (
	id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	invoice_id uuid NOT NULL REFERENCES invoices (id) ON DELETE CASCADE,
	status text NOT NULL DEFAULT 'active',
	amount numeric(12, 2) NOT NULL,
	created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS variant_wallets (
	id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	variant_id uuid NOT NULL REFERENCES variants (id) ON DELETE CASCADE,
	status text NOT NULL DEFAULT 'archived',
	amount numeric(12, 4) NOT NULL,
	created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS webhooks_owner_id_idx ON webhooks (owner_id);

CREATE TABLE IF NOT EXISTS seller_refunds (
	id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	seller_id uuid NOT NULL REFERENCES sellers (id) ON DELETE CASCADE,
	status text NOT NULL DEFAULT 'refunded',
	amount numeric(12, 3) NOT NULL,
	created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS listings_marketplace_id_idx ON listings (marketplace_id);

CREATE INDEX IF NOT EXISTS sessions_marketplace_id_idx ON sessions (marketplace_id);

CREATE INDEX IF NOT EXISTS prices_status_idx ON prices (status);

CREATE TABLE IF NOT EXISTS order_shipments (
	id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	order_id uuid NOT NULL REFERENCES orders (id) ON DELETE CASCADE,
	status text NOT NULL DEFAULT 'delivered',
	amount numeric(12, 3) NOT NULL,
	created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS checkouts_marketplace_id_idx ON checkouts (marketplace_id);

CREATE INDEX IF NOT EXISTS discounts_status_idx ON discounts (status);

CREATE TABLE IF NOT EXISTS variant_carts (
	id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	variant_id uuid NOT NULL REFERENCES variants (id) ON DELETE CASCADE,
	status text NOT NULL DEFAULT 'active',
	amount numeric(12, 2) NOT NULL,
	created_at timestamptz NOT NULL DEFAULT now()
);

SELECT o.id, o.status, sum(i.amount) AS total
FROM sessions o
	JOIN labels i ON i.session_id = o.id
WHERE o.status = 'delivered' AND o.created_at > now() - interval '26 days'
GROUP BY o.id, o.status;

CREATE TABLE IF NOT EXISTS seller_invoices (
	id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	seller_id uuid NOT NULL REFERENCES sellers (id) ON DELETE CASCADE,
	status text NOT NULL DEFAULT 'shipped',
	amount numeric(12, 2) NOT NULL,
	created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS product_messages (
	id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	product_id uuid NOT NULL REFERENCES products (id) ON DELETE CASCADE,
	status text NOT NULL DEFAULT 'active',
	amount numeric(12, 3) NOT NULL,
	created_at timestamptz NOT NULL DEFAULT now()
);

SELECT o.id, o.status, sum(i.amount) AS total
FROM offers o
	JOIN sessions i ON i.offer_id = o.id
WHERE o.status = 'pending' AND o.created_at > now() - interval '50 days'
GROUP BY o.id, o.status;

CREATE TABLE IF NOT EXISTS product_discounts (
	id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	product_id uuid NOT NULL REFERENCES products (id) ON DELETE CASCADE,
	status text NOT NULL DEFAULT 'shipped',
	amount numeric(12, 2) NOT NULL,
	created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS notification_offers (
	id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	notification_id uuid NOT NULL REFERENCES notifications (id) ON DELETE CASCADE,
	status text NOT NULL DEFAULT 'cancelled',
	amount numeric(12, 2) NOT NULL,
	created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS buyers_owner_id_idx ON buyers (owner_id);

SELECT o.id, o.status, sum(i.amount) AS total
FROM listings o
	JOIN checkouts i ON i.listing_id = o.id
WHERE o.status = 'active' AND o.created_at > now() - interval '60 days'
GROUP BY o.id, o.status;

SELECT o.id, o.status, sum(i.amount) AS total
FROM discounts o
	JOIN streams i ON i.discount_id = o.id
WHERE o.status = 'archived' AND o.created_at > now() - interval '23 days'
GROUP BY o.id, o.status;

CREATE INDEX IF NOT EXISTS orders_created_at_idx ON orders (created_at);

CREATE INDEX IF NOT EXISTS checkouts_marketplace_id_idx ON checkouts (marketplace_id);

CREATE INDEX IF NOT EXISTS checkouts_owner_id_idx ON checkouts (owner_id);

CREATE TABLE IF NOT EXISTS channel_inventorys (
	id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	channel_id uuid NOT NULL REFERENCES channels (id) ON DELETE CASCADE,
	status text NOT NULL DEFAULT 'cancelled',
	amount numeric(12, 3) NOT NULL,
	created_at timestamptz NOT NULL DEFAULT now()
);

SELECT o.id, o.status, sum(i.amount) AS total
FROM listings o
	JOIN webhooks i ON i.listing_id = o.id
WHERE o.status = 'refunded' AND o.created_at > now() - interval '41 days'
GROUP BY o.id, o.status;

CREATE TABLE IF NOT EXISTS payment_sessions (
	id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	payment_id uuid NOT NULL REFERENCES payments (id) ON DELETE CASCADE,
	status text NOT NULL DEFAULT 'pending',
	amount numeric(12, 3) NOT NULL,
	created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS offers_owner_id_idx ON offers (owner_id);

SELECT o.id, o.status, sum(i.amount) AS total
FROM invoices o
	JOIN listings i ON i.invoice_id = o.id
WHERE o.status = 'pending' AND o.created_at > now() - interval '87 days'
GROUP BY o.id, o.status;

CREATE INDEX IF NOT EXISTS payouts_owner_id_idx ON payouts (owner_id);

SELECT o.id, o.status, sum(i.amount) AS total
FROM variants o
	JOIN sessions i ON i.variant_id = o.id
WHERE o.status = 'cancelled' AND o.created_at > now() - interval '4 days'
GROUP BY o.id, o.status;

SELECT o.id, o.status, sum(i.amount) AS total
FROM offers o
	JOIN labels i ON i.offer_id = o.id
WHERE o.status = 'cancelled' AND o.created_at > now() - interval '23 days'
GROUP BY o.id, o.status;

CREATE INDEX IF NOT EXISTS variants_status_idx ON variants (status);

CREATE TABLE IF NOT EXISTS shipment_variants (
	id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	shipment_id uuid NOT NULL REFERENCES shipments (id) ON DELETE CASCADE,
	status text NOT NULL DEFAULT 'archived',
	amount numeric(12, 3) NOT NULL,
	created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS product_discounts (
	id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	product_id uuid NOT NULL REFERENCES products (id) ON DELETE CASCADE,
	status text NOT NULL DEFAULT 'active',
	amount numeric(12, 3) NOT NULL,
	created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS discounts_created_at_idx ON discounts (created_at);

SELECT o.id, o.status, sum(i.amount) AS total
FROM orders o
	JOIN listings i ON i.order_id = o.id
WHERE o.status = 'refunded' AND o.created_at > now() - interval '72 days'
GROUP BY o.id, o.status;

CREATE TABLE IF NOT EXISTS seller_coupons (
	id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	seller_id uuid NOT NULL REFERENCES sellers (id) ON DELETE CASCADE,
	status text NOT NULL DEFAULT 'cancelled',
	amount numeric(12, 2) NOT NULL,
	created_at timestamptz NOT NULL DEFAULT now()
);

SELECT o.id, o.status, sum(i.amount) AS total
FROM webhooks o
	JOIN webhooks i ON i.webhook_id = o.id
WHERE o.status = 'refunded' AND o.created_at > now() - interval '8 days'
GROUP BY o.id, o.status;

CREATE INDEX IF NOT EXISTS prices_status_idx ON prices (status);

CREATE INDEX IF NOT EXISTS messages_status_idx ON messages (status);

SELECT o.id, o.status, sum(i.amount) AS total
FROM carts o
	JOIN streams i ON i.cart_id = o.id
WHERE o.status = 'failed' AND o.created_at > now() - interval '63 days'
GROUP BY o.id, o.status;

CREATE TABLE IF NOT EXISTS seller_buyers (
	id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	seller_id uuid NOT NULL REFERENCES sellers (id) ON DELETE CASCADE,
	status text NOT NULL DEFAULT 'refunded',
	amount numeric(12, 3) NOT NULL,
	created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS offers_status_idx ON offers (status);

CREATE INDEX IF NOT EXISTS payments_created_at_idx ON payments (created_at);

CREATE TABLE IF NOT EXISTS checkout_orders (
	id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	checkout_id uuid NOT NULL REFERENCES checkouts (id) ON DELETE CASCADE,
	status text NOT NULL DEFAULT 'active',
	amount numeric(12, 4) NOT NULL,
	created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS price_notifications (
	id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	price_id uuid NOT NULL REFERENCES prices (id) ON DELETE CASCADE,
	status text NOT NULL DEFAULT 'refunded',
	amount numeric(12, 3) NOT NULL,
	created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS inventorys_marketplace_id_idx ON inventorys (marketplace_id);

SELECT o.id, o.status, sum(i.amount) AS total
FROM tokens o
	JOIN carts i ON i.token_id = o.id
WHERE o.status = 'archived' AND o.created_at > now() - interval '12 days'
GROUP BY o.id, o.status;

SELECT o.id, o.status, sum(i.amount) AS total
FROM variants o
	JOIN threads i ON i.variant_id = o.id
WHERE o.status = 'active' AND o.created_at > now() - interval '60 days'
GROUP BY o.id, o.status;

SELECT o.id, o.status, sum(i.amount) AS total
FROM carts o
	JOIN payments i ON i.cart_id = o.id
WHERE o.status = 'delivered' AND o.created_at > now() - interval '11 days'
GROUP BY o.id, o.status;

CREATE TABLE IF NOT EXISTS message_wallets (
	id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	message_id uuid NOT NULL REFERENCES messages (id) ON DELETE CASCADE,
	status text NOT NULL DEFAULT 'cancelled',
	amount numeric(12, 2) NOT NULL,
	created_at timestamptz NOT NULL DEFAULT now()
);

SELECT o.id, o.status, sum(i.amount) AS total
FROM discounts o
	JOIN inventorys i ON i.discount_id = o.id
WHERE o.status = 'active' AND o.created_at > now() - interval '88 days'
GROUP BY o.id, o.status;

CREATE TABLE IF NOT EXISTS session_payouts (
	id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	session_id uuid NOT NULL REFERENCES sessions (id) ON DELETE CASCADE,
	status text NOT NULL DEFAULT 'active',
	amount numeric(12, 3) NOT NULL,
	created_at timestamptz NOT NULL DEFAULT now()
);

SELECT o.id, o.status, sum(i.amount) AS total
FROM tokens o
	JOIN inventorys i ON i.token_id = o.id
WHERE o.status = 'failed' AND o.created_at > now() - interval '30 days'
GROUP BY o.id, o.status;

CREATE INDEX IF NOT EXISTS threads_owner_id_idx ON threads (owner_id);

CREATE INDEX IF NOT EXISTS shipments_status_idx ON shipments (status);

CREATE TABLE IF NOT EXISTS inventory_wallets (
	id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	inventory_id uuid NOT NULL REFERENCES inventorys (id) ON DELETE CASCADE,
	status text NOT NULL DEFAULT 'archived',
	amount numeric(12, 3) NOT NULL,
	created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS payout_payments (
	id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	payout_id uuid NOT NULL REFERENCES payouts (id) ON DELETE CASCADE,
	status text NOT NULL DEFAULT 'shipped',
	amount numeric(12, 3) NOT NULL,
	created_at timestamptz NOT NULL DEFAULT now()
);

SELECT o.id, o.status, sum(i.amount) AS total
FROM reviews o
	JOIN carts i ON i.review_id = o.id
WHERE o.status = 'pending' AND o.created_at > now() - interval '63 days'
GROUP BY o.id, o.status;

CREATE INDEX IF NOT EXISTS variants_status_idx ON variants (status);

CREATE TABLE IF NOT EXISTS cart_channels (
	id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	cart_id uuid NOT NULL REFERENCES carts (id) ON DELETE CASCADE,
	status text NOT NULL DEFAULT 'failed',
	amount numeric(12, 3) NOT NULL,
	created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS notification_invoices (
	id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	notification_id uuid NOT NULL REFERENCES notifications (id) ON DELETE CASCADE,
	status text NOT NULL DEFAULT 'refunded',
	amount numeric(12, 2) NOT NULL,
	created_at timestamptz NOT NULL DEFAULT now()
);

SELECT o.id, o.status, sum(i.amount) AS total
FROM orders o
	JOIN products i ON i.order_id = o.id
WHERE o.status = 'active' AND o.created_at > now() - interval '85 days'
GROUP BY o.id, o.status;

SELECT o.id, o.status, sum(i.amount) AS total
FROM discounts o
	JOIN sessions i ON i.discount_id = o.id
WHERE o.status = 'archived' AND o.created_at > now() - interval '4 days'
GROUP BY o.id, o.status;

SELECT o.id, o.status, sum(i.amount) AS total
FROM shipments o
	JOIN sellers i ON i.shipment_id = o.id
WHERE o.status = 'pending' AND o.created_at > now() - interval '48 days'
GROUP BY o.id, o.status;

CREATE INDEX IF NOT EXISTS sessions_marketplace_id_idx ON sessions (marketplace_id);

CREATE TABLE IF NOT EXISTS buyer_payouts (
	id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	buyer_id uuid NOT NULL REFERENCES buyers (id) ON DELETE CASCADE,
	status text NOT NULL DEFAULT 'pending',
	amount numeric(12, 2) NOT NULL,
	created_at timestamptz NOT NULL DEFAULT now()
);

SELECT o.id, o.status, sum(i.amount) AS total
FROM streams o
	JOIN checkouts i ON i.stream_id = o.id
WHERE o.status = 'cancelled' AND o.created_at > now() - interval '43 days'
GROUP BY o.id, o.status;

CREATE INDEX IF NOT EXISTS invoices_created_at_idx ON invoices (created_at);

SELECT o.id, o.status, sum(i.amount) AS total
FROM webhooks o
	JOIN labels i ON i.webhook_id = o.id
WHERE o.status = 'failed' AND o.created_at > now() - interval '18 days'
GROUP BY o.id, o.status;

SELECT o.id, o.status, sum(i.amount) AS total
FROM inventorys o
	JOIN coupons i ON i.inventory_id = o.id
WHERE o.status = 'pending' AND o.created_at > now() - interval '4 days'
GROUP BY o.id, o.status;

SELECT o.id, o.status, sum(i.amount) AS total
FROM offers o
	JOIN buyers i ON i.offer_id = o.id
WHERE o.status = 'delivered' AND o.created_at > now() - interval '19 days'
GROUP BY o.id, o.status;

CREATE INDEX IF NOT EXISTS streams_status_idx ON streams (status);

CREATE TABLE IF NOT EXISTS offer_sellers (
	id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	offer_id uuid NOT NULL REFERENCES offers (id) ON DELETE CASCADE,
	status text NOT NULL DEFAULT 'pending',
	amount numeric(12, 2) NOT NULL,
	created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS shipment_webhooks (
	id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	shipment_id uuid NOT NULL REFERENCES shipments (id) ON DELETE CASCADE,
	status text NOT NULL DEFAULT 'cancelled',
	amount numeric(12, 4) NOT NULL,
	created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS refunds_created_at_idx ON refunds (created_at);

CREATE INDEX IF NOT EXISTS carts_status_idx ON carts (status);

CREATE TABLE IF NOT EXISTS payout_webhooks (
	id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	payout_id uuid NOT NULL REFERENCES payouts (id) ON DELETE CASCADE,
	status text NOT NULL DEFAULT 'delivered',
	amount numeric(12, 4) NOT NULL,
	created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS variant_variants (
	id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	variant_id uuid NOT NULL REFERENCES variants (id) ON DELETE CASCADE,
	status text NOT NULL DEFAULT 'shipped',
	amount numeric(12, 2) NOT NULL,
	created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS channels_marketplace_id_idx ON channels (marketplace_id);

CREATE INDEX IF NOT EXISTS invoices_created_at_idx ON invoices (created_at);

SELECT o.id, o.status, sum(i.amount) AS total
FROM channels o
	JOIN payments i ON i.channel_id = o.id
WHERE o.status = 'failed' AND o.created_at > now() - interval '77 days'
GROUP BY o.id, o.status;

CREATE TABLE IF NOT EXISTS discount_payments (
	id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	discount_id uuid NOT NULL REFERENCES discounts (id) ON DELETE CASCADE,
	status text NOT NULL DEFAULT 'active',
	amount numeric(12, 4) NOT NULL,
	created_at timestamptz NOT NULL DEFAULT now()
);

SELECT o.id, o.status, sum(i.amount) AS total
FROM variants o
	JOIN coupons i ON i.variant_id = o.id
WHERE o.status = 'shipped' AND o.created_at > now() - interval '3 days'
GROUP BY o.id, o.status;

CREATE TABLE IF NOT EXISTS variant_prices (
	id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	variant_id uuid NOT NULL REFERENCES variants (id) ON DELETE CASCADE,
	status text NOT NULL DEFAULT 'refunded',
	amount numeric(12, 3) NOT NULL,
	created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS payouts_status_idx ON payouts (status);

SELECT o.id, o.status, sum(i.amount) AS total
FROM carts o
	JOIN labels i ON i.cart_id = o.id
WHERE o.status = 'active' AND o.created_at > now() - interval '20 days'
GROUP BY o.id, o.status;

CREATE INDEX IF NOT EXISTS threads_status_idx ON threads (status);

CREATE INDEX IF NOT EXISTS accounts_created_at_idx ON accounts (created_at);

CREATE INDEX IF NOT EXISTS reviews_created_at_idx ON reviews (created_at);

SELECT o.id, o.status, sum(i.amount) AS total
FROM inventorys o
	JOIN tokens i ON i.inventory_id = o.id
WHERE o.status = 'active' AND o.created_at > now() - interval '66 days'
GROUP BY o.id, o.status;

CREATE TABLE IF NOT EXISTS buyer_checkouts (
	id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	buyer_id uuid NOT NULL REFERENCES buyers (id) ON DELETE CASCADE,
	status text NOT NULL DEFAULT 'delivered',
	amount numeric(12, 3) NOT NULL,
	created_at timestamptz NOT NULL DEFAULT now()
);

SELECT o.id, o.status, sum(i.amount) AS total
FROM invoices o
	JOIN buyers i ON i.invoice_id = o.id
WHERE o.status = 'archived' AND o.created_at > now() - interval '38 days'
GROUP BY o.id, o.status;

CREATE INDEX IF NOT EXISTS invoices_marketplace_id_idx ON invoices (marketplace_id);

SELECT o.id, o.status, sum(i.amount) AS total
FROM invoices o
	JOIN sellers i ON i.invoice_id = o.id
WHERE o.status = 'cancelled' AND o.created_at > now() - interval '67 days'
GROUP BY o.id, o.status;

SELECT o.id, o.status, sum(i.amount) AS total
FROM variants o
	JOIN webhooks i ON i.variant_id = o.id
WHERE o.status = 'archived' AND o.created_at > now() - interval '58 days'
GROUP BY o.id, o.status;

CREATE INDEX IF NOT EXISTS products_created_at_idx ON products (created_at);

SELECT o.id, o.status, sum(i.amount) AS total
FROM invoices o
	JOIN labels i ON i.invoice_id = o.id
WHERE o.status = 'pending' AND o.created_at > now() - interval '1 days'
GROUP BY o.id, o.status;

CREATE TABLE IF NOT EXISTS cart_payments (
	id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	cart_id uuid NOT NULL REFERENCES carts (id) ON DELETE CASCADE,
	status text NOT NULL DEFAULT 'failed',
	amount numeric(12, 3) NOT NULL,
	created_at timestamptz NOT NULL DEFAULT now()
);

SELECT o.id, o.status, sum(i.amount) AS total
FROM buyers o
	JOIN buyers i ON i.buyer_id = o.id
WHERE o.status = 'pending' AND o.created_at > now() - interval '48 days'
GROUP BY o.id, o.status;

CREATE INDEX IF NOT EXISTS offers_owner_id_idx ON offers (owner_id);

CREATE INDEX IF NOT EXISTS variants_owner_id_idx ON variants (owner_id);

CREATE INDEX IF NOT EXISTS prices_owner_id_idx ON prices (owner_id);

CREATE INDEX IF NOT EXISTS wallets_marketplace_id_idx ON wallets (marketplace_id);

CREATE INDEX IF NOT EXISTS coupons_status_idx ON coupons (status);

CREATE TABLE IF NOT EXISTS order_wallets (
	id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	order_id uuid NOT NULL REFERENCES orders (id) ON DELETE CASCADE,
	status text NOT NULL DEFAULT 'failed',
	amount numeric(12, 3) NOT NULL,
	created_at timestamptz NOT NULL DEFAULT now()
);

SELECT o.id, o.status, sum(i.amount) AS total
FROM checkouts o
	JOIN sessions i ON i.checkout_id = o.id
WHERE o.status = 'shipped' AND o.created_at > now() - interval '3 days'
GROUP BY o.id, o.status;

SELECT o.id, o.status, sum(i.amount) AS total
FROM reviews o
	JOIN carts i ON i.review_id = o.id
WHERE o.status = 'active' AND o.created_at > now() - interval '9 days'
GROUP BY o.id, o.status;

SELECT o.id, o.status, sum(i.amount) AS total
FROM checkouts o
	JOIN webhooks i ON i.checkout_id = o.id
WHERE o.status = 'shipped' AND o.created_at > now() - interval '13 days'
GROUP BY o.id, o.status;

CREATE TABLE IF NOT EXISTS payout_products (
	id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	payout_id uuid NOT NULL REFERENCES payouts (id) ON DELETE CASCADE,
	status text NOT NULL DEFAULT 'active',
	amount numeric(12, 4) NOT NULL,
	created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS thread_buyers (
	id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	thread_id uuid NOT NULL REFERENCES threads (id) ON DELETE CASCADE,
	status text NOT NULL DEFAULT 'refunded',
	amount numeric(12, 2) NOT NULL,
	created_at timestamptz NOT NULL DEFAULT now()
);

SELECT o.id, o.status, sum(i.amount) AS total
FROM refunds o
	JOIN offers i ON i.refund_id = o.id
WHERE o.status = 'active' AND o.created_at > now() - interval '49 days'
GROUP BY o.id, o.status;

CREATE INDEX IF NOT EXISTS notifications_owner_id_idx ON notifications (owner_id);

CREATE TABLE IF NOT EXISTS seller_notifications (
	id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	seller_id uuid NOT NULL REFERENCES sellers (id) ON DELETE CASCADE,
	status text NOT NULL DEFAULT 'pending',
	amount numeric(12, 4) NOT NULL,
	created_at timestamptz NOT NULL DEFAULT now()
);

SELECT o.id, o.status, sum(i.amount) AS total
FROM invoices o
	JOIN notifications i ON i.invoice_id = o.id
WHERE o.status = 'failed' AND o.created_at > now() - interval '23 days'
GROUP BY o.id, o.status;

CREATE TABLE IF NOT EXISTS thread_webhooks (
	id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	thread_id uuid NOT NULL REFERENCES threads (id) ON DELETE CASCADE,
	status text NOT NULL DEFAULT 'shipped',
	amount numeric(12, 4) NOT NULL,
	created_at timestamptz NOT NULL DEFAULT now()
);

SELECT o.id, o.status, sum(i.amount) AS total
FROM invoices o
	JOIN discounts i ON i.invoice_id = o.id
WHERE o.status = 'failed' AND o.created_at > now() - interval '89 days'
GROUP BY o.id, o.status;

SELECT o.id, o.status, sum(i.amount) AS total
FROM payments o
	JOIN shipments i ON i.payment_id = o.id
WHERE o.status = 'failed' AND o.created_at > now() - interval '67 days'
GROUP BY o.id, o.status;

CREATE INDEX IF NOT EXISTS wallets_owner_id_idx ON wallets (owner_id);

CREATE INDEX IF NOT EXISTS offers_created_at_idx ON offers (created_at);

CREATE TABLE IF NOT EXISTS message_buyers (
	id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	message_id uuid NOT NULL REFERENCES messages (id) ON DELETE CASCADE,
	status text NOT NULL DEFAULT 'failed',
	amount numeric(12, 3) NOT NULL,
	created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS payouts_status_idx ON payouts (status);

CREATE TABLE IF NOT EXISTS buyer_tokens (
	id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	buyer_id uuid NOT NULL REFERENCES buyers (id) ON DELETE CASCADE,
	status text NOT NULL DEFAULT 'shipped',
	amount numeric(12, 3) NOT NULL,
	created_at timestamptz NOT NULL DEFAULT now()
);

SELECT o.id, o.status, sum(i.amount) AS total
FROM streams o
	JOIN invoices i ON i.stream_id = o.id
WHERE o.status = 'shipped' AND o.created_at > now() - interval '14 days'
GROUP BY o.id, o.status;

CREATE TABLE IF NOT EXISTS token_streams (
	id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	token_id uuid NOT NULL REFERENCES tokens (id) ON DELETE CASCADE,
	status text NOT NULL DEFAULT 'shipped',
	amount numeric(12, 2) NOT NULL,
	created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS offer_streams (
	id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	offer_id uuid NOT NULL REFERENCES offers (id) ON DELETE CASCADE,
	status text NOT NULL DEFAULT 'archived',
	amount numeric(12, 4) NOT NULL,
	created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS accounts_owner_id_idx ON accounts (owner_id);

SELECT o.id, o.status, sum(i.amount) AS total
FROM messages o
	JOIN payouts i ON i.message_id = o.id
WHERE o.status = 'refunded' AND o.created_at > now() - interval '57 days'
GROUP BY o.id, o.status;

CREATE INDEX IF NOT EXISTS messages_owner_id_idx ON messages (owner_id);

SELECT o.id, o.status, sum(i.amount) AS total
FROM payments o
	JOIN checkouts i ON i.payment_id = o.id
WHERE o.status = 'pending' AND o.created_at > now() - interval '64 days'
GROUP BY o.id, o.status;

SELECT o.id, o.status, sum(i.amount) AS total
FROM coupons o
	JOIN refunds i ON i.coupon_id = o.id
WHERE o.status = 'refunded' AND o.created_at > now() - interval '70 days'
GROUP BY o.id, o.status;

SELECT o.id, o.status, sum(i.amount) AS total
