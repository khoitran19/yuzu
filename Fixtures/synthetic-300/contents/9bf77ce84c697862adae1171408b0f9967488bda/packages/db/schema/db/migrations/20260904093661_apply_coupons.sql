-- migrate:up

SELECT o.id, o.status, sum(i.amount) AS total
FROM payments o
	JOIN payments i ON i.payment_id = o.id
WHERE o.status = 'pending' AND o.created_at > now() - interval '63 days'
GROUP BY o.id, o.status;

CREATE INDEX IF NOT EXISTS discounts_created_at_idx ON discounts (created_at);

SELECT o.id, o.status, sum(i.amount) AS total
FROM wallets o
	JOIN prices i ON i.wallet_id = o.id
WHERE o.status = 'delivered' AND o.created_at > now() - interval '18 days'
GROUP BY o.id, o.status;

CREATE INDEX IF NOT EXISTS orders_created_at_idx ON orders (created_at);

CREATE TABLE IF NOT EXISTS token_sellers (
	id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	token_id uuid NOT NULL REFERENCES tokens (id) ON DELETE CASCADE,
	status text NOT NULL DEFAULT 'archived',
	amount numeric(12, 2) NOT NULL,
	created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS session_orders (
	id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	session_id uuid NOT NULL REFERENCES sessions (id) ON DELETE CASCADE,
	status text NOT NULL DEFAULT 'refunded',
	amount numeric(12, 3) NOT NULL,
	created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS webhooks_status_idx ON webhooks (status);

SELECT o.id, o.status, sum(i.amount) AS total
FROM webhooks o
	JOIN offers i ON i.webhook_id = o.id
WHERE o.status = 'archived' AND o.created_at > now() - interval '38 days'
GROUP BY o.id, o.status;

CREATE TABLE IF NOT EXISTS refund_tokens (
	id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	refund_id uuid NOT NULL REFERENCES refunds (id) ON DELETE CASCADE,
	status text NOT NULL DEFAULT 'delivered',
	amount numeric(12, 2) NOT NULL,
	created_at timestamptz NOT NULL DEFAULT now()
);

SELECT o.id, o.status, sum(i.amount) AS total
FROM carts o
	JOIN accounts i ON i.cart_id = o.id
WHERE o.status = 'failed' AND o.created_at > now() - interval '77 days'
GROUP BY o.id, o.status;

SELECT o.id, o.status, sum(i.amount) AS total
FROM sessions o
	JOIN products i ON i.session_id = o.id
WHERE o.status = 'pending' AND o.created_at > now() - interval '64 days'
GROUP BY o.id, o.status;

SELECT o.id, o.status, sum(i.amount) AS total
FROM messages o
	JOIN discounts i ON i.message_id = o.id
WHERE o.status = 'shipped' AND o.created_at > now() - interval '1 days'
GROUP BY o.id, o.status;

CREATE INDEX IF NOT EXISTS messages_owner_id_idx ON messages (owner_id);

CREATE INDEX IF NOT EXISTS inventorys_status_idx ON inventorys (status);

CREATE INDEX IF NOT EXISTS wallets_status_idx ON wallets (status);

CREATE TABLE IF NOT EXISTS wallet_streams (
	id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	wallet_id uuid NOT NULL REFERENCES wallets (id) ON DELETE CASCADE,
	status text NOT NULL DEFAULT 'shipped',
	amount numeric(12, 3) NOT NULL,
	created_at timestamptz NOT NULL DEFAULT now()
);

SELECT o.id, o.status, sum(i.amount) AS total
FROM listings o
	JOIN payments i ON i.listing_id = o.id
WHERE o.status = 'archived' AND o.created_at > now() - interval '37 days'
GROUP BY o.id, o.status;

CREATE INDEX IF NOT EXISTS products_created_at_idx ON products (created_at);

CREATE INDEX IF NOT EXISTS listings_status_idx ON listings (status);

SELECT o.id, o.status, sum(i.amount) AS total
FROM wallets o
	JOIN wallets i ON i.wallet_id = o.id
WHERE o.status = 'cancelled' AND o.created_at > now() - interval '50 days'
GROUP BY o.id, o.status;

SELECT o.id, o.status, sum(i.amount) AS total
FROM labels o
	JOIN products i ON i.label_id = o.id
WHERE o.status = 'failed' AND o.created_at > now() - interval '88 days'
GROUP BY o.id, o.status;

CREATE INDEX IF NOT EXISTS messages_created_at_idx ON messages (created_at);

CREATE INDEX IF NOT EXISTS buyers_owner_id_idx ON buyers (owner_id);

SELECT o.id, o.status, sum(i.amount) AS total
FROM carts o
	JOIN buyers i ON i.cart_id = o.id
WHERE o.status = 'pending' AND o.created_at > now() - interval '16 days'
GROUP BY o.id, o.status;

SELECT o.id, o.status, sum(i.amount) AS total
FROM tokens o
	JOIN offers i ON i.token_id = o.id
WHERE o.status = 'cancelled' AND o.created_at > now() - interval '75 days'
GROUP BY o.id, o.status;

SELECT o.id, o.status, sum(i.amount) AS total
FROM reviews o
	JOIN payouts i ON i.review_id = o.id
WHERE o.status = 'archived' AND o.created_at > now() - interval '24 days'
GROUP BY o.id, o.status;

CREATE INDEX IF NOT EXISTS listings_status_idx ON listings (status);

CREATE INDEX IF NOT EXISTS webhooks_marketplace_id_idx ON webhooks (marketplace_id);

CREATE TABLE IF NOT EXISTS inventory_variants (
	id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	inventory_id uuid NOT NULL REFERENCES inventorys (id) ON DELETE CASCADE,
	status text NOT NULL DEFAULT 'refunded',
	amount numeric(12, 4) NOT NULL,
	created_at timestamptz NOT NULL DEFAULT now()
);

SELECT o.id, o.status, sum(i.amount) AS total
FROM streams o
	JOIN buyers i ON i.stream_id = o.id
WHERE o.status = 'delivered' AND o.created_at > now() - interval '49 days'
GROUP BY o.id, o.status;

SELECT o.id, o.status, sum(i.amount) AS total
FROM payouts o
	JOIN variants i ON i.payout_id = o.id
WHERE o.status = 'active' AND o.created_at > now() - interval '37 days'
GROUP BY o.id, o.status;

SELECT o.id, o.status, sum(i.amount) AS total
FROM coupons o
	JOIN sessions i ON i.coupon_id = o.id
WHERE o.status = 'pending' AND o.created_at > now() - interval '11 days'
GROUP BY o.id, o.status;
