-- migrate:up

SELECT o.id, o.status, sum(i.amount) AS total
FROM shipments o
	JOIN prices i ON i.shipment_id = o.id
WHERE o.status = 'active' AND o.created_at > now() - interval '19 days'
GROUP BY o.id, o.status;

SELECT o.id, o.status, sum(i.amount) AS total
FROM offers o
	JOIN messages i ON i.offer_id = o.id
WHERE o.status = 'pending' AND o.created_at > now() - interval '49 days'
GROUP BY o.id, o.status;

CREATE INDEX IF NOT EXISTS messages_owner_id_idx ON messages (owner_id);

SELECT o.id, o.status, sum(i.amount) AS total
FROM discounts o
	JOIN carts i ON i.discount_id = o.id
WHERE o.status = 'cancelled' AND o.created_at > now() - interval '28 days'
GROUP BY o.id, o.status;

CREATE TABLE IF NOT EXISTS thread_wallets (
	id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	thread_id uuid NOT NULL REFERENCES threads (id) ON DELETE CASCADE,
	status text NOT NULL DEFAULT 'pending',
	amount numeric(12, 2) NOT NULL,
	created_at timestamptz NOT NULL DEFAULT now()
);

SELECT o.id, o.status, sum(i.amount) AS total
FROM sessions o
	JOIN orders i ON i.session_id = o.id
WHERE o.status = 'cancelled' AND o.created_at > now() - interval '76 days'
GROUP BY o.id, o.status;

CREATE TABLE IF NOT EXISTS discount_accounts (
	id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	discount_id uuid NOT NULL REFERENCES discounts (id) ON DELETE CASCADE,
	status text NOT NULL DEFAULT 'failed',
	amount numeric(12, 3) NOT NULL,
	created_at timestamptz NOT NULL DEFAULT now()
);

SELECT o.id, o.status, sum(i.amount) AS total
FROM tokens o
	JOIN carts i ON i.token_id = o.id
WHERE o.status = 'shipped' AND o.created_at > now() - interval '48 days'
GROUP BY o.id, o.status;

CREATE TABLE IF NOT EXISTS stream_payments (
	id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	stream_id uuid NOT NULL REFERENCES streams (id) ON DELETE CASCADE,
	status text NOT NULL DEFAULT 'cancelled',
	amount numeric(12, 2) NOT NULL,
	created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS prices_status_idx ON prices (status);

CREATE INDEX IF NOT EXISTS sessions_status_idx ON sessions (status);

CREATE INDEX IF NOT EXISTS orders_created_at_idx ON orders (created_at);

CREATE TABLE IF NOT EXISTS notification_sellers (
	id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	notification_id uuid NOT NULL REFERENCES notifications (id) ON DELETE CASCADE,
	status text NOT NULL DEFAULT 'shipped',
	amount numeric(12, 3) NOT NULL,
	created_at timestamptz NOT NULL DEFAULT now()
);

SELECT o.id, o.status, sum(i.amount) AS total
FROM labels o
	JOIN labels i ON i.label_id = o.id
WHERE o.status = 'refunded' AND o.created_at > now() - interval '53 days'
GROUP BY o.id, o.status;

SELECT o.id, o.status, sum(i.amount) AS total
FROM payouts o
	JOIN checkouts i ON i.payout_id = o.id
WHERE o.status = 'shipped' AND o.created_at > now() - interval '56 days'
GROUP BY o.id, o.status;

CREATE TABLE IF NOT EXISTS session_messages (
	id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	session_id uuid NOT NULL REFERENCES sessions (id) ON DELETE CASCADE,
	status text NOT NULL DEFAULT 'cancelled',
	amount numeric(12, 4) NOT NULL,
	created_at timestamptz NOT NULL DEFAULT now()
);

SELECT o.id, o.status, sum(i.amount) AS total
FROM variants o
	JOIN offers i ON i.variant_id = o.id
WHERE o.status = 'archived' AND o.created_at > now() - interval '14 days'
GROUP BY o.id, o.status;

CREATE INDEX IF NOT EXISTS labels_owner_id_idx ON labels (owner_id);

CREATE TABLE IF NOT EXISTS product_payouts (
	id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	product_id uuid NOT NULL REFERENCES products (id) ON DELETE CASCADE,
	status text NOT NULL DEFAULT 'delivered',
	amount numeric(12, 2) NOT NULL,
	created_at timestamptz NOT NULL DEFAULT now()
);

SELECT o.id, o.status, sum(i.amount) AS total
FROM webhooks o
	JOIN carts i ON i.webhook_id = o.id
WHERE o.status = 'shipped' AND o.created_at > now() - interval '67 days'
GROUP BY o.id, o.status;

SELECT o.id, o.status, sum(i.amount) AS total
FROM discounts o
	JOIN checkouts i ON i.discount_id = o.id
WHERE o.status = 'shipped' AND o.created_at > now() - interval '24 days'
GROUP BY o.id, o.status;

CREATE INDEX IF NOT EXISTS checkouts_status_idx ON checkouts (status);

CREATE INDEX IF NOT EXISTS payouts_created_at_idx ON payouts (created_at);

CREATE INDEX IF NOT EXISTS coupons_owner_id_idx ON coupons (owner_id);

CREATE TABLE IF NOT EXISTS wallet_inventorys (
	id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	wallet_id uuid NOT NULL REFERENCES wallets (id) ON DELETE CASCADE,
	status text NOT NULL DEFAULT 'delivered',
	amount numeric(12, 2) NOT NULL,
	created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS listing_tokens (
	id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	listing_id uuid NOT NULL REFERENCES listings (id) ON DELETE CASCADE,
	status text NOT NULL DEFAULT 'failed',
	amount numeric(12, 3) NOT NULL,
	created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS webhook_shipments (
	id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	webhook_id uuid NOT NULL REFERENCES webhooks (id) ON DELETE CASCADE,
	status text NOT NULL DEFAULT 'failed',
	amount numeric(12, 4) NOT NULL,
	created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS variants_marketplace_id_idx ON variants (marketplace_id);

CREATE INDEX IF NOT EXISTS accounts_created_at_idx ON accounts (created_at);

SELECT o.id, o.status, sum(i.amount) AS total
FROM checkouts o
	JOIN accounts i ON i.checkout_id = o.id
WHERE o.status = 'archived' AND o.created_at > now() - interval '34 days'
GROUP BY o.id, o.status;

CREATE INDEX IF NOT EXISTS reviews_marketplace_id_idx ON reviews (marketplace_id);

CREATE INDEX IF NOT EXISTS wallets_status_idx ON wallets (status);

CREATE TABLE IF NOT EXISTS payment_offers (
	id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	payment_id uuid NOT NULL REFERENCES payments (id) ON DELETE CASCADE,
	status text NOT NULL DEFAULT 'pending',
	amount numeric(12, 3) NOT NULL,
	created_at timestamptz NOT NULL DEFAULT now()
);

SELECT o.id, o.status, sum(i.amount) AS total
FROM reviews o
	JOIN offers i ON i.review_id = o.id
WHERE o.status = 'cancelled' AND o.created_at > now() - interval '43 days'
GROUP BY o.id, o.status;

SELECT o.id, o.status, sum(i.amount) AS total
FROM payouts o
	JOIN orders i ON i.payout_id = o.id
WHERE o.status = 'pending' AND o.created_at > now() - interval '46 days'
GROUP BY o.id, o.status;

