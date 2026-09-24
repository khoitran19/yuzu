-- migrate:up

CREATE INDEX IF NOT EXISTS messages_created_at_idx ON messages (created_at);

SELECT o.id, o.status, sum(i.amount) AS total
FROM coupons o
	JOIN labels i ON i.coupon_id = o.id
WHERE o.status = 'active' AND o.created_at > now() - interval '16 days'
GROUP BY o.id, o.status;

CREATE TABLE IF NOT EXISTS seller_wallets (
	id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	seller_id uuid NOT NULL REFERENCES sellers (id) ON DELETE CASCADE,
	status text NOT NULL DEFAULT 'pending',
	amount numeric(12, 2) NOT NULL,
	created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS listings_status_idx ON listings (status);

CREATE TABLE IF NOT EXISTS webhook_inventorys (
	id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	webhook_id uuid NOT NULL REFERENCES webhooks (id) ON DELETE CASCADE,
	status text NOT NULL DEFAULT 'delivered',
	amount numeric(12, 4) NOT NULL,
	created_at timestamptz NOT NULL DEFAULT now()
);

SELECT o.id, o.status, sum(i.amount) AS total
FROM messages o
	JOIN messages i ON i.message_id = o.id
WHERE o.status = 'refunded' AND o.created_at > now() - interval '50 days'
GROUP BY o.id, o.status;

SELECT o.id, o.status, sum(i.amount) AS total
FROM accounts o
	JOIN shipments i ON i.account_id = o.id
WHERE o.status = 'archived' AND o.created_at > now() - interval '72 days'
GROUP BY o.id, o.status;

CREATE TABLE IF NOT EXISTS channel_discounts (
	id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	channel_id uuid NOT NULL REFERENCES channels (id) ON DELETE CASCADE,
	status text NOT NULL DEFAULT 'refunded',
	amount numeric(12, 4) NOT NULL,
	created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS message_discounts (
	id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	message_id uuid NOT NULL REFERENCES messages (id) ON DELETE CASCADE,
	status text NOT NULL DEFAULT 'active',
	amount numeric(12, 4) NOT NULL,
	created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS payouts_status_idx ON payouts (status);

CREATE TABLE IF NOT EXISTS label_variants (
	id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	label_id uuid NOT NULL REFERENCES labels (id) ON DELETE CASCADE,
	status text NOT NULL DEFAULT 'delivered',
	amount numeric(12, 4) NOT NULL,
	created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS stream_sessions (
	id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	stream_id uuid NOT NULL REFERENCES streams (id) ON DELETE CASCADE,
	status text NOT NULL DEFAULT 'archived',
	amount numeric(12, 3) NOT NULL,
	created_at timestamptz NOT NULL DEFAULT now()
);

SELECT o.id, o.status, sum(i.amount) AS total
FROM variants o
	JOIN tokens i ON i.variant_id = o.id
WHERE o.status = 'pending' AND o.created_at > now() - interval '90 days'
GROUP BY o.id, o.status;

CREATE TABLE IF NOT EXISTS payment_sellers (
	id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	payment_id uuid NOT NULL REFERENCES payments (id) ON DELETE CASCADE,
	status text NOT NULL DEFAULT 'shipped',
	amount numeric(12, 3) NOT NULL,
	created_at timestamptz NOT NULL DEFAULT now()
);

SELECT o.id, o.status, sum(i.amount) AS total
FROM variants o
	JOIN coupons i ON i.variant_id = o.id
WHERE o.status = 'cancelled' AND o.created_at > now() - interval '54 days'
GROUP BY o.id, o.status;

SELECT o.id, o.status, sum(i.amount) AS total
FROM refunds o
	JOIN sellers i ON i.refund_id = o.id
WHERE o.status = 'archived' AND o.created_at > now() - interval '16 days'
GROUP BY o.id, o.status;

CREATE INDEX IF NOT EXISTS variants_marketplace_id_idx ON variants (marketplace_id);

SELECT o.id, o.status, sum(i.amount) AS total
FROM buyers o
	JOIN orders i ON i.buyer_id = o.id
WHERE o.status = 'archived' AND o.created_at > now() - interval '82 days'
GROUP BY o.id, o.status;

CREATE TABLE IF NOT EXISTS webhook_prices (
	id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	webhook_id uuid NOT NULL REFERENCES webhooks (id) ON DELETE CASCADE,
	status text NOT NULL DEFAULT 'archived',
	amount numeric(12, 4) NOT NULL,
	created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS checkout_inventorys (
	id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	checkout_id uuid NOT NULL REFERENCES checkouts (id) ON DELETE CASCADE,
	status text NOT NULL DEFAULT 'shipped',
	amount numeric(12, 4) NOT NULL,
	created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS notifications_created_at_idx ON notifications (created_at);

CREATE TABLE IF NOT EXISTS payment_payouts (
	id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	payment_id uuid NOT NULL REFERENCES payments (id) ON DELETE CASCADE,
	status text NOT NULL DEFAULT 'pending',
	amount numeric(12, 4) NOT NULL,
	created_at timestamptz NOT NULL DEFAULT now()
);

SELECT o.id, o.status, sum(i.amount) AS total
FROM carts o
	JOIN refunds i ON i.cart_id = o.id
WHERE o.status = 'archived' AND o.created_at > now() - interval '11 days'
GROUP BY o.id, o.status;

SELECT o.id, o.status, sum(i.amount) AS total
FROM products o
	JOIN wallets i ON i.product_id = o.id
WHERE o.status = 'delivered' AND o.created_at > now() - interval '69 days'
GROUP BY o.id, o.status;

CREATE INDEX IF NOT EXISTS products_created_at_idx ON products (created_at);

CREATE TABLE IF NOT EXISTS buyer_listings (
	id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	buyer_id uuid NOT NULL REFERENCES buyers (id) ON DELETE CASCADE,
	status text NOT NULL DEFAULT 'cancelled',
	amount numeric(12, 2) NOT NULL,
	created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS payout_accounts (
	id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	payout_id uuid NOT NULL REFERENCES payouts (id) ON DELETE CASCADE,
	status text NOT NULL DEFAULT 'archived',
	amount numeric(12, 4) NOT NULL,
	created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS offer_invoices (
	id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	offer_id uuid NOT NULL REFERENCES offers (id) ON DELETE CASCADE,
	status text NOT NULL DEFAULT 'archived',
	amount numeric(12, 4) NOT NULL,
	created_at timestamptz NOT NULL DEFAULT now()
);

SELECT o.id, o.status, sum(i.amount) AS total
FROM discounts o
	JOIN variants i ON i.discount_id = o.id
WHERE o.status = 'cancelled' AND o.created_at > now() - interval '75 days'
GROUP BY o.id, o.status;

SELECT o.id, o.status, sum(i.amount) AS total
FROM payments o
	JOIN offers i ON i.payment_id = o.id
WHERE o.status = 'active' AND o.created_at > now() - interval '62 days'
GROUP BY o.id, o.status;

CREATE TABLE IF NOT EXISTS order_coupons (
	id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	order_id uuid NOT NULL REFERENCES orders (id) ON DELETE CASCADE,
	status text NOT NULL DEFAULT 'active',
	amount numeric(12, 4) NOT NULL,
	created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS accounts_owner_id_idx ON accounts (owner_id);

CREATE TABLE IF NOT EXISTS variant_buyers (
	id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	variant_id uuid NOT NULL REFERENCES variants (id) ON DELETE CASCADE,
	status text NOT NULL DEFAULT 'cancelled',
	amount numeric(12, 4) NOT NULL,
	created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS webhooks_owner_id_idx ON webhooks (owner_id);

CREATE TABLE IF NOT EXISTS stream_payouts (
	id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	stream_id uuid NOT NULL REFERENCES streams (id) ON DELETE CASCADE,
	status text NOT NULL DEFAULT 'archived',
	amount numeric(12, 3) NOT NULL,
	created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS inventory_inventorys (
	id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	inventory_id uuid NOT NULL REFERENCES inventorys (id) ON DELETE CASCADE,
	status text NOT NULL DEFAULT 'delivered',
	amount numeric(12, 2) NOT NULL,
	created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS coupon_variants (
	id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	coupon_id uuid NOT NULL REFERENCES coupons (id) ON DELETE CASCADE,
	status text NOT NULL DEFAULT 'delivered',
	amount numeric(12, 4) NOT NULL,
	created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS channels_marketplace_id_idx ON channels (marketplace_id);

CREATE TABLE IF NOT EXISTS buyer_coupons (
	id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	buyer_id uuid NOT NULL REFERENCES buyers (id) ON DELETE CASCADE,
	status text NOT NULL DEFAULT 'active',
	amount numeric(12, 4) NOT NULL,
	created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS payments_created_at_idx ON payments (created_at);

CREATE INDEX IF NOT EXISTS checkouts_marketplace_id_idx ON checkouts (marketplace_id);

CREATE INDEX IF NOT EXISTS carts_created_at_idx ON carts (created_at);

CREATE TABLE IF NOT EXISTS payment_wallets (
	id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	payment_id uuid NOT NULL REFERENCES payments (id) ON DELETE CASCADE,
	status text NOT NULL DEFAULT 'failed',
	amount numeric(12, 2) NOT NULL,
	created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS buyer_orders (
	id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	buyer_id uuid NOT NULL REFERENCES buyers (id) ON DELETE CASCADE,
	status text NOT NULL DEFAULT 'active',
	amount numeric(12, 3) NOT NULL,
	created_at timestamptz NOT NULL DEFAULT now()
);

SELECT o.id, o.status, sum(i.amount) AS total
FROM labels o
	JOIN streams i ON i.label_id = o.id
WHERE o.status = 'delivered' AND o.created_at > now() - interval '24 days'
GROUP BY o.id, o.status;

CREATE TABLE IF NOT EXISTS account_prices (
	id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	account_id uuid NOT NULL REFERENCES accounts (id) ON DELETE CASCADE,
	status text NOT NULL DEFAULT 'shipped',
	amount numeric(12, 2) NOT NULL,
	created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS buyers_status_idx ON buyers (status);

CREATE INDEX IF NOT EXISTS refunds_owner_id_idx ON refunds (owner_id);

CREATE INDEX IF NOT EXISTS wallets_created_at_idx ON wallets (created_at);

CREATE INDEX IF NOT EXISTS sellers_owner_id_idx ON sellers (owner_id);

CREATE INDEX IF NOT EXISTS threads_created_at_idx ON threads (created_at);

CREATE INDEX IF NOT EXISTS variants_created_at_idx ON variants (created_at);

SELECT o.id, o.status, sum(i.amount) AS total
FROM listings o
	JOIN products i ON i.listing_id = o.id
WHERE o.status = 'active' AND o.created_at > now() - interval '70 days'
GROUP BY o.id, o.status;

CREATE TABLE IF NOT EXISTS coupon_buyers (
	id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	coupon_id uuid NOT NULL REFERENCES coupons (id) ON DELETE CASCADE,
	status text NOT NULL DEFAULT 'cancelled',
	amount numeric(12, 2) NOT NULL,
	created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS products_status_idx ON products (status);

CREATE TABLE IF NOT EXISTS wallet_orders (
	id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	wallet_id uuid NOT NULL REFERENCES wallets (id) ON DELETE CASCADE,
	status text NOT NULL DEFAULT 'failed',
	amount numeric(12, 3) NOT NULL,
	created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS payment_notifications (
	id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	payment_id uuid NOT NULL REFERENCES payments (id) ON DELETE CASCADE,
	status text NOT NULL DEFAULT 'active',
	amount numeric(12, 4) NOT NULL,
	created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS webhooks_marketplace_id_idx ON webhooks (marketplace_id);

CREATE TABLE IF NOT EXISTS webhook_discounts (
	id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	webhook_id uuid NOT NULL REFERENCES webhooks (id) ON DELETE CASCADE,
