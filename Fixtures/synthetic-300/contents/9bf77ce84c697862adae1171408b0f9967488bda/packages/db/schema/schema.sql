-- migrate:up

CREATE TABLE IF NOT EXISTS thread_discounts (
	id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	thread_id uuid NOT NULL REFERENCES threads (id) ON DELETE CASCADE,
	status text NOT NULL DEFAULT 'cancelled',
	amount numeric(12, 2) NOT NULL,
	created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS invoices_owner_id_idx ON invoices (owner_id);

CREATE INDEX IF NOT EXISTS tokens_status_idx ON tokens (status);

SELECT o.id, o.status, sum(i.amount) AS total
FROM reviews o
	JOIN accounts i ON i.review_id = o.id
WHERE o.status = 'failed' AND o.created_at > now() - interval '9 days'
GROUP BY o.id, o.status;

CREATE INDEX IF NOT EXISTS orders_owner_id_idx ON orders (owner_id);

CREATE INDEX IF NOT EXISTS reviews_owner_id_idx ON reviews (owner_id);

CREATE TABLE IF NOT EXISTS order_products (
	id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	order_id uuid NOT NULL REFERENCES orders (id) ON DELETE CASCADE,
	status text NOT NULL DEFAULT 'failed',
	amount numeric(12, 4) NOT NULL,
	created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS session_prices (
	id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	session_id uuid NOT NULL REFERENCES sessions (id) ON DELETE CASCADE,
	status text NOT NULL DEFAULT 'cancelled',
	amount numeric(12, 4) NOT NULL,
	created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS review_products (
	id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	review_id uuid NOT NULL REFERENCES reviews (id) ON DELETE CASCADE,
	status text NOT NULL DEFAULT 'shipped',
	amount numeric(12, 3) NOT NULL,
	created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS inventory_reviews (
	id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	inventory_id uuid NOT NULL REFERENCES inventorys (id) ON DELETE CASCADE,
	status text NOT NULL DEFAULT 'active',
	amount numeric(12, 2) NOT NULL,
	created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS listings_created_at_idx ON listings (created_at);

CREATE TABLE IF NOT EXISTS channel_coupons (
	id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	channel_id uuid NOT NULL REFERENCES channels (id) ON DELETE CASCADE,
	status text NOT NULL DEFAULT 'failed',
	amount numeric(12, 4) NOT NULL,
	created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS payments_marketplace_id_idx ON payments (marketplace_id);

CREATE TABLE IF NOT EXISTS variant_sessions (
	id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	variant_id uuid NOT NULL REFERENCES variants (id) ON DELETE CASCADE,
	status text NOT NULL DEFAULT 'archived',
	amount numeric(12, 3) NOT NULL,
	created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS labels_created_at_idx ON labels (created_at);

SELECT o.id, o.status, sum(i.amount) AS total
FROM reviews o
	JOIN invoices i ON i.review_id = o.id
WHERE o.status = 'active' AND o.created_at > now() - interval '47 days'
GROUP BY o.id, o.status;

CREATE INDEX IF NOT EXISTS streams_status_idx ON streams (status);

CREATE INDEX IF NOT EXISTS accounts_status_idx ON accounts (status);

SELECT o.id, o.status, sum(i.amount) AS total
FROM variants o
	JOIN carts i ON i.variant_id = o.id
WHERE o.status = 'delivered' AND o.created_at > now() - interval '37 days'
GROUP BY o.id, o.status;

CREATE TABLE IF NOT EXISTS order_payouts (
	id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	order_id uuid NOT NULL REFERENCES orders (id) ON DELETE CASCADE,
	status text NOT NULL DEFAULT 'shipped',
	amount numeric(12, 4) NOT NULL,
	created_at timestamptz NOT NULL DEFAULT now()
);

SELECT o.id, o.status, sum(i.amount) AS total
FROM variants o
	JOIN payouts i ON i.variant_id = o.id
WHERE o.status = 'shipped' AND o.created_at > now() - interval '4 days'
GROUP BY o.id, o.status;

CREATE INDEX IF NOT EXISTS sessions_marketplace_id_idx ON sessions (marketplace_id);

SELECT o.id, o.status, sum(i.amount) AS total
FROM tokens o
	JOIN inventorys i ON i.token_id = o.id
WHERE o.status = 'failed' AND o.created_at > now() - interval '44 days'
GROUP BY o.id, o.status;

CREATE TABLE IF NOT EXISTS invoice_sellers (
	id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	invoice_id uuid NOT NULL REFERENCES invoices (id) ON DELETE CASCADE,
	status text NOT NULL DEFAULT 'cancelled',
	amount numeric(12, 4) NOT NULL,
	created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS payments_status_idx ON payments (status);

SELECT o.id, o.status, sum(i.amount) AS total
FROM sellers o
	JOIN variants i ON i.seller_id = o.id
WHERE o.status = 'failed' AND o.created_at > now() - interval '76 days'
GROUP BY o.id, o.status;

CREATE TABLE IF NOT EXISTS coupon_threads (
	id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	coupon_id uuid NOT NULL REFERENCES coupons (id) ON DELETE CASCADE,
	status text NOT NULL DEFAULT 'delivered',
	amount numeric(12, 3) NOT NULL,
	created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS price_webhooks (
	id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	price_id uuid NOT NULL REFERENCES prices (id) ON DELETE CASCADE,
	status text NOT NULL DEFAULT 'shipped',
	amount numeric(12, 3) NOT NULL,
	created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS refunds_owner_id_idx ON refunds (owner_id);

SELECT o.id, o.status, sum(i.amount) AS total
FROM prices o
	JOIN labels i ON i.price_id = o.id
WHERE o.status = 'delivered' AND o.created_at > now() - interval '19 days'
GROUP BY o.id, o.status;

CREATE TABLE IF NOT EXISTS order_streams (
	id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	order_id uuid NOT NULL REFERENCES orders (id) ON DELETE CASCADE,
	status text NOT NULL DEFAULT 'active',
	amount numeric(12, 4) NOT NULL,
	created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS shipments_status_idx ON shipments (status);

CREATE TABLE IF NOT EXISTS thread_invoices (
	id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	thread_id uuid NOT NULL REFERENCES threads (id) ON DELETE CASCADE,
	status text NOT NULL DEFAULT 'delivered',
	amount numeric(12, 3) NOT NULL,
	created_at timestamptz NOT NULL DEFAULT now()
);

SELECT o.id, o.status, sum(i.amount) AS total
FROM shipments o
	JOIN streams i ON i.shipment_id = o.id
WHERE o.status = 'failed' AND o.created_at > now() - interval '83 days'
GROUP BY o.id, o.status;

CREATE INDEX IF NOT EXISTS coupons_marketplace_id_idx ON coupons (marketplace_id);

CREATE TABLE IF NOT EXISTS invoice_channels (
	id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	invoice_id uuid NOT NULL REFERENCES invoices (id) ON DELETE CASCADE,
	status text NOT NULL DEFAULT 'pending',
	amount numeric(12, 2) NOT NULL,
	created_at timestamptz NOT NULL DEFAULT now()
);

SELECT o.id, o.status, sum(i.amount) AS total
FROM products o
	JOIN labels i ON i.product_id = o.id
WHERE o.status = 'active' AND o.created_at > now() - interval '60 days'
GROUP BY o.id, o.status;

SELECT o.id, o.status, sum(i.amount) AS total
FROM inventorys o
	JOIN threads i ON i.inventory_id = o.id
WHERE o.status = 'refunded' AND o.created_at > now() - interval '32 days'
GROUP BY o.id, o.status;

SELECT o.id, o.status, sum(i.amount) AS total
FROM sessions o
	JOIN messages i ON i.session_id = o.id
WHERE o.status = 'cancelled' AND o.created_at > now() - interval '22 days'
GROUP BY o.id, o.status;

SELECT o.id, o.status, sum(i.amount) AS total
FROM buyers o
	JOIN streams i ON i.buyer_id = o.id
WHERE o.status = 'shipped' AND o.created_at > now() - interval '14 days'
GROUP BY o.id, o.status;

SELECT o.id, o.status, sum(i.amount) AS total
FROM webhooks o
	JOIN prices i ON i.webhook_id = o.id
WHERE o.status = 'delivered' AND o.created_at > now() - interval '9 days'
GROUP BY o.id, o.status;

SELECT o.id, o.status, sum(i.amount) AS total
FROM payments o
	JOIN streams i ON i.payment_id = o.id
WHERE o.status = 'cancelled' AND o.created_at > now() - interval '29 days'
GROUP BY o.id, o.status;

CREATE TABLE IF NOT EXISTS label_buyers (
	id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	label_id uuid NOT NULL REFERENCES labels (id) ON DELETE CASCADE,
	status text NOT NULL DEFAULT 'active',
	amount numeric(12, 3) NOT NULL,
	created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS thread_invoices (
	id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	thread_id uuid NOT NULL REFERENCES threads (id) ON DELETE CASCADE,
	status text NOT NULL DEFAULT 'shipped',
	amount numeric(12, 4) NOT NULL,
	created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS sessions_owner_id_idx ON sessions (owner_id);

SELECT o.id, o.status, sum(i.amount) AS total
FROM shipments o
	JOIN coupons i ON i.shipment_id = o.id
WHERE o.status = 'refunded' AND o.created_at > now() - interval '58 days'
GROUP BY o.id, o.status;

CREATE TABLE IF NOT EXISTS thread_coupons (
	id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	thread_id uuid NOT NULL REFERENCES threads (id) ON DELETE CASCADE,
	status text NOT NULL DEFAULT 'archived',
	amount numeric(12, 2) NOT NULL,
	created_at timestamptz NOT NULL DEFAULT now()
);

SELECT o.id, o.status, sum(i.amount) AS total
FROM messages o
	JOIN invoices i ON i.message_id = o.id
WHERE o.status = 'cancelled' AND o.created_at > now() - interval '62 days'
GROUP BY o.id, o.status;

CREATE TABLE IF NOT EXISTS refund_shipments (
	id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	refund_id uuid NOT NULL REFERENCES refunds (id) ON DELETE CASCADE,
	status text NOT NULL DEFAULT 'cancelled',
	amount numeric(12, 3) NOT NULL,
	created_at timestamptz NOT NULL DEFAULT now()
);

SELECT o.id, o.status, sum(i.amount) AS total
FROM threads o
	JOIN carts i ON i.thread_id = o.id
WHERE o.status = 'delivered' AND o.created_at > now() - interval '33 days'
GROUP BY o.id, o.status;

SELECT o.id, o.status, sum(i.amount) AS total
FROM sellers o
	JOIN variants i ON i.seller_id = o.id
WHERE o.status = 'failed' AND o.created_at > now() - interval '31 days'
GROUP BY o.id, o.status;

CREATE TABLE IF NOT EXISTS discount_orders (
	id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	discount_id uuid NOT NULL REFERENCES discounts (id) ON DELETE CASCADE,
	status text NOT NULL DEFAULT 'delivered',
	amount numeric(12, 2) NOT NULL,
	created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS reviews_status_idx ON reviews (status);

SELECT o.id, o.status, sum(i.amount) AS total
FROM wallets o
	JOIN offers i ON i.wallet_id = o.id
WHERE o.status = 'shipped' AND o.created_at > now() - interval '51 days'
GROUP BY o.id, o.status;

CREATE INDEX IF NOT EXISTS payouts_status_idx ON payouts (status);

CREATE TABLE IF NOT EXISTS shipment_offers (
	id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	shipment_id uuid NOT NULL REFERENCES shipments (id) ON DELETE CASCADE,
	status text NOT NULL DEFAULT 'archived',
	amount numeric(12, 2) NOT NULL,
	created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS invoice_notifications (
	id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	invoice_id uuid NOT NULL REFERENCES invoices (id) ON DELETE CASCADE,
	status text NOT NULL DEFAULT 'pending',
	amount numeric(12, 2) NOT NULL,
	created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS cart_discounts (
	id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	cart_id uuid NOT NULL REFERENCES carts (id) ON DELETE CASCADE,
	status text NOT NULL DEFAULT 'shipped',
	amount numeric(12, 3) NOT NULL,
	created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS payouts_created_at_idx ON payouts (created_at);

CREATE TABLE IF NOT EXISTS message_products (
	id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	message_id uuid NOT NULL REFERENCES messages (id) ON DELETE CASCADE,
	status text NOT NULL DEFAULT 'cancelled',
	amount numeric(12, 4) NOT NULL,
	created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS payouts_status_idx ON payouts (status);

CREATE TABLE IF NOT EXISTS payout_coupons (
	id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	payout_id uuid NOT NULL REFERENCES payouts (id) ON DELETE CASCADE,
	status text NOT NULL DEFAULT 'delivered',
	amount numeric(12, 4) NOT NULL,
	created_at timestamptz NOT NULL DEFAULT now()
);

SELECT o.id, o.status, sum(i.amount) AS total
FROM channels o
	JOIN wallets i ON i.channel_id = o.id
WHERE o.status = 'failed' AND o.created_at > now() - interval '27 days'
GROUP BY o.id, o.status;

SELECT o.id, o.status, sum(i.amount) AS total
FROM invoices o
	JOIN webhooks i ON i.invoice_id = o.id
WHERE o.status = 'refunded' AND o.created_at > now() - interval '34 days'
GROUP BY o.id, o.status;

SELECT o.id, o.status, sum(i.amount) AS total
FROM coupons o
	JOIN threads i ON i.coupon_id = o.id
WHERE o.status = 'pending' AND o.created_at > now() - interval '74 days'
GROUP BY o.id, o.status;

SELECT o.id, o.status, sum(i.amount) AS total
FROM channels o
	JOIN labels i ON i.channel_id = o.id
WHERE o.status = 'cancelled' AND o.created_at > now() - interval '14 days'
GROUP BY o.id, o.status;

SELECT o.id, o.status, sum(i.amount) AS total
FROM offers o
	JOIN refunds i ON i.offer_id = o.id
WHERE o.status = 'cancelled' AND o.created_at > now() - interval '69 days'
GROUP BY o.id, o.status;

CREATE INDEX IF NOT EXISTS discounts_owner_id_idx ON discounts (owner_id);

CREATE INDEX IF NOT EXISTS webhooks_marketplace_id_idx ON webhooks (marketplace_id);

CREATE TABLE IF NOT EXISTS coupon_sellers (
	id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	coupon_id uuid NOT NULL REFERENCES coupons (id) ON DELETE CASCADE,
	status text NOT NULL DEFAULT 'pending',
	amount numeric(12, 3) NOT NULL,
	created_at timestamptz NOT NULL DEFAULT now()
);

SELECT o.id, o.status, sum(i.amount) AS total
FROM buyers o
	JOIN refunds i ON i.buyer_id = o.id
WHERE o.status = 'archived' AND o.created_at > now() - interval '12 days'
GROUP BY o.id, o.status;

CREATE INDEX IF NOT EXISTS payouts_owner_id_idx ON payouts (owner_id);

CREATE INDEX IF NOT EXISTS payouts_created_at_idx ON payouts (created_at);

CREATE TABLE IF NOT EXISTS token_wallets (
	id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	token_id uuid NOT NULL REFERENCES tokens (id) ON DELETE CASCADE,
	status text NOT NULL DEFAULT 'archived',
	amount numeric(12, 4) NOT NULL,
	created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS accounts_created_at_idx ON accounts (created_at);

SELECT o.id, o.status, sum(i.amount) AS total
FROM prices o
	JOIN messages i ON i.price_id = o.id
WHERE o.status = 'cancelled' AND o.created_at > now() - interval '20 days'
GROUP BY o.id, o.status;

CREATE TABLE IF NOT EXISTS listing_offers (
	id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	listing_id uuid NOT NULL REFERENCES listings (id) ON DELETE CASCADE,
	status text NOT NULL DEFAULT 'refunded',
	amount numeric(12, 2) NOT NULL,
	created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS seller_channels (
	id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	seller_id uuid NOT NULL REFERENCES sellers (id) ON DELETE CASCADE,
	status text NOT NULL DEFAULT 'cancelled',
	amount numeric(12, 4) NOT NULL,
	created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS wallets_created_at_idx ON wallets (created_at);

CREATE TABLE IF NOT EXISTS discount_shipments (
	id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	discount_id uuid NOT NULL REFERENCES discounts (id) ON DELETE CASCADE,
	status text NOT NULL DEFAULT 'failed',
	amount numeric(12, 2) NOT NULL,
	created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS labels_created_at_idx ON labels (created_at);

CREATE TABLE IF NOT EXISTS account_refunds (
	id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	account_id uuid NOT NULL REFERENCES accounts (id) ON DELETE CASCADE,
	status text NOT NULL DEFAULT 'delivered',
	amount numeric(12, 2) NOT NULL,
	created_at timestamptz NOT NULL DEFAULT now()
);

SELECT o.id, o.status, sum(i.amount) AS total
FROM notifications o
	JOIN sellers i ON i.notification_id = o.id
WHERE o.status = 'shipped' AND o.created_at > now() - interval '29 days'
GROUP BY o.id, o.status;

CREATE INDEX IF NOT EXISTS orders_marketplace_id_idx ON orders (marketplace_id);

SELECT o.id, o.status, sum(i.amount) AS total
FROM channels o
	JOIN carts i ON i.channel_id = o.id
WHERE o.status = 'pending' AND o.created_at > now() - interval '74 days'
GROUP BY o.id, o.status;

CREATE INDEX IF NOT EXISTS sessions_created_at_idx ON sessions (created_at);

CREATE INDEX IF NOT EXISTS messages_marketplace_id_idx ON messages (marketplace_id);

CREATE INDEX IF NOT EXISTS tokens_status_idx ON tokens (status);

SELECT o.id, o.status, sum(i.amount) AS total
FROM notifications o
	JOIN threads i ON i.notification_id = o.id
WHERE o.status = 'active' AND o.created_at > now() - interval '57 days'
GROUP BY o.id, o.status;

SELECT o.id, o.status, sum(i.amount) AS total
FROM checkouts o
	JOIN wallets i ON i.checkout_id = o.id
WHERE o.status = 'refunded' AND o.created_at > now() - interval '70 days'
GROUP BY o.id, o.status;

SELECT o.id, o.status, sum(i.amount) AS total
FROM threads o
	JOIN reviews i ON i.thread_id = o.id
WHERE o.status = 'delivered' AND o.created_at > now() - interval '53 days'
GROUP BY o.id, o.status;

CREATE TABLE IF NOT EXISTS notification_payments (
	id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	notification_id uuid NOT NULL REFERENCES notifications (id) ON DELETE CASCADE,
	status text NOT NULL DEFAULT 'refunded',
	amount numeric(12, 3) NOT NULL,
	created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS seller_webhooks (
	id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	seller_id uuid NOT NULL REFERENCES sellers (id) ON DELETE CASCADE,
	status text NOT NULL DEFAULT 'failed',
	amount numeric(12, 3) NOT NULL,
	created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS session_payouts (
	id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	session_id uuid NOT NULL REFERENCES sessions (id) ON DELETE CASCADE,
	status text NOT NULL DEFAULT 'active',
	amount numeric(12, 4) NOT NULL,
	created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS buyers_created_at_idx ON buyers (created_at);

SELECT o.id, o.status, sum(i.amount) AS total
FROM messages o
	JOIN carts i ON i.message_id = o.id
WHERE o.status = 'cancelled' AND o.created_at > now() - interval '16 days'
GROUP BY o.id, o.status;

SELECT o.id, o.status, sum(i.amount) AS total
FROM webhooks o
	JOIN labels i ON i.webhook_id = o.id
WHERE o.status = 'shipped' AND o.created_at > now() - interval '36 days'
GROUP BY o.id, o.status;

SELECT o.id, o.status, sum(i.amount) AS total
FROM checkouts o
	JOIN shipments i ON i.checkout_id = o.id
WHERE o.status = 'archived' AND o.created_at > now() - interval '5 days'
GROUP BY o.id, o.status;

CREATE TABLE IF NOT EXISTS refund_orders (
	id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	refund_id uuid NOT NULL REFERENCES refunds (id) ON DELETE CASCADE,
	status text NOT NULL DEFAULT 'refunded',
	amount numeric(12, 2) NOT NULL,
	created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS sessions_created_at_idx ON sessions (created_at);

CREATE INDEX IF NOT EXISTS wallets_marketplace_id_idx ON wallets (marketplace_id);

CREATE TABLE IF NOT EXISTS checkout_sellers (
	id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	checkout_id uuid NOT NULL REFERENCES checkouts (id) ON DELETE CASCADE,
	status text NOT NULL DEFAULT 'failed',
	amount numeric(12, 4) NOT NULL,
	created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS sellers_status_idx ON sellers (status);

CREATE INDEX IF NOT EXISTS sessions_owner_id_idx ON sessions (owner_id);

SELECT o.id, o.status, sum(i.amount) AS total
FROM refunds o
	JOIN accounts i ON i.refund_id = o.id
WHERE o.status = 'pending' AND o.created_at > now() - interval '68 days'
GROUP BY o.id, o.status;

CREATE TABLE IF NOT EXISTS variant_webhooks (
	id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	variant_id uuid NOT NULL REFERENCES variants (id) ON DELETE CASCADE,
	status text NOT NULL DEFAULT 'shipped',
	amount numeric(12, 3) NOT NULL,
	created_at timestamptz NOT NULL DEFAULT now()
);

SELECT o.id, o.status, sum(i.amount) AS total
FROM payments o
	JOIN products i ON i.payment_id = o.id
WHERE o.status = 'cancelled' AND o.created_at > now() - interval '6 days'
GROUP BY o.id, o.status;

SELECT o.id, o.status, sum(i.amount) AS total
FROM labels o
	JOIN refunds i ON i.label_id = o.id
WHERE o.status = 'delivered' AND o.created_at > now() - interval '88 days'
GROUP BY o.id, o.status;

CREATE TABLE IF NOT EXISTS cart_buyers (
	id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	cart_id uuid NOT NULL REFERENCES carts (id) ON DELETE CASCADE,
	status text NOT NULL DEFAULT 'active',
	amount numeric(12, 4) NOT NULL,
	created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS shipments_created_at_idx ON shipments (created_at);

CREATE TABLE IF NOT EXISTS listing_streams (
	id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	listing_id uuid NOT NULL REFERENCES listings (id) ON DELETE CASCADE,
	status text NOT NULL DEFAULT 'refunded',
	amount numeric(12, 2) NOT NULL,
	created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS offer_tokens (
	id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	offer_id uuid NOT NULL REFERENCES offers (id) ON DELETE CASCADE,
	status text NOT NULL DEFAULT 'pending',
	amount numeric(12, 4) NOT NULL,
	created_at timestamptz NOT NULL DEFAULT now()
);

SELECT o.id, o.status, sum(i.amount) AS total
FROM offers o
	JOIN channels i ON i.offer_id = o.id
WHERE o.status = 'shipped' AND o.created_at > now() - interval '67 days'
GROUP BY o.id, o.status;

SELECT o.id, o.status, sum(i.amount) AS total
FROM offers o
	JOIN sessions i ON i.offer_id = o.id
WHERE o.status = 'refunded' AND o.created_at > now() - interval '53 days'
GROUP BY o.id, o.status;

CREATE INDEX IF NOT EXISTS prices_created_at_idx ON prices (created_at);

CREATE TABLE IF NOT EXISTS wallet_listings (
	id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	wallet_id uuid NOT NULL REFERENCES wallets (id) ON DELETE CASCADE,
	status text NOT NULL DEFAULT 'active',
	amount numeric(12, 2) NOT NULL,
	created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS labels_marketplace_id_idx ON labels (marketplace_id);

CREATE INDEX IF NOT EXISTS channels_marketplace_id_idx ON channels (marketplace_id);

SELECT o.id, o.status, sum(i.amount) AS total
FROM variants o
	JOIN shipments i ON i.variant_id = o.id
WHERE o.status = 'refunded' AND o.created_at > now() - interval '71 days'
GROUP BY o.id, o.status;

CREATE TABLE IF NOT EXISTS webhook_sellers (
	id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	webhook_id uuid NOT NULL REFERENCES webhooks (id) ON DELETE CASCADE,
	status text NOT NULL DEFAULT 'pending',
	amount numeric(12, 3) NOT NULL,
	created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS coupons_owner_id_idx ON coupons (owner_id);

CREATE INDEX IF NOT EXISTS invoices_marketplace_id_idx ON invoices (marketplace_id);

CREATE INDEX IF NOT EXISTS coupons_status_idx ON coupons (status);

CREATE TABLE IF NOT EXISTS payout_messages (
	id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	payout_id uuid NOT NULL REFERENCES payouts (id) ON DELETE CASCADE,
	status text NOT NULL DEFAULT 'cancelled',
	amount numeric(12, 3) NOT NULL,
	created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS coupon_reviews (
	id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	coupon_id uuid NOT NULL REFERENCES coupons (id) ON DELETE CASCADE,
	status text NOT NULL DEFAULT 'shipped',
	amount numeric(12, 3) NOT NULL,
	created_at timestamptz NOT NULL DEFAULT now()
);

SELECT o.id, o.status, sum(i.amount) AS total
FROM wallets o
	JOIN refunds i ON i.wallet_id = o.id
WHERE o.status = 'active' AND o.created_at > now() - interval '61 days'
GROUP BY o.id, o.status;

CREATE TABLE IF NOT EXISTS payout_shipments (
	id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	payout_id uuid NOT NULL REFERENCES payouts (id) ON DELETE CASCADE,
	status text NOT NULL DEFAULT 'shipped',
	amount numeric(12, 2) NOT NULL,
	created_at timestamptz NOT NULL DEFAULT now()
);

SELECT o.id, o.status, sum(i.amount) AS total
FROM prices o
	JOIN offers i ON i.price_id = o.id
WHERE o.status = 'archived' AND o.created_at > now() - interval '27 days'
GROUP BY o.id, o.status;

SELECT o.id, o.status, sum(i.amount) AS total
FROM reviews o
	JOIN sellers i ON i.review_id = o.id
WHERE o.status = 'shipped' AND o.created_at > now() - interval '80 days'
GROUP BY o.id, o.status;

CREATE TABLE IF NOT EXISTS channel_inventorys (
	id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	channel_id uuid NOT NULL REFERENCES channels (id) ON DELETE CASCADE,
	status text NOT NULL DEFAULT 'refunded',
	amount numeric(12, 2) NOT NULL,
	created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS discount_webhooks (
	id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	discount_id uuid NOT NULL REFERENCES discounts (id) ON DELETE CASCADE,
	status text NOT NULL DEFAULT 'failed',
	amount numeric(12, 4) NOT NULL,
	created_at timestamptz NOT NULL DEFAULT now()
);

SELECT o.id, o.status, sum(i.amount) AS total
FROM tokens o
	JOIN notifications i ON i.token_id = o.id
WHERE o.status = 'active' AND o.created_at > now() - interval '35 days'
GROUP BY o.id, o.status;

CREATE INDEX IF NOT EXISTS webhooks_created_at_idx ON webhooks (created_at);

CREATE TABLE IF NOT EXISTS payment_variants (
	id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	payment_id uuid NOT NULL REFERENCES payments (id) ON DELETE CASCADE,
	status text NOT NULL DEFAULT 'failed',
	amount numeric(12, 3) NOT NULL,
	created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS prices_status_idx ON prices (status);

CREATE INDEX IF NOT EXISTS accounts_marketplace_id_idx ON accounts (marketplace_id);

CREATE TABLE IF NOT EXISTS offer_checkouts (
	id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	offer_id uuid NOT NULL REFERENCES offers (id) ON DELETE CASCADE,
	status text NOT NULL DEFAULT 'pending',
	amount numeric(12, 3) NOT NULL,
	created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS wallets_created_at_idx ON wallets (created_at);

SELECT o.id, o.status, sum(i.amount) AS total
FROM carts o
	JOIN threads i ON i.cart_id = o.id
WHERE o.status = 'failed' AND o.created_at > now() - interval '6 days'
GROUP BY o.id, o.status;

SELECT o.id, o.status, sum(i.amount) AS total
FROM orders o
	JOIN streams i ON i.order_id = o.id
WHERE o.status = 'refunded' AND o.created_at > now() - interval '18 days'
GROUP BY o.id, o.status;

SELECT o.id, o.status, sum(i.amount) AS total
FROM sellers o
	JOIN messages i ON i.seller_id = o.id
WHERE o.status = 'archived' AND o.created_at > now() - interval '22 days'
GROUP BY o.id, o.status;

SELECT o.id, o.status, sum(i.amount) AS total
FROM tokens o
	JOIN refunds i ON i.token_id = o.id
WHERE o.status = 'cancelled' AND o.created_at > now() - interval '19 days'
GROUP BY o.id, o.status;

SELECT o.id, o.status, sum(i.amount) AS total
FROM wallets o
	JOIN reviews i ON i.wallet_id = o.id
WHERE o.status = 'refunded' AND o.created_at > now() - interval '34 days'
GROUP BY o.id, o.status;

CREATE INDEX IF NOT EXISTS prices_owner_id_idx ON prices (owner_id);

SELECT o.id, o.status, sum(i.amount) AS total
FROM checkouts o
	JOIN prices i ON i.checkout_id = o.id
WHERE o.status = 'delivered' AND o.created_at > now() - interval '47 days'
GROUP BY o.id, o.status;

CREATE INDEX IF NOT EXISTS orders_owner_id_idx ON orders (owner_id);

CREATE TABLE IF NOT EXISTS offer_labels (
	id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	offer_id uuid NOT NULL REFERENCES offers (id) ON DELETE CASCADE,
	status text NOT NULL DEFAULT 'failed',
	amount numeric(12, 2) NOT NULL,
	created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS review_discounts (
	id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	review_id uuid NOT NULL REFERENCES reviews (id) ON DELETE CASCADE,
	status text NOT NULL DEFAULT 'shipped',
	amount numeric(12, 2) NOT NULL,
	created_at timestamptz NOT NULL DEFAULT now()
);

SELECT o.id, o.status, sum(i.amount) AS total
FROM offers o
	JOIN products i ON i.offer_id = o.id
WHERE o.status = 'shipped' AND o.created_at > now() - interval '17 days'
GROUP BY o.id, o.status;

CREATE TABLE IF NOT EXISTS wallet_refunds (
	id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	wallet_id uuid NOT NULL REFERENCES wallets (id) ON DELETE CASCADE,
	status text NOT NULL DEFAULT 'refunded',
	amount numeric(12, 2) NOT NULL,
	created_at timestamptz NOT NULL DEFAULT now()
);

SELECT o.id, o.status, sum(i.amount) AS total
FROM orders o
	JOIN wallets i ON i.order_id = o.id
WHERE o.status = 'archived' AND o.created_at > now() - interval '31 days'
GROUP BY o.id, o.status;

CREATE TABLE IF NOT EXISTS wallet_webhooks (
	id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	wallet_id uuid NOT NULL REFERENCES wallets (id) ON DELETE CASCADE,
	status text NOT NULL DEFAULT 'shipped',
	amount numeric(12, 4) NOT NULL,
	created_at timestamptz NOT NULL DEFAULT now()
);

SELECT o.id, o.status, sum(i.amount) AS total
FROM coupons o
	JOIN threads i ON i.coupon_id = o.id
WHERE o.status = 'active' AND o.created_at > now() - interval '55 days'
GROUP BY o.id, o.status;

CREATE INDEX IF NOT EXISTS streams_owner_id_idx ON streams (owner_id);

SELECT o.id, o.status, sum(i.amount) AS total
FROM refunds o
	JOIN labels i ON i.refund_id = o.id
WHERE o.status = 'pending' AND o.created_at > now() - interval '76 days'
GROUP BY o.id, o.status;

SELECT o.id, o.status, sum(i.amount) AS total
FROM discounts o
	JOIN invoices i ON i.discount_id = o.id
WHERE o.status = 'refunded' AND o.created_at > now() - interval '32 days'
GROUP BY o.id, o.status;

CREATE TABLE IF NOT EXISTS discount_streams (
	id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	discount_id uuid NOT NULL REFERENCES discounts (id) ON DELETE CASCADE,
	status text NOT NULL DEFAULT 'archived',
	amount numeric(12, 3) NOT NULL,
	created_at timestamptz NOT NULL DEFAULT now()
);

SELECT o.id, o.status, sum(i.amount) AS total
FROM invoices o
	JOIN payments i ON i.invoice_id = o.id
WHERE o.status = 'refunded' AND o.created_at > now() - interval '10 days'
GROUP BY o.id, o.status;

SELECT o.id, o.status, sum(i.amount) AS total
FROM labels o
	JOIN reviews i ON i.label_id = o.id
WHERE o.status = 'refunded' AND o.created_at > now() - interval '52 days'
GROUP BY o.id, o.status;

SELECT o.id, o.status, sum(i.amount) AS total
FROM tokens o
	JOIN invoices i ON i.token_id = o.id
WHERE o.status = 'refunded' AND o.created_at > now() - interval '62 days'
GROUP BY o.id, o.status;

CREATE INDEX IF NOT EXISTS offers_marketplace_id_idx ON offers (marketplace_id);

CREATE TABLE IF NOT EXISTS review_streams (
	id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	review_id uuid NOT NULL REFERENCES reviews (id) ON DELETE CASCADE,
	status text NOT NULL DEFAULT 'active',
	amount numeric(12, 3) NOT NULL,
	created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS discounts_created_at_idx ON discounts (created_at);

CREATE INDEX IF NOT EXISTS streams_status_idx ON streams (status);

CREATE TABLE IF NOT EXISTS review_shipments (
	id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	review_id uuid NOT NULL REFERENCES reviews (id) ON DELETE CASCADE,
	status text NOT NULL DEFAULT 'active',
	amount numeric(12, 3) NOT NULL,
	created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS invoices_created_at_idx ON invoices (created_at);

CREATE INDEX IF NOT EXISTS carts_marketplace_id_idx ON carts (marketplace_id);

CREATE TABLE IF NOT EXISTS wallet_messages (
	id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	wallet_id uuid NOT NULL REFERENCES wallets (id) ON DELETE CASCADE,
	status text NOT NULL DEFAULT 'refunded',
	amount numeric(12, 4) NOT NULL,
	created_at timestamptz NOT NULL DEFAULT now()
);

SELECT o.id, o.status, sum(i.amount) AS total
FROM payouts o
	JOIN listings i ON i.payout_id = o.id
WHERE o.status = 'cancelled' AND o.created_at > now() - interval '72 days'
GROUP BY o.id, o.status;

SELECT o.id, o.status, sum(i.amount) AS total
FROM webhooks o
	JOIN coupons i ON i.webhook_id = o.id
WHERE o.status = 'delivered' AND o.created_at > now() - interval '87 days'
GROUP BY o.id, o.status;

CREATE TABLE IF NOT EXISTS listing_sessions (
	id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	listing_id uuid NOT NULL REFERENCES listings (id) ON DELETE CASCADE,
	status text NOT NULL DEFAULT 'refunded',
	amount numeric(12, 4) NOT NULL,
	created_at timestamptz NOT NULL DEFAULT now()
);

SELECT o.id, o.status, sum(i.amount) AS total
FROM threads o
	JOIN accounts i ON i.thread_id = o.id
WHERE o.status = 'shipped' AND o.created_at > now() - interval '28 days'
GROUP BY o.id, o.status;

CREATE TABLE IF NOT EXISTS price_checkouts (
	id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	price_id uuid NOT NULL REFERENCES prices (id) ON DELETE CASCADE,
	status text NOT NULL DEFAULT 'shipped',
	amount numeric(12, 4) NOT NULL,
	created_at timestamptz NOT NULL DEFAULT now()
);

SELECT o.id, o.status, sum(i.amount) AS total
FROM buyers o
	JOIN checkouts i ON i.buyer_id = o.id
WHERE o.status = 'refunded' AND o.created_at > now() - interval '41 days'
GROUP BY o.id, o.status;

CREATE INDEX IF NOT EXISTS sessions_marketplace_id_idx ON sessions (marketplace_id);

CREATE TABLE IF NOT EXISTS webhook_threads (
	id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	webhook_id uuid NOT NULL REFERENCES webhooks (id) ON DELETE CASCADE,
	status text NOT NULL DEFAULT 'delivered',
	amount numeric(12, 4) NOT NULL,
	created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS review_discounts (
	id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	review_id uuid NOT NULL REFERENCES reviews (id) ON DELETE CASCADE,
	status text NOT NULL DEFAULT 'refunded',
	amount numeric(12, 2) NOT NULL,
	created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS notification_checkouts (
	id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	notification_id uuid NOT NULL REFERENCES notifications (id) ON DELETE CASCADE,
	status text NOT NULL DEFAULT 'refunded',
	amount numeric(12, 2) NOT NULL,
	created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS discount_buyers (
	id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	discount_id uuid NOT NULL REFERENCES discounts (id) ON DELETE CASCADE,
	status text NOT NULL DEFAULT 'shipped',
	amount numeric(12, 2) NOT NULL,
	created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS buyer_webhooks (
	id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	buyer_id uuid NOT NULL REFERENCES buyers (id) ON DELETE CASCADE,
	status text NOT NULL DEFAULT 'failed',
	amount numeric(12, 3) NOT NULL,
	created_at timestamptz NOT NULL DEFAULT now()
);

SELECT o.id, o.status, sum(i.amount) AS total
FROM invoices o
	JOIN messages i ON i.invoice_id = o.id
WHERE o.status = 'refunded' AND o.created_at > now() - interval '64 days'
GROUP BY o.id, o.status;

SELECT o.id, o.status, sum(i.amount) AS total
FROM sessions o
	JOIN invoices i ON i.session_id = o.id
WHERE o.status = 'delivered' AND o.created_at > now() - interval '23 days'
GROUP BY o.id, o.status;

CREATE INDEX IF NOT EXISTS sessions_created_at_idx ON sessions (created_at);

SELECT o.id, o.status, sum(i.amount) AS total
FROM streams o
	JOIN variants i ON i.stream_id = o.id
WHERE o.status = 'pending' AND o.created_at > now() - interval '51 days'
GROUP BY o.id, o.status;

CREATE TABLE IF NOT EXISTS label_accounts (
	id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	label_id uuid NOT NULL REFERENCES labels (id) ON DELETE CASCADE,
	status text NOT NULL DEFAULT 'shipped',
	amount numeric(12, 4) NOT NULL,
	created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS tokens_status_idx ON tokens (status);

CREATE INDEX IF NOT EXISTS wallets_created_at_idx ON wallets (created_at);

CREATE TABLE IF NOT EXISTS buyer_payouts (
	id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	buyer_id uuid NOT NULL REFERENCES buyers (id) ON DELETE CASCADE,
	status text NOT NULL DEFAULT 'delivered',
	amount numeric(12, 2) NOT NULL,
	created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS token_invoices (
	id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	token_id uuid NOT NULL REFERENCES tokens (id) ON DELETE CASCADE,
	status text NOT NULL DEFAULT 'refunded',
	amount numeric(12, 2) NOT NULL,
	created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS orders_status_idx ON orders (status);

CREATE TABLE IF NOT EXISTS invoice_accounts (
	id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	invoice_id uuid NOT NULL REFERENCES invoices (id) ON DELETE CASCADE,
	status text NOT NULL DEFAULT 'pending',
	amount numeric(12, 2) NOT NULL,
	created_at timestamptz NOT NULL DEFAULT now()
);

SELECT o.id, o.status, sum(i.amount) AS total
FROM coupons o
	JOIN variants i ON i.coupon_id = o.id
WHERE o.status = 'failed' AND o.created_at > now() - interval '78 days'
GROUP BY o.id, o.status;

CREATE TABLE IF NOT EXISTS cart_orders (
	id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	cart_id uuid NOT NULL REFERENCES carts (id) ON DELETE CASCADE,
	status text NOT NULL DEFAULT 'active',
	amount numeric(12, 3) NOT NULL,
	created_at timestamptz NOT NULL DEFAULT now()
);

SELECT o.id, o.status, sum(i.amount) AS total
FROM sessions o
	JOIN notifications i ON i.session_id = o.id
WHERE o.status = 'cancelled' AND o.created_at > now() - interval '89 days'
GROUP BY o.id, o.status;

CREATE INDEX IF NOT EXISTS discounts_marketplace_id_idx ON discounts (marketplace_id);

CREATE TABLE IF NOT EXISTS seller_offers (
	id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	seller_id uuid NOT NULL REFERENCES sellers (id) ON DELETE CASCADE,
	status text NOT NULL DEFAULT 'archived',
	amount numeric(12, 2) NOT NULL,
	created_at timestamptz NOT NULL DEFAULT now()
);

SELECT o.id, o.status, sum(i.amount) AS total
FROM accounts o
	JOIN variants i ON i.account_id = o.id
WHERE o.status = 'cancelled' AND o.created_at > now() - interval '49 days'
GROUP BY o.id, o.status;

CREATE TABLE IF NOT EXISTS offer_reviews (
	id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	offer_id uuid NOT NULL REFERENCES offers (id) ON DELETE CASCADE,
	status text NOT NULL DEFAULT 'active',
	amount numeric(12, 4) NOT NULL,
	created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS shipment_sessions (
	id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	shipment_id uuid NOT NULL REFERENCES shipments (id) ON DELETE CASCADE,
	status text NOT NULL DEFAULT 'delivered',
	amount numeric(12, 2) NOT NULL,
	created_at timestamptz NOT NULL DEFAULT now()
);

SELECT o.id, o.status, sum(i.amount) AS total
FROM orders o
	JOIN refunds i ON i.order_id = o.id
WHERE o.status = 'pending' AND o.created_at > now() - interval '3 days'
GROUP BY o.id, o.status;

CREATE INDEX IF NOT EXISTS reviews_owner_id_idx ON reviews (owner_id);

CREATE INDEX IF NOT EXISTS variants_created_at_idx ON variants (created_at);

CREATE TABLE IF NOT EXISTS label_sessions (
	id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	label_id uuid NOT NULL REFERENCES labels (id) ON DELETE CASCADE,
	status text NOT NULL DEFAULT 'active',
	amount numeric(12, 3) NOT NULL,
	created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS account_webhooks (
	id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	account_id uuid NOT NULL REFERENCES accounts (id) ON DELETE CASCADE,
	status text NOT NULL DEFAULT 'archived',
	amount numeric(12, 2) NOT NULL,
	created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS session_orders (
	id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	session_id uuid NOT NULL REFERENCES sessions (id) ON DELETE CASCADE,
	status text NOT NULL DEFAULT 'cancelled',
	amount numeric(12, 3) NOT NULL,
	created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS invoice_checkouts (
	id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	invoice_id uuid NOT NULL REFERENCES invoices (id) ON DELETE CASCADE,
	status text NOT NULL DEFAULT 'refunded',
	amount numeric(12, 3) NOT NULL,
	created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS thread_prices (
	id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	thread_id uuid NOT NULL REFERENCES threads (id) ON DELETE CASCADE,
	status text NOT NULL DEFAULT 'delivered',
	amount numeric(12, 4) NOT NULL,
	created_at timestamptz NOT NULL DEFAULT now()
);

SELECT o.id, o.status, sum(i.amount) AS total
FROM variants o
	JOIN streams i ON i.variant_id = o.id
WHERE o.status = 'pending' AND o.created_at > now() - interval '57 days'
GROUP BY o.id, o.status;

CREATE INDEX IF NOT EXISTS listings_status_idx ON listings (status);

CREATE INDEX IF NOT EXISTS products_owner_id_idx ON products (owner_id);

CREATE INDEX IF NOT EXISTS carts_created_at_idx ON carts (created_at);

CREATE TABLE IF NOT EXISTS product_sessions (
	id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	product_id uuid NOT NULL REFERENCES products (id) ON DELETE CASCADE,
	status text NOT NULL DEFAULT 'shipped',
	amount numeric(12, 4) NOT NULL,
	created_at timestamptz NOT NULL DEFAULT now()
);

SELECT o.id, o.status, sum(i.amount) AS total
FROM orders o
	JOIN shipments i ON i.order_id = o.id
WHERE o.status = 'cancelled' AND o.created_at > now() - interval '47 days'
GROUP BY o.id, o.status;

CREATE TABLE IF NOT EXISTS payout_tokens (
	id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	payout_id uuid NOT NULL REFERENCES payouts (id) ON DELETE CASCADE,
	status text NOT NULL DEFAULT 'refunded',
	amount numeric(12, 3) NOT NULL,
	created_at timestamptz NOT NULL DEFAULT now()
);

SELECT o.id, o.status, sum(i.amount) AS total
FROM webhooks o
	JOIN coupons i ON i.webhook_id = o.id
WHERE o.status = 'cancelled' AND o.created_at > now() - interval '79 days'
GROUP BY o.id, o.status;

SELECT o.id, o.status, sum(i.amount) AS total
FROM wallets o
	JOIN payments i ON i.wallet_id = o.id
WHERE o.status = 'refunded' AND o.created_at > now() - interval '62 days'
GROUP BY o.id, o.status;

CREATE TABLE IF NOT EXISTS listing_products (
	id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	listing_id uuid NOT NULL REFERENCES listings (id) ON DELETE CASCADE,
	status text NOT NULL DEFAULT 'active',
	amount numeric(12, 3) NOT NULL,
	created_at timestamptz NOT NULL DEFAULT now()
);

SELECT o.id, o.status, sum(i.amount) AS total
FROM tokens o
	JOIN sessions i ON i.token_id = o.id
WHERE o.status = 'archived' AND o.created_at > now() - interval '54 days'
GROUP BY o.id, o.status;

CREATE TABLE IF NOT EXISTS offer_accounts (
	id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	offer_id uuid NOT NULL REFERENCES offers (id) ON DELETE CASCADE,
	status text NOT NULL DEFAULT 'archived',
	amount numeric(12, 4) NOT NULL,
	created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS refunds_marketplace_id_idx ON refunds (marketplace_id);

CREATE INDEX IF NOT EXISTS accounts_status_idx ON accounts (status);

CREATE INDEX IF NOT EXISTS carts_created_at_idx ON carts (created_at);

CREATE TABLE IF NOT EXISTS coupon_accounts (
	id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	coupon_id uuid NOT NULL REFERENCES coupons (id) ON DELETE CASCADE,
	status text NOT NULL DEFAULT 'cancelled',
	amount numeric(12, 2) NOT NULL,
	created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS coupon_notifications (
	id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	coupon_id uuid NOT NULL REFERENCES coupons (id) ON DELETE CASCADE,
	status text NOT NULL DEFAULT 'delivered',
	amount numeric(12, 3) NOT NULL,
	created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS wallet_prices (
	id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	wallet_id uuid NOT NULL REFERENCES wallets (id) ON DELETE CASCADE,
	status text NOT NULL DEFAULT 'failed',
	amount numeric(12, 2) NOT NULL,
	created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS cart_accounts (
	id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	cart_id uuid NOT NULL REFERENCES carts (id) ON DELETE CASCADE,
	status text NOT NULL DEFAULT 'active',
	amount numeric(12, 3) NOT NULL,
	created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS seller_orders (
	id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	seller_id uuid NOT NULL REFERENCES sellers (id) ON DELETE CASCADE,
	status text NOT NULL DEFAULT 'archived',
	amount numeric(12, 3) NOT NULL,
	created_at timestamptz NOT NULL DEFAULT now()
);

SELECT o.id, o.status, sum(i.amount) AS total
FROM checkouts o
	JOIN orders i ON i.checkout_id = o.id
WHERE o.status = 'failed' AND o.created_at > now() - interval '36 days'
GROUP BY o.id, o.status;

CREATE INDEX IF NOT EXISTS webhooks_marketplace_id_idx ON webhooks (marketplace_id);

CREATE TABLE IF NOT EXISTS message_labels (
	id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	message_id uuid NOT NULL REFERENCES messages (id) ON DELETE CASCADE,
	status text NOT NULL DEFAULT 'shipped',
	amount numeric(12, 4) NOT NULL,
	created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS shipments_owner_id_idx ON shipments (owner_id);

CREATE INDEX IF NOT EXISTS tokens_marketplace_id_idx ON tokens (marketplace_id);

CREATE INDEX IF NOT EXISTS wallets_created_at_idx ON wallets (created_at);

SELECT o.id, o.status, sum(i.amount) AS total
FROM coupons o
	JOIN streams i ON i.coupon_id = o.id
WHERE o.status = 'shipped' AND o.created_at > now() - interval '89 days'
GROUP BY o.id, o.status;

CREATE TABLE IF NOT EXISTS shipment_variants (
	id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	shipment_id uuid NOT NULL REFERENCES shipments (id) ON DELETE CASCADE,
	status text NOT NULL DEFAULT 'failed',
	amount numeric(12, 2) NOT NULL,
	created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS wallets_marketplace_id_idx ON wallets (marketplace_id);

CREATE INDEX IF NOT EXISTS shipments_status_idx ON shipments (status);

CREATE TABLE IF NOT EXISTS checkout_sessions (
	id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	checkout_id uuid NOT NULL REFERENCES checkouts (id) ON DELETE CASCADE,
	status text NOT NULL DEFAULT 'shipped',
	amount numeric(12, 4) NOT NULL,
	created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS checkout_channels (
	id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	checkout_id uuid NOT NULL REFERENCES checkouts (id) ON DELETE CASCADE,
	status text NOT NULL DEFAULT 'delivered',
	amount numeric(12, 2) NOT NULL,
	created_at timestamptz NOT NULL DEFAULT now()
);

SELECT o.id, o.status, sum(i.amount) AS total
FROM refunds o
	JOIN listings i ON i.refund_id = o.id
WHERE o.status = 'failed' AND o.created_at > now() - interval '42 days'
GROUP BY o.id, o.status;

CREATE INDEX IF NOT EXISTS checkouts_status_idx ON checkouts (status);

CREATE TABLE IF NOT EXISTS thread_discounts (
	id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	thread_id uuid NOT NULL REFERENCES threads (id) ON DELETE CASCADE,
	status text NOT NULL DEFAULT 'delivered',
	amount numeric(12, 4) NOT NULL,
	created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS listing_messages (
	id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	listing_id uuid NOT NULL REFERENCES listings (id) ON DELETE CASCADE,
	status text NOT NULL DEFAULT 'delivered',
	amount numeric(12, 3) NOT NULL,
	created_at timestamptz NOT NULL DEFAULT now()
);

SELECT o.id, o.status, sum(i.amount) AS total
FROM wallets o
	JOIN products i ON i.wallet_id = o.id
WHERE o.status = 'archived' AND o.created_at > now() - interval '41 days'
GROUP BY o.id, o.status;

SELECT o.id, o.status, sum(i.amount) AS total
FROM accounts o
	JOIN prices i ON i.account_id = o.id
WHERE o.status = 'shipped' AND o.created_at > now() - interval '33 days'
GROUP BY o.id, o.status;

CREATE INDEX IF NOT EXISTS tokens_status_idx ON tokens (status);

CREATE INDEX IF NOT EXISTS payouts_marketplace_id_idx ON payouts (marketplace_id);

CREATE INDEX IF NOT EXISTS tokens_marketplace_id_idx ON tokens (marketplace_id);

CREATE TABLE IF NOT EXISTS payout_invoices (
	id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	payout_id uuid NOT NULL REFERENCES payouts (id) ON DELETE CASCADE,
	status text NOT NULL DEFAULT 'archived',
	amount numeric(12, 3) NOT NULL,
	created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS wallet_orders (
	id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	wallet_id uuid NOT NULL REFERENCES wallets (id) ON DELETE CASCADE,
	status text NOT NULL DEFAULT 'cancelled',
	amount numeric(12, 4) NOT NULL,
	created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS seller_sessions (
	id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	seller_id uuid NOT NULL REFERENCES sellers (id) ON DELETE CASCADE,
	status text NOT NULL DEFAULT 'archived',
	amount numeric(12, 2) NOT NULL,
	created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS listing_channels (
	id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	listing_id uuid NOT NULL REFERENCES listings (id) ON DELETE CASCADE,
	status text NOT NULL DEFAULT 'pending',
	amount numeric(12, 4) NOT NULL,
	created_at timestamptz NOT NULL DEFAULT now()
);

SELECT o.id, o.status, sum(i.amount) AS total
FROM webhooks o
	JOIN inventorys i ON i.webhook_id = o.id
WHERE o.status = 'cancelled' AND o.created_at > now() - interval '33 days'
GROUP BY o.id, o.status;

SELECT o.id, o.status, sum(i.amount) AS total
FROM carts o
	JOIN reviews i ON i.cart_id = o.id
WHERE o.status = 'delivered' AND o.created_at > now() - interval '23 days'
GROUP BY o.id, o.status;

SELECT o.id, o.status, sum(i.amount) AS total
FROM prices o
	JOIN payouts i ON i.price_id = o.id
WHERE o.status = 'pending' AND o.created_at > now() - interval '37 days'
GROUP BY o.id, o.status;

SELECT o.id, o.status, sum(i.amount) AS total
FROM inventorys o
	JOIN carts i ON i.inventory_id = o.id
WHERE o.status = 'active' AND o.created_at > now() - interval '15 days'
GROUP BY o.id, o.status;

SELECT o.id, o.status, sum(i.amount) AS total
FROM payouts o
	JOIN reviews i ON i.payout_id = o.id
WHERE o.status = 'refunded' AND o.created_at > now() - interval '62 days'
GROUP BY o.id, o.status;

CREATE TABLE IF NOT EXISTS label_orders (
	id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	label_id uuid NOT NULL REFERENCES labels (id) ON DELETE CASCADE,
	status text NOT NULL DEFAULT 'shipped',
	amount numeric(12, 4) NOT NULL,
	created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS shipments_created_at_idx ON shipments (created_at);

CREATE INDEX IF NOT EXISTS tokens_marketplace_id_idx ON tokens (marketplace_id);

SELECT o.id, o.status, sum(i.amount) AS total
FROM products o
	JOIN reviews i ON i.product_id = o.id
WHERE o.status = 'archived' AND o.created_at > now() - interval '19 days'
GROUP BY o.id, o.status;

CREATE TABLE IF NOT EXISTS account_prices (
	id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	account_id uuid NOT NULL REFERENCES accounts (id) ON DELETE CASCADE,
	status text NOT NULL DEFAULT 'pending',
	amount numeric(12, 4) NOT NULL,
	created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS product_threads (
	id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	product_id uuid NOT NULL REFERENCES products (id) ON DELETE CASCADE,
	status text NOT NULL DEFAULT 'pending',
	amount numeric(12, 3) NOT NULL,
	created_at timestamptz NOT NULL DEFAULT now()
);

SELECT o.id, o.status, sum(i.amount) AS total
FROM shipments o
	JOIN payments i ON i.shipment_id = o.id
WHERE o.status = 'delivered' AND o.created_at > now() - interval '79 days'
GROUP BY o.id, o.status;

CREATE INDEX IF NOT EXISTS buyers_status_idx ON buyers (status);

CREATE INDEX IF NOT EXISTS discounts_marketplace_id_idx ON discounts (marketplace_id);

CREATE INDEX IF NOT EXISTS listings_created_at_idx ON listings (created_at);

CREATE INDEX IF NOT EXISTS labels_created_at_idx ON labels (created_at);

CREATE INDEX IF NOT EXISTS tokens_created_at_idx ON tokens (created_at);

CREATE INDEX IF NOT EXISTS wallets_owner_id_idx ON wallets (owner_id);

SELECT o.id, o.status, sum(i.amount) AS total
FROM offers o
	JOIN products i ON i.offer_id = o.id
WHERE o.status = 'refunded' AND o.created_at > now() - interval '37 days'
GROUP BY o.id, o.status;

SELECT o.id, o.status, sum(i.amount) AS total
FROM labels o
	JOIN streams i ON i.label_id = o.id
WHERE o.status = 'failed' AND o.created_at > now() - interval '89 days'
GROUP BY o.id, o.status;

CREATE TABLE IF NOT EXISTS refund_messages (
	id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	refund_id uuid NOT NULL REFERENCES refunds (id) ON DELETE CASCADE,
	status text NOT NULL DEFAULT 'failed',
	amount numeric(12, 4) NOT NULL,
	created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS tokens_owner_id_idx ON tokens (owner_id);

CREATE INDEX IF NOT EXISTS sellers_created_at_idx ON sellers (created_at);

SELECT o.id, o.status, sum(i.amount) AS total
FROM wallets o
	JOIN prices i ON i.wallet_id = o.id
WHERE o.status = 'pending' AND o.created_at > now() - interval '49 days'
GROUP BY o.id, o.status;

CREATE TABLE IF NOT EXISTS payout_shipments (
	id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	payout_id uuid NOT NULL REFERENCES payouts (id) ON DELETE CASCADE,
	status text NOT NULL DEFAULT 'cancelled',
	amount numeric(12, 2) NOT NULL,
	created_at timestamptz NOT NULL DEFAULT now()
);

SELECT o.id, o.status, sum(i.amount) AS total
FROM variants o
	JOIN webhooks i ON i.variant_id = o.id
WHERE o.status = 'refunded' AND o.created_at > now() - interval '87 days'
GROUP BY o.id, o.status;

CREATE TABLE IF NOT EXISTS inventory_inventorys (
	id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	inventory_id uuid NOT NULL REFERENCES inventorys (id) ON DELETE CASCADE,
	status text NOT NULL DEFAULT 'delivered',
	amount numeric(12, 2) NOT NULL,
	created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS cart_listings (
	id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	cart_id uuid NOT NULL REFERENCES carts (id) ON DELETE CASCADE,
	status text NOT NULL DEFAULT 'pending',
	amount numeric(12, 4) NOT NULL,
	created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS labels_status_idx ON labels (status);

CREATE INDEX IF NOT EXISTS tokens_marketplace_id_idx ON tokens (marketplace_id);

CREATE INDEX IF NOT EXISTS listings_created_at_idx ON listings (created_at);

CREATE TABLE IF NOT EXISTS payout_messages (
	id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	payout_id uuid NOT NULL REFERENCES payouts (id) ON DELETE CASCADE,
	status text NOT NULL DEFAULT 'active',
	amount numeric(12, 2) NOT NULL,
	created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS payments_status_idx ON payments (status);

CREATE INDEX IF NOT EXISTS listings_marketplace_id_idx ON listings (marketplace_id);

CREATE INDEX IF NOT EXISTS orders_created_at_idx ON orders (created_at);

CREATE INDEX IF NOT EXISTS invoices_owner_id_idx ON invoices (owner_id);

CREATE TABLE IF NOT EXISTS wallet_messages (
	id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	wallet_id uuid NOT NULL REFERENCES wallets (id) ON DELETE CASCADE,
	status text NOT NULL DEFAULT 'shipped',
	amount numeric(12, 3) NOT NULL,
	created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS buyers_status_idx ON buyers (status);

CREATE TABLE IF NOT EXISTS discount_labels (
	id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	discount_id uuid NOT NULL REFERENCES discounts (id) ON DELETE CASCADE,
	status text NOT NULL DEFAULT 'pending',
	amount numeric(12, 3) NOT NULL,
	created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS message_products (
	id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	message_id uuid NOT NULL REFERENCES messages (id) ON DELETE CASCADE,
	status text NOT NULL DEFAULT 'active',
	amount numeric(12, 4) NOT NULL,
	created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS cart_checkouts (
	id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	cart_id uuid NOT NULL REFERENCES carts (id) ON DELETE CASCADE,
	status text NOT NULL DEFAULT 'refunded',
	amount numeric(12, 3) NOT NULL,
	created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS refund_listings (
	id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	refund_id uuid NOT NULL REFERENCES refunds (id) ON DELETE CASCADE,
	status text NOT NULL DEFAULT 'refunded',
	amount numeric(12, 3) NOT NULL,
	created_at timestamptz NOT NULL DEFAULT now()
);

SELECT o.id, o.status, sum(i.amount) AS total
FROM buyers o
	JOIN coupons i ON i.buyer_id = o.id
WHERE o.status = 'archived' AND o.created_at > now() - interval '4 days'
GROUP BY o.id, o.status;

SELECT o.id, o.status, sum(i.amount) AS total
FROM listings o
	JOIN sellers i ON i.listing_id = o.id
WHERE o.status = 'refunded' AND o.created_at > now() - interval '55 days'
GROUP BY o.id, o.status;

CREATE INDEX IF NOT EXISTS orders_created_at_idx ON orders (created_at);

SELECT o.id, o.status, sum(i.amount) AS total
FROM listings o
	JOIN offers i ON i.listing_id = o.id
WHERE o.status = 'cancelled' AND o.created_at > now() - interval '63 days'
GROUP BY o.id, o.status;

SELECT o.id, o.status, sum(i.amount) AS total
FROM invoices o
	JOIN inventorys i ON i.invoice_id = o.id
WHERE o.status = 'delivered' AND o.created_at > now() - interval '38 days'
GROUP BY o.id, o.status;

CREATE TABLE IF NOT EXISTS coupon_streams (
	id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	coupon_id uuid NOT NULL REFERENCES coupons (id) ON DELETE CASCADE,
	status text NOT NULL DEFAULT 'refunded',
	amount numeric(12, 4) NOT NULL,
	created_at timestamptz NOT NULL DEFAULT now()
);

SELECT o.id, o.status, sum(i.amount) AS total
FROM products o
	JOIN orders i ON i.product_id = o.id
WHERE o.status = 'cancelled' AND o.created_at > now() - interval '1 days'
GROUP BY o.id, o.status;

CREATE INDEX IF NOT EXISTS inventorys_created_at_idx ON inventorys (created_at);

CREATE TABLE IF NOT EXISTS buyer_offers (
	id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	buyer_id uuid NOT NULL REFERENCES buyers (id) ON DELETE CASCADE,
	status text NOT NULL DEFAULT 'cancelled',
	amount numeric(12, 4) NOT NULL,
	created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS coupon_channels (
	id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	coupon_id uuid NOT NULL REFERENCES coupons (id) ON DELETE CASCADE,
	status text NOT NULL DEFAULT 'cancelled',
	amount numeric(12, 3) NOT NULL,
	created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS carts_marketplace_id_idx ON carts (marketplace_id);

CREATE TABLE IF NOT EXISTS wallet_reviews (
	id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	wallet_id uuid NOT NULL REFERENCES wallets (id) ON DELETE CASCADE,
	status text NOT NULL DEFAULT 'active',
	amount numeric(12, 2) NOT NULL,
	created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS payouts_status_idx ON payouts (status);

SELECT o.id, o.status, sum(i.amount) AS total
FROM discounts o
	JOIN inventorys i ON i.discount_id = o.id
WHERE o.status = 'pending' AND o.created_at > now() - interval '38 days'
GROUP BY o.id, o.status;

SELECT o.id, o.status, sum(i.amount) AS total
FROM sellers o
	JOIN accounts i ON i.seller_id = o.id
WHERE o.status = 'archived' AND o.created_at > now() - interval '64 days'
GROUP BY o.id, o.status;

CREATE TABLE IF NOT EXISTS session_streams (
	id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	session_id uuid NOT NULL REFERENCES sessions (id) ON DELETE CASCADE,
	status text NOT NULL DEFAULT 'refunded',
	amount numeric(12, 4) NOT NULL,
	created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS labels_marketplace_id_idx ON labels (marketplace_id);

CREATE TABLE IF NOT EXISTS offer_notifications (
	id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	offer_id uuid NOT NULL REFERENCES offers (id) ON DELETE CASCADE,
	status text NOT NULL DEFAULT 'archived',
	amount numeric(12, 2) NOT NULL,
	created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS discounts_created_at_idx ON discounts (created_at);

CREATE INDEX IF NOT EXISTS discounts_owner_id_idx ON discounts (owner_id);

SELECT o.id, o.status, sum(i.amount) AS total
FROM webhooks o
	JOIN coupons i ON i.webhook_id = o.id
WHERE o.status = 'delivered' AND o.created_at > now() - interval '48 days'
GROUP BY o.id, o.status;

SELECT o.id, o.status, sum(i.amount) AS total
FROM buyers o
	JOIN accounts i ON i.buyer_id = o.id
WHERE o.status = 'archived' AND o.created_at > now() - interval '78 days'
GROUP BY o.id, o.status;

SELECT o.id, o.status, sum(i.amount) AS total
FROM webhooks o
	JOIN notifications i ON i.webhook_id = o.id
WHERE o.status = 'pending' AND o.created_at > now() - interval '64 days'
GROUP BY o.id, o.status;

SELECT o.id, o.status, sum(i.amount) AS total
FROM coupons o
	JOIN messages i ON i.coupon_id = o.id
WHERE o.status = 'shipped' AND o.created_at > now() - interval '86 days'
GROUP BY o.id, o.status;

CREATE TABLE IF NOT EXISTS product_sessions (
	id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	product_id uuid NOT NULL REFERENCES products (id) ON DELETE CASCADE,
	status text NOT NULL DEFAULT 'refunded',
	amount numeric(12, 3) NOT NULL,
	created_at timestamptz NOT NULL DEFAULT now()
);

SELECT o.id, o.status, sum(i.amount) AS total
FROM prices o
	JOIN buyers i ON i.price_id = o.id
WHERE o.status = 'shipped' AND o.created_at > now() - interval '42 days'
GROUP BY o.id, o.status;

CREATE TABLE IF NOT EXISTS review_messages (
	id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	review_id uuid NOT NULL REFERENCES reviews (id) ON DELETE CASCADE,
	status text NOT NULL DEFAULT 'active',
	amount numeric(12, 2) NOT NULL,
	created_at timestamptz NOT NULL DEFAULT now()
);

SELECT o.id, o.status, sum(i.amount) AS total
FROM offers o
	JOIN sellers i ON i.offer_id = o.id
WHERE o.status = 'refunded' AND o.created_at > now() - interval '1 days'
GROUP BY o.id, o.status;

CREATE TABLE IF NOT EXISTS refund_shipments (
	id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	refund_id uuid NOT NULL REFERENCES refunds (id) ON DELETE CASCADE,
	status text NOT NULL DEFAULT 'failed',
	amount numeric(12, 4) NOT NULL,
	created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS buyers_owner_id_idx ON buyers (owner_id);

CREATE TABLE IF NOT EXISTS message_checkouts (
	id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	message_id uuid NOT NULL REFERENCES messages (id) ON DELETE CASCADE,
	status text NOT NULL DEFAULT 'archived',
	amount numeric(12, 4) NOT NULL,
	created_at timestamptz NOT NULL DEFAULT now()
);

SELECT o.id, o.status, sum(i.amount) AS total
FROM discounts o
	JOIN offers i ON i.discount_id = o.id
WHERE o.status = 'pending' AND o.created_at > now() - interval '87 days'
GROUP BY o.id, o.status;

CREATE INDEX IF NOT EXISTS offers_status_idx ON offers (status);

CREATE INDEX IF NOT EXISTS wallets_status_idx ON wallets (status);

SELECT o.id, o.status, sum(i.amount) AS total
FROM notifications o
	JOIN variants i ON i.notification_id = o.id
WHERE o.status = 'cancelled' AND o.created_at > now() - interval '29 days'
GROUP BY o.id, o.status;

CREATE INDEX IF NOT EXISTS products_created_at_idx ON products (created_at);

CREATE TABLE IF NOT EXISTS label_labels (
	id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	label_id uuid NOT NULL REFERENCES labels (id) ON DELETE CASCADE,
	status text NOT NULL DEFAULT 'delivered',
	amount numeric(12, 3) NOT NULL,
	created_at timestamptz NOT NULL DEFAULT now()
);

SELECT o.id, o.status, sum(i.amount) AS total
FROM products o
	JOIN checkouts i ON i.product_id = o.id
WHERE o.status = 'cancelled' AND o.created_at > now() - interval '39 days'
GROUP BY o.id, o.status;

SELECT o.id, o.status, sum(i.amount) AS total
FROM listings o
	JOIN notifications i ON i.listing_id = o.id
WHERE o.status = 'pending' AND o.created_at > now() - interval '59 days'
GROUP BY o.id, o.status;

SELECT o.id, o.status, sum(i.amount) AS total
FROM messages o
	JOIN checkouts i ON i.message_id = o.id
WHERE o.status = 'delivered' AND o.created_at > now() - interval '61 days'
GROUP BY o.id, o.status;

CREATE TABLE IF NOT EXISTS invoice_threads (
	id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	invoice_id uuid NOT NULL REFERENCES invoices (id) ON DELETE CASCADE,
	status text NOT NULL DEFAULT 'delivered',
	amount numeric(12, 3) NOT NULL,
