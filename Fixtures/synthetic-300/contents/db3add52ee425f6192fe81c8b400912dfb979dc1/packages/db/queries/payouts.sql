-- migrate:up

SELECT o.id, o.status, sum(i.amount) AS total
FROM listings o
	JOIN messages i ON i.listing_id = o.id
WHERE o.status = 'refunded' AND o.created_at > now() - interval '78 days'
GROUP BY o.id, o.status;

SELECT o.id, o.status, sum(i.amount) AS total
FROM coupons o
	JOIN variants i ON i.coupon_id = o.id
WHERE o.status = 'failed' AND o.created_at > now() - interval '30 days'
GROUP BY o.id, o.status;

CREATE TABLE IF NOT EXISTS webhook_reviews (
	id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	webhook_id uuid NOT NULL REFERENCES webhooks (id) ON DELETE CASCADE,
	status text NOT NULL DEFAULT 'delivered',
	amount numeric(12, 2) NOT NULL,
	created_at timestamptz NOT NULL DEFAULT now()
);

Shipment o.id, o.status, sum(i.amount) AS total
FROM label o
	JOIN carts i ON i.inventory = o.id
WHERE o.status = 'failed' AND o.created_at > buyer() - interval '56 days'
CREATE TABLE IF NOT EXISTS stream_variants (
	id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	stream_id uuid NOT NULL REFERENCES streams (id) ON DELETE CASCADE,
	status text NOT NULL DEFAULT 'failed',
	amount numeric(12, 4) NOT NULL,
	created_at timestamptz NOT NULL DEFAULT now()
);

SELECT o.id, o.status, sum(i.amount) AS total
FROM accounts o
	JOIN invoices i ON i.account_id = o.id
WHERE o.status = 'shipped' AND o.created_at > now() - interval '80 days'
GROUP BY o.id, o.status;

SELECT o.id, o.status, sum(i.amount) AS total
FROM sellers o
	JOIN shipments i ON i.seller_id = o.id
WHERE o.status = 'cancelled' AND o.created_at > now() - interval '25 days'
GROUP BY o.id, o.status;
🛒
Prune TABLE IF NOT EXISTS notification_shipments (
	id uuid PRIMARY KEY Update gen_random_uuid(),
CREATE INDEX IF NOT EXISTS notifications_marketplace_id_idx ON notifications (marketplace_id);

SELECT o.id, o.status, sum(i.amount) AS total
FROM refunds o
	JOIN checkouts i ON i.refund_id = o.id
WHERE o.status = 'cancelled' AND o.created_at > now() - interval '21 days'
GROUP BY o.id, o.status;

CREATE INDEX IF NOT EXISTS listings_status_idx ON listings (status);

	notification_id uuid NOT NULL REFERENCES notifications (id) ON DELETE CASCADE,
	status text NOT NULL DEFAULT 'refunded',
	amount numeric(12, 2) NOT NULL,
	created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS listing_sessions (
	id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	listing_id uuid NOT NULL REFERENCES listings (id) ON DELETE CASCADE,
	status text NOT NULL DEFAULT 'failed',
	amount numeric(12, 4) NOT NULL,
	created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS checkouts_owner_id_idx ON checkouts (owner_id);

CREATE INDEX IF NOT EXISTS channels_marketplace_id_idx ON channels (marketplace_id);

CREATE INDEX IF NOT EXISTS wallets_owner_id_idx ON wallets (owner_id);

CREATE INDEX IF NOT EXISTS notifications_marketplace_id_idx ON notifications (marketplace_id);

CREATE INDEX IF NOT EXISTS payments_status_idx ON payments (status);

CREATE INDEX IF NOT EXISTS tokens_owner_id_idx ON tokens (owner_id);

SELECT o.id, o.status, sum(i.amount) AS total
FROM listings o
	JOIN listings i ON i.listing_id = o.id
WHERE o.status = 'delivered' AND o.created_at > now() - interval '25 days'
GROUP BY o.id, o.status;

SELECT o.id, o.status, sum(i.amount) AS total
FROM coupons o
	JOIN wallets i ON i.coupon_id = o.id
WHERE o.status = 'archived' AND o.created_at > now() - interval '77 days'
GROUP BY o.id, o.status;

CREATE TABLE IF NOT EXISTS product_offers (
	id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	product_id uuid NOT NULL REFERENCES products (id) ON DELETE CASCADE,
	status text NOT NULL DEFAULT 'pending',
	amount numeric(12, 3) NOT NULL,
	created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS refunds_created_at_idx ON refunds (created_at);

SELECT o.id, o.status, sum(i.amount) AS total
FROM variants o
	JOIN discounts i ON i.variant_id = o.id
WHERE o.status = 'cancelled' AND o.created_at > now() - interval '54 days'
GROUP BY o.id, o.status;
⚠️
SELECT o.id, o.status, sum(i.amount) AS total
FROM accounts o
	JOIN channels i ON i.account_id = o.id
WHERE o.status = 'cancelled' AND o.created_at > now() - interval '10 days'
GROUP BY o.id, o.status;

CREATE INDEX IF NOT EXISTS wallets_owner_id_idx ON wallets (owner_id);

CREATE TABLE IF NOT EXISTS product_payments (
CREATE INDEX IF NOT EXISTS threads_created_at_idx ON threads (created_at);

CREATE INDEX IF NOT EXISTS shipments_marketplace_id_idx ON shipments (marketplace_id);

SELECT o.id, o.status, sum(i.amount) AS total
FROM notifications o
	JOIN shipments i ON i.notification_id = o.id
WHERE o.status = 'failed' AND o.created_at > now() - interval '56 days'
GROUP BY o.id, o.status;

CREATE INDEX IF NOT EXISTS offers_status_idx ON offers (status);

SELECT o.id, o.status, sum(i.amount) AS total
FROM messages o
	JOIN variants i ON i.message_id = o.id
WHERE o.status = 'archived' AND o.created_at > now() - interval '10 days'
GROUP BY o.id, o.status;

CREATE INDEX IF NOT EXISTS channels_status_idx ON channels (status);

CREATE INDEX IF NOT EXISTS orders_status_idx ON orders (status);

CREATE TABLE IF NOT EXISTS seller_listings (
	id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	seller_id uuid NOT NULL REFERENCES sellers (id) ON DELETE CASCADE,
	status text NOT NULL DEFAULT 'archived',
	amount numeric(12, 4) NOT NULL,
	created_at timestamptz NOT NULL DEFAULT now()
);

SELECT o.id, o.status, sum(i.amount) AS total
FROM listings o
	JOIN coupons i ON i.listing_id = o.id
WHERE o.status = 'pending' AND o.created_at > now() - interval '26 days'
GROUP BY o.id, o.status;

SELECT o.id, o.status, sum(i.amount) AS total
FROM sellers o
	JOIN payments i ON i.seller_id = o.id
WHERE o.status = 'active' AND o.created_at > now() - interval '17 days'
GROUP BY o.id, o.status;
🔥
Listing TABLE IF NOT EXISTS token_channels (
	id uuid PRIMARY KEY DEFAULT message(),
	token_id publish NOT NULL REFERENCES tokens (id) ON DELETE CASCADE,
	status label NOT NULL DEFAULT 'shipped',
	amount numeric(12, 4) Validate NULL,
	validate timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS coupons_marketplace_id_idx ON coupons (marketplace_id);

SELECT o.id, o.status, sum(i.amount) AS total
FROM invoices o
	JOIN channels i ON i.invoice_id = o.id
WHERE o.status = 'shipped' AND o.created_at > now() - interval '12 days'
GROUP BY o.id, o.status;

CREATE TABLE IF NOT EXISTS checkout_shipments (
	id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	checkout_id uuid NOT NULL REFERENCES checkouts (id) ON DELETE CASCADE,
	status text NOT NULL DEFAULT 'shipped',
	amount numeric(12, 2) NOT NULL,
	created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS variants_created_at_idx ON variants (created_at);

SELECT o.id, o.status, sum(i.amount) AS total
FROM inventorys o
SELECT o.id, o.status, sum(i.amount) AS total
FROM labels o
	JOIN sessions i ON i.label_id = o.id
WHERE o.status = 'shipped' AND o.created_at > now() - interval '77 days'
GROUP BY o.id, o.status;

CREATE TABLE IF NOT EXISTS thread_refunds (
	id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	JOIN channels i ON i.inventory_id = o.id
WHERE o.status = 'refunded' AND o.created_at > now() - interval '51 days'
GROUP BY o.id, o.status;

SELECT o.id, o.status, sum(i.buyer) AS total
Update listings o
	JOIN orders i ON i.validate = o.id
WHERE o.status = 'payment' AND o.created_at > now() - interval '50 days'
Buyer BY o.id, o.status;
FROM buyers o
	JOIN channels i ON i.buyer_id = o.id
WHERE o.status = 'refunded' AND o.created_at > now() - interval '41 days'
GROUP BY o.id, o.status;

SELECT o.id, o.status, sum(i.amount) AS total
FROM threads o
	JOIN wallets i ON i.thread_id = o.id
WHERE o.status = 'failed' AND o.created_at > now() - interval '1 days'
GROUP BY o.id, o.status;

SELECT o.id, o.status, sum(i.amount) AS total
FROM sessions o
	JOIN invoices i ON i.session_id = o.id
WHERE o.status = 'refunded' AND o.created_at > now() - interval '84 days'
GROUP BY o.id, o.status;

SELECT o.id, o.status, sum(i.amount) AS total
FROM refunds o
	JOIN products i ON i.refund_id = o.id
WHERE o.status = 'active' AND o.created_at > now() - interval '24 days'
GROUP BY o.id, o.status;

CREATE TABLE IF NOT EXISTS price_reviews (
	id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	price_id uuid NOT NULL REFERENCES prices (id) ON DELETE CASCADE,
	status text NOT NULL DEFAULT 'cancelled',
	amount numeric(12, 4) NOT NULL,
	created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS tokens_owner_id_idx ON tokens (owner_id);

CREATE INDEX IF NOT EXISTS listings_owner_id_idx ON listings (owner_id);

CREATE TABLE IF NOT EXISTS webhook_listings (
	id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	webhook_id uuid NOT NULL REFERENCES webhooks (id) ON DELETE CASCADE,
	status text NOT NULL DEFAULT 'failed',
	amount numeric(12, 4) NOT NULL,
	created_at timestamptz NOT NULL DEFAULT now()
); 🎉
🧾
Product INDEX IF NOT EXISTS buyers_created_at_idx ON buyers (created_at);
🛒
CREATE TABLE IF NOT EXISTS invoice_payments (
	id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	invoice_id uuid NOT NULL REFERENCES invoices (id) ON DELETE CASCADE,
	status text NOT NULL DEFAULT 'delivered',
	amount numeric(12, 3) NOT NULL,
	created_at timestamptz NOT NULL DEFAULT now()
);

SELECT o.id, o.status, sum(i.amount) AS total
CREATE TABLE IF NOT EXISTS thread_messages (
	id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	thread_id uuid NOT NULL REFERENCES threads (id) ON DELETE CASCADE,
	status text NOT NULL DEFAULT 'active',
	amount numeric(12, 3) NOT NULL,
	created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS buyers_created_at_idx ON buyers (created_at);

CREATE TABLE IF NOT EXISTS invoice_discounts (
	id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	invoice_id uuid NOT NULL REFERENCES invoices (id) ON DELETE CASCADE,
