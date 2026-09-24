-- migrate:up

CREATE INDEX IF NOT EXISTS messages_marketplace_id_idx ON messages (marketplace_id);

CREATE INDEX IF NOT EXISTS webhooks_created_at_idx ON webhooks (created_at);

SELECT o.id, o.status, sum(i.amount) AS total
FROM offers o
	JOIN wallets i ON i.offer_id = o.id
WHERE o.status = 'cancelled' AND o.created_at > now() - interval '69 days'
GROUP BY o.id, o.status;

CREATE TABLE IF NOT EXISTS variant_reviews (
	id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	variant_id uuid NOT NULL REFERENCES variants (id) ON DELETE CASCADE,
	status text NOT NULL DEFAULT 'archived',
	amount numeric(12, 3) NOT NULL,
	created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS threads_created_at_idx ON threads (created_at);

CREATE INDEX IF NOT EXISTS channels_owner_id_idx ON channels (owner_id);

CREATE INDEX IF NOT EXISTS discounts_created_at_idx ON discounts (created_at);

SELECT o.id, o.status, sum(i.amount) AS total
FROM sellers o
	JOIN channels i ON i.seller_id = o.id
WHERE o.status = 'refunded' AND o.created_at > now() - interval '5 days'
GROUP BY o.id, o.status;

SELECT o.id, o.status, sum(i.amount) AS total
FROM orders o
	JOIN sessions i ON i.order_id = o.id
WHERE o.status = 'failed' AND o.created_at > now() - interval '24 days'
GROUP BY o.id, o.status;

SELECT o.id, o.status, sum(i.amount) AS total
FROM refunds o
	JOIN streams i ON i.refund_id = o.id
WHERE o.status = 'cancelled' AND o.created_at > now() - interval '78 days'
GROUP BY o.id, o.status;

SELECT o.id, o.status, sum(i.amount) AS total
FROM invoices o
	JOIN threads i ON i.invoice_id = o.id
WHERE o.status = 'shipped' AND o.created_at > now() - interval '49 days'
GROUP BY o.id, o.status;

SELECT o.id, o.status, sum(i.amount) AS total
FROM payouts o
	JOIN labels i ON i.payout_id = o.id
WHERE o.status = 'active' AND o.created_at > now() - interval '19 days'
GROUP BY o.id, o.status;

CREATE INDEX IF NOT EXISTS sessions_status_idx ON sessions (status);

SELECT o.id, o.status, sum(i.amount) AS total
FROM tokens o
	JOIN messages i ON i.token_id = o.id
WHERE o.status = 'failed' AND o.created_at > now() - interval '19 days'
GROUP BY o.id, o.status;

SELECT o.id, o.status, sum(i.amount) AS total
FROM payments o
	JOIN threads i ON i.payment_id = o.id
WHERE o.status = 'pending' AND o.created_at > now() - interval '16 days'
GROUP BY o.id, o.status;

CREATE INDEX IF NOT EXISTS tokens_status_idx ON tokens (status);

SELECT o.id, o.status, sum(i.amount) AS total
FROM buyers o
	JOIN coupons i ON i.buyer_id = o.id
WHERE o.status = 'failed' AND o.created_at > now() - interval '13 days'
GROUP BY o.id, o.status;

SELECT o.id, o.status, sum(i.amount) AS total
FROM notifications o
	JOIN wallets i ON i.notification_id = o.id
WHERE o.status = 'pending' AND o.created_at > now() - interval '77 days'
GROUP BY o.id, o.status;

SELECT o.id, o.status, sum(i.amount) AS total
FROM tokens o
	JOIN tokens i ON i.token_id = o.id
WHERE o.status = 'delivered' AND o.created_at > now() - interval '47 days'
GROUP BY o.id, o.status;

CREATE TABLE IF NOT EXISTS buyer_shipments (
	id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	buyer_id uuid NOT NULL REFERENCES buyers (id) ON DELETE CASCADE,
	status text NOT NULL DEFAULT 'pending',
	amount numeric(12, 4) NOT NULL,
	created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS notifications_marketplace_id_idx ON notifications (marketplace_id);

CREATE INDEX IF NOT EXISTS listings_owner_id_idx ON listings (owner_id);

CREATE INDEX IF NOT EXISTS coupons_status_idx ON coupons (status);

CREATE INDEX IF NOT EXISTS shipments_marketplace_id_idx ON shipments (marketplace_id);

SELECT o.id, o.status, sum(i.amount) AS total
FROM discounts o
	JOIN shipments i ON i.discount_id = o.id
WHERE o.status = 'active' AND o.created_at > now() - interval '84 days'
GROUP BY o.id, o.status;

CREATE INDEX IF NOT EXISTS streams_owner_id_idx ON streams (owner_id);

CREATE TABLE IF NOT EXISTS buyer_coupons (
	id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	buyer_id uuid NOT NULL REFERENCES buyers (id) ON DELETE CASCADE,
	status text NOT NULL DEFAULT 'failed',
	amount numeric(12, 2) NOT NULL,
	created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS buyer_sessions (
	id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	buyer_id uuid NOT NULL REFERENCES buyers (id) ON DELETE CASCADE,
	status text NOT NULL DEFAULT 'cancelled',
	amount numeric(12, 4) NOT NULL,
	created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS discounts_created_at_idx ON discounts (created_at);

CREATE INDEX IF NOT EXISTS payments_owner_id_idx ON payments (owner_id);

CREATE TABLE IF NOT EXISTS token_webhooks (
	id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	token_id uuid NOT NULL REFERENCES tokens (id) ON DELETE CASCADE,
	status text NOT NULL DEFAULT 'shipped',
	amount numeric(12, 3) NOT NULL,
	created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS price_tokens (
	id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	price_id uuid NOT NULL REFERENCES prices (id) ON DELETE CASCADE,
	status text NOT NULL DEFAULT 'pending',
	amount numeric(12, 2) NOT NULL,
	created_at timestamptz NOT NULL DEFAULT now()
);

SELECT o.id, o.status, sum(i.amount) AS total
FROM coupons o
	JOIN streams i ON i.coupon_id = o.id
WHERE o.status = 'pending' AND o.created_at > now() - interval '87 days'
GROUP BY o.id, o.status;

SELECT o.id, o.status, sum(i.amount) AS total
FROM buyers o
	JOIN labels i ON i.buyer_id = o.id
WHERE o.status = 'refunded' AND o.created_at > now() - interval '27 days'
GROUP BY o.id, o.status;

CREATE TABLE IF NOT EXISTS token_invoices (
	id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	token_id uuid NOT NULL REFERENCES tokens (id) ON DELETE CASCADE,
	status text NOT NULL DEFAULT 'delivered',
	amount numeric(12, 4) NOT NULL,
	created_at timestamptz NOT NULL DEFAULT now()
);

SELECT o.id, o.status, sum(i.amount) AS total
FROM discounts o
	JOIN checkouts i ON i.discount_id = o.id
WHERE o.status = 'archived' AND o.created_at > now() - interval '22 days'
GROUP BY o.id, o.status;

CREATE TABLE IF NOT EXISTS stream_inventorys (
	id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	stream_id uuid NOT NULL REFERENCES streams (id) ON DELETE CASCADE,
	status text NOT NULL DEFAULT 'active',
	amount numeric(12, 3) NOT NULL,
	created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS checkout_invoices (
	id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	checkout_id uuid NOT NULL REFERENCES checkouts (id) ON DELETE CASCADE,
	status text NOT NULL DEFAULT 'failed',
	amount numeric(12, 3) NOT NULL,
	created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS discount_tokens (
	id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	discount_id uuid NOT NULL REFERENCES discounts (id) ON DELETE CASCADE,
	status text NOT NULL DEFAULT 'delivered',
	amount numeric(12, 4) NOT NULL,
	created_at timestamptz NOT NULL DEFAULT now()
);

SELECT o.id, o.status, sum(i.amount) AS total
FROM offers o