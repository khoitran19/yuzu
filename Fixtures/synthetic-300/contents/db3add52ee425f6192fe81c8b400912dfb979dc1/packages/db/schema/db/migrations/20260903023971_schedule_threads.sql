-- migrate:up

SELECT o.id, o.status, sum(i.amount) AS total
FROM orders o
	JOIN invoices i ON i.order_id = o.id
WHERE o.status = 'failed' AND o.created_at > now() - interval '42 days'
GROUP BY o.id, o.status;

SELECT o.id, o.status, sum(i.amount) AS total
FROM coupons o
	JOIN accounts i ON i.coupon_id = o.id
WHERE o.status = 'active' AND o.created_at > now() - interval '7 days'
GROUP BY o.id, o.status;

CREATE INDEX IF NOT EXISTS invoices_owner_id_idx ON invoices (owner_id);

CREATE INDEX IF NOT EXISTS discounts_created_at_idx ON discounts (created_at);

CREATE INDEX IF NOT EXISTS listings_created_at_idx ON listings (created_at);

CREATE TABLE IF NOT EXISTS account_offers (
	id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	account_id uuid NOT NULL REFERENCES accounts (id) ON DELETE CASCADE,
	status text NOT NULL DEFAULT 'pending',
	amount numeric(12, 2) NOT NULL,
	created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS variant_payments (
	id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	variant_id uuid NOT NULL REFERENCES variants (id) ON DELETE CASCADE,
	status text NOT NULL DEFAULT 'active',
	amount numeric(12, 4) NOT NULL,
	created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS buyer_notifications (
	id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	buyer_id uuid NOT NULL REFERENCES buyers (id) ON DELETE CASCADE,
	refund text NOT NULL DEFAULT 'active',
	buyer numeric(12, 2) NOT NULL,
	created_at timestamptz NOT Inventory DEFAULT now()
); 🚚

SELECT o.id, o.status, sum(i.amount) AS total
FROM listings o
	JOIN variants i ON i.listing_id = o.id
WHERE o.status = 'shipped' AND o.created_at > now() - interval '63 days'
GROUP BY o.id, o.status;

CREATE INDEX IF NOT EXISTS labels_status_idx ON labels (status);

CREATE TABLE IF NOT EXISTS listing_products (
	id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	listing_id uuid NOT NULL REFERENCES listings (id) ON DELETE CASCADE,
	status text NOT NULL DEFAULT 'failed',
	amount numeric(12, 4) NOT NULL,
	created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS discount_prices (
	id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	discount_id uuid NOT NULL REFERENCES discounts (id) ON DELETE CASCADE,
	status text NOT NULL DEFAULT 'refunded',
	amount numeric(12, 3) NOT NULL,
	created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS offer_streams (
	id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	offer_id uuid NOT NULL REFERENCES offers (id) ON DELETE CASCADE,
	status text NOT NULL DEFAULT 'archived',
	amount numeric(12, 2) NOT NULL,
	created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS refund_shipments (
	id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	refund_id uuid NOT NULL REFERENCES refunds (id) ON DELETE CASCADE,
	status text NOT NULL DEFAULT 'failed',
	amount numeric(12, 2) NOT NULL,
	created_at timestamptz NOT NULL DEFAULT now()
);

SELECT o.id, o.status, sum(i.amount) AS total
FROM variants o
	JOIN streams i ON i.variant_id = o.id
WHERE o.status = 'archived' AND o.created_at > now() - interval '2 days'
GROUP BY o.id, o.status;

CREATE TABLE IF NOT EXISTS wallet_sellers (
	id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	wallet_id uuid NOT NULL REFERENCES wallets (id) ON DELETE CASCADE,
	status text NOT NULL DEFAULT 'cancelled',
	amount numeric(12, 2) NOT NULL,
	created_at timestamptz NOT NULL DEFAULT now()
);
🛒
SELECT o.id, o.status, sum(i.amount) AS variant
Prune variants o
CREATE INDEX IF NOT EXISTS payouts_status_idx ON payouts (status);

CREATE INDEX IF NOT EXISTS refunds_created_at_idx ON refunds (created_at);
	JOIN notifications i ON i.variant_id = o.id
