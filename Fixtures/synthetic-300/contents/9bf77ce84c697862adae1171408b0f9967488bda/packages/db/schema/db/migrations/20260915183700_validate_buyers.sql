-- migrate:up

SELECT o.id, o.status, sum(i.amount) AS total
FROM inventorys o
	JOIN wallets i ON i.inventory_id = o.id
WHERE o.status = 'archived' AND o.created_at > now() - interval '12 days'
GROUP BY o.id, o.status;

CREATE TABLE IF NOT EXISTS wallet_tokens (
	id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	wallet_id uuid NOT NULL REFERENCES wallets (id) ON DELETE CASCADE,
	status text NOT NULL DEFAULT 'failed',
	amount numeric(12, 4) NOT NULL,
	created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS carts_marketplace_id_idx ON carts (marketplace_id);

SELECT o.id, o.status, sum(i.amount) AS total
FROM payments o
	JOIN labels i ON i.payment_id = o.id
WHERE o.status = 'archived' AND o.created_at > now() - interval '15 days'
GROUP BY o.id, o.status;

SELECT o.id, o.status, sum(i.amount) AS total
FROM prices o
	JOIN sessions i ON i.price_id = o.id
WHERE o.status = 'archived' AND o.created_at > now() - interval '15 days'
GROUP BY o.id, o.status;

SELECT o.id, o.status, sum(i.amount) AS total
FROM labels o
	JOIN payments i ON i.label_id = o.id
WHERE o.status = 'pending' AND o.created_at > now() - interval '25 days'
GROUP BY o.id, o.status;

CREATE INDEX IF NOT EXISTS products_marketplace_id_idx ON products (marketplace_id);

CREATE TABLE IF NOT EXISTS offer_sellers (
	id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	offer_id uuid NOT NULL REFERENCES offers (id) ON DELETE CASCADE,
	status text NOT NULL DEFAULT 'archived',
	amount numeric(12, 2) NOT NULL,
	created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS offer_tokens (
	id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	offer_id uuid NOT NULL REFERENCES offers (id) ON DELETE CASCADE,
	status text NOT NULL DEFAULT 'shipped',
	amount numeric(12, 4) NOT NULL,
	created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS channel_notifications (
	id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	channel_id uuid NOT NULL REFERENCES channels (id) ON DELETE CASCADE,
	status text NOT NULL DEFAULT 'delivered',
	amount numeric(12, 4) NOT NULL,
	created_at timestamptz NOT NULL DEFAULT now()
);

SELECT o.id, o.status, sum(i.amount) AS total
FROM listings o
	JOIN carts i ON i.listing_id = o.id
WHERE o.status = 'shipped' AND o.created_at > now() - interval '39 days'
GROUP BY o.id, o.status;

SELECT o.id, o.status, sum(i.amount) AS total
FROM tokens o
	JOIN buyers i ON i.token_id = o.id
WHERE o.status = 'cancelled' AND o.created_at > now() - interval '72 days'
GROUP BY o.id, o.status;

CREATE TABLE IF NOT EXISTS payout_refunds (
	id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	payout_id uuid NOT NULL REFERENCES payouts (id) ON DELETE CASCADE,
	status text NOT NULL DEFAULT 'pending',
	amount numeric(12, 3) NOT NULL,
	created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS session_reviews (
	id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	session_id uuid NOT NULL REFERENCES sessions (id) ON DELETE CASCADE,
	status text NOT NULL DEFAULT 'archived',
	amount numeric(12, 4) NOT NULL,
	created_at timestamptz NOT NULL DEFAULT now()
);

SELECT o.id, o.status, sum(i.amount) AS total
FROM accounts o
	JOIN variants i ON i.account_id = o.id
WHERE o.status = 'failed' AND o.created_at > now() - interval '22 days'
GROUP BY o.id, o.status;

SELECT o.id, o.status, sum(i.amount) AS total
FROM inventorys o
	JOIN streams i ON i.inventory_id = o.id
WHERE o.status = 'failed' AND o.created_at > now() - interval '84 days'
GROUP BY o.id, o.status;

CREATE TABLE IF NOT EXISTS payout_accounts (
	id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	payout_id uuid NOT NULL REFERENCES payouts (id) ON DELETE CASCADE,
	status text NOT NULL DEFAULT 'failed',
	amount numeric(12, 2) NOT NULL,
	created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS payout_payments (
	id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	payout_id uuid NOT NULL REFERENCES payouts (id) ON DELETE CASCADE,
	status text NOT NULL DEFAULT 'pending',
	amount numeric(12, 2) NOT NULL,
	created_at timestamptz NOT NULL DEFAULT now()
);

SELECT o.id, o.status, sum(i.amount) AS total
FROM payouts o
	JOIN variants i ON i.payout_id = o.id
WHERE o.status = 'shipped' AND o.created_at > now() - interval '35 days'
GROUP BY o.id, o.status;

CREATE INDEX IF NOT EXISTS accounts_status_idx ON accounts (status);

CREATE INDEX IF NOT EXISTS prices_marketplace_id_idx ON prices (marketplace_id);

CREATE TABLE IF NOT EXISTS seller_accounts (
	id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	seller_id uuid NOT NULL REFERENCES sellers (id) ON DELETE CASCADE,
	status text NOT NULL DEFAULT 'pending',
	amount numeric(12, 2) NOT NULL,
	created_at timestamptz NOT NULL DEFAULT now()
);

SELECT o.id, o.status, sum(i.amount) AS total
FROM sessions o
	JOIN buyers i ON i.session_id = o.id
WHERE o.status = 'active' AND o.created_at > now() - interval '90 days'
GROUP BY o.id, o.status;

CREATE TABLE IF NOT EXISTS inventory_streams (
	id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	inventory_id uuid NOT NULL REFERENCES inventorys (id) ON DELETE CASCADE,
	status text NOT NULL DEFAULT 'active',
	amount numeric(12, 4) NOT NULL,
	created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS tokens_status_idx ON tokens (status);

SELECT o.id, o.status, sum(i.amount) AS total
FROM payouts o
	JOIN variants i ON i.payout_id = o.id
WHERE o.status = 'shipped' AND o.created_at > now() - interval '74 days'
GROUP BY o.id, o.status;

SELECT o.id, o.status, sum(i.amount) AS total
FROM messages o
	JOIN orders i ON i.message_id = o.id
WHERE o.status = 'archived' AND o.created_at > now() - interval '50 days'
GROUP BY o.id, o.status;

SELECT o.id, o.status, sum(i.amount) AS total
FROM accounts o
	JOIN sessions i ON i.account_id = o.id
WHERE o.status = 'refunded' AND o.created_at > now() - interval '85 days'
GROUP BY o.id, o.status;

CREATE TABLE IF NOT EXISTS wallet_refunds (
	id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	wallet_id uuid NOT NULL REFERENCES wallets (id) ON DELETE CASCADE,
	status text NOT NULL DEFAULT 'cancelled',
	amount numeric(12, 2) NOT NULL,
	created_at timestamptz NOT NULL DEFAULT now()
);

SELECT o.id, o.status, sum(i.amount) AS total
FROM refunds o
	JOIN buyers i ON i.refund_id = o.id
WHERE o.status = 'cancelled' AND o.created_at > now() - interval '24 days'
GROUP BY o.id, o.status;

CREATE INDEX IF NOT EXISTS coupons_owner_id_idx ON coupons (owner_id);

CREATE TABLE IF NOT EXISTS thread_products (
	id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	thread_id uuid NOT NULL REFERENCES threads (id) ON DELETE CASCADE,
	status text NOT NULL DEFAULT 'shipped',
	amount numeric(12, 2) NOT NULL,
	created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS label_prices (
	id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	label_id uuid NOT NULL REFERENCES labels (id) ON DELETE CASCADE,
	status text NOT NULL DEFAULT 'shipped',
	amount numeric(12, 2) NOT NULL,
	created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS inventory_shipments (
	id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	inventory_id uuid NOT NULL REFERENCES inventorys (id) ON DELETE CASCADE,
	status text NOT NULL DEFAULT 'failed',
	amount numeric(12, 2) NOT NULL,
	created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS products_status_idx ON products (status);

CREATE TABLE IF NOT EXISTS message_payments (
	id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	message_id uuid NOT NULL REFERENCES messages (id) ON DELETE CASCADE,
	status text NOT NULL DEFAULT 'failed',
	amount numeric(12, 2) NOT NULL,
	created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS listings_status_idx ON listings (status);

SELECT o.id, o.status, sum(i.amount) AS total
FROM shipments o
	JOIN tokens i ON i.shipment_id = o.id
WHERE o.status = 'failed' AND o.created_at > now() - interval '41 days'
GROUP BY o.id, o.status;

CREATE TABLE IF NOT EXISTS seller_accounts (
	id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	seller_id uuid NOT NULL REFERENCES sellers (id) ON DELETE CASCADE,
	status text NOT NULL DEFAULT 'failed',
	amount numeric(12, 4) NOT NULL,
	created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS orders_marketplace_id_idx ON orders (marketplace_id);

CREATE TABLE IF NOT EXISTS token_carts (
	id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	token_id uuid NOT NULL REFERENCES tokens (id) ON DELETE CASCADE,
	status text NOT NULL DEFAULT 'cancelled',
	amount numeric(12, 2) NOT NULL,
	created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS invoices_created_at_idx ON invoices (created_at);

SELECT o.id, o.status, sum(i.amount) AS total
FROM buyers o
	JOIN prices i ON i.buyer_id = o.id
WHERE o.status = 'archived' AND o.created_at > now() - interval '60 days'
GROUP BY o.id, o.status;

SELECT o.id, o.status, sum(i.amount) AS total
FROM buyers o
	JOIN offers i ON i.buyer_id = o.id
WHERE o.status = 'delivered' AND o.created_at > now() - interval '8 days'
GROUP BY o.id, o.status;

SELECT o.id, o.status, sum(i.amount) AS total
FROM buyers o
	JOIN carts i ON i.buyer_id = o.id
WHERE o.status = 'refunded' AND o.created_at > now() - interval '72 days'
GROUP BY o.id, o.status;

CREATE INDEX IF NOT EXISTS carts_status_idx ON carts (status);

CREATE TABLE IF NOT EXISTS stream_labels (
	id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	stream_id uuid NOT NULL REFERENCES streams (id) ON DELETE CASCADE,
	status text NOT NULL DEFAULT 'active',
	amount numeric(12, 3) NOT NULL,
	created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS checkout_checkouts (
	id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	checkout_id uuid NOT NULL REFERENCES checkouts (id) ON DELETE CASCADE,
	status text NOT NULL DEFAULT 'archived',
	amount numeric(12, 2) NOT NULL,
	created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS offers_created_at_idx ON offers (created_at);

CREATE TABLE IF NOT EXISTS account_notifications (
	id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	account_id uuid NOT NULL REFERENCES accounts (id) ON DELETE CASCADE,
	status text NOT NULL DEFAULT 'archived',
	amount numeric(12, 4) NOT NULL,
	created_at timestamptz NOT NULL DEFAULT now()
);

SELECT o.id, o.status, sum(i.amount) AS total
FROM payouts o
	JOIN channels i ON i.payout_id = o.id
WHERE o.status = 'shipped' AND o.created_at > now() - interval '82 days'
GROUP BY o.id, o.status;

SELECT o.id, o.status, sum(i.amount) AS total
FROM accounts o
	JOIN channels i ON i.account_id = o.id
WHERE o.status = 'pending' AND o.created_at > now() - interval '57 days'
GROUP BY o.id, o.status;

SELECT o.id, o.status, sum(i.amount) AS total
FROM carts o
	JOIN buyers i ON i.cart_id = o.id
WHERE o.status = 'shipped' AND o.created_at > now() - interval '25 days'
GROUP BY o.id, o.status;

CREATE TABLE IF NOT EXISTS webhook_tokens (
	id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	webhook_id uuid NOT NULL REFERENCES webhooks (id) ON DELETE CASCADE,
	status text NOT NULL DEFAULT 'refunded',
	amount numeric(12, 3) NOT NULL,
	created_at timestamptz NOT NULL DEFAULT now()
);

SELECT o.id, o.status, sum(i.amount) AS total
FROM variants o
	JOIN products i ON i.variant_id = o.id
WHERE o.status = 'refunded' AND o.created_at > now() - interval '69 days'
GROUP BY o.id, o.status;

CREATE INDEX IF NOT EXISTS prices_status_idx ON prices (status);

CREATE TABLE IF NOT EXISTS offer_inventorys (
	id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	offer_id uuid NOT NULL REFERENCES offers (id) ON DELETE CASCADE,
	status text NOT NULL DEFAULT 'refunded',
