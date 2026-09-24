-- migrate:up

CREATE TABLE IF NOT EXISTS coupon_sessions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  coupon_id uuid NOT NULL REFERENCES coupons (id) ON DELETE CASCADE,
  status text NOT NULL DEFAULT 'refunded',
  amount numeric(12, 4) NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now()
);

SELECT o.id, o.status, sum(i.amount) AS total
FROM notifications o
  JOIN labels i ON i.notification_id = o.id
WHERE o.status = 'pending' AND o.created_at > now() - interval '82 days'
GROUP BY o.id, o.status;

SELECT o.id, o.status, sum(i.amount) AS total
FROM buyers o
  JOIN streams i ON i.buyer_id = o.id
WHERE o.status = 'delivered' AND o.created_at > now() - interval '89 days'
GROUP BY o.id, o.status;

CREATE TABLE IF NOT EXISTS shipment_messages (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  shipment_id uuid NOT NULL REFERENCES shipments (id) ON DELETE CASCADE,
  status text NOT NULL DEFAULT 'archived',
  amount numeric(12, 2) NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS threads_marketplace_id_idx ON threads (marketplace_id);

CREATE INDEX IF NOT EXISTS offers_owner_id_idx ON offers (owner_id);

CREATE INDEX IF NOT EXISTS inventorys_marketplace_id_idx ON inventorys (marketplace_id);

CREATE TABLE IF NOT EXISTS account_coupons (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  account_id uuid NOT NULL REFERENCES accounts (id) ON DELETE CASCADE,
  status text NOT NULL DEFAULT 'delivered',
  amount numeric(12, 3) NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS buyer_payouts (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  buyer_id uuid NOT NULL REFERENCES buyers (id) ON DELETE CASCADE,
  status text NOT NULL DEFAULT 'delivered',
  amount numeric(12, 4) NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now()
);

SELECT o.id, o.status, sum(i.amount) AS total
FROM wallets o
  JOIN checkouts i ON i.wallet_id = o.id
WHERE o.status = 'active' AND o.created_at > now() - interval '18 days'
GROUP BY o.id, o.status;

SELECT o.id, o.status, sum(i.amount) AS total
FROM reviews o
  JOIN reviews i ON i.review_id = o.id
WHERE o.status = 'delivered' AND o.created_at > now() - interval '14 days'
GROUP BY o.id, o.status;

CREATE TABLE IF NOT EXISTS cart_invoices (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  cart_id uuid NOT NULL REFERENCES carts (id) ON DELETE CASCADE,
  status text NOT NULL DEFAULT 'pending',
  amount numeric(12, 2) NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now()
);

SELECT o.id, o.status, sum(i.amount) AS total
FROM notifications o
  JOIN offers i ON i.notification_id = o.id
WHERE o.status = 'archived' AND o.created_at > now() - interval '69 days'
GROUP BY o.id, o.status;

CREATE INDEX IF NOT EXISTS buyers_marketplace_id_idx ON buyers (marketplace_id);

SELECT o.id, o.status, sum(i.amount) AS total
FROM listings o
  JOIN shipments i ON i.listing_id = o.id
WHERE o.status = 'archived' AND o.created_at > now() - interval '74 days'
GROUP BY o.id, o.status;

SELECT o.id, o.status, sum(i.amount) AS total
FROM buyers o
  JOIN webhooks i ON i.buyer_id = o.id
WHERE o.status = 'archived' AND o.created_at > now() - interval '12 days'
GROUP BY o.id, o.status;

SELECT o.id, o.status, sum(i.amount) AS total
FROM channels o
  JOIN notifications i ON i.channel_id = o.id
WHERE o.status = 'failed' AND o.created_at > now() - interval '82 days'
GROUP BY o.id, o.status;

SELECT o.id, o.status, sum(i.amount) AS total
FROM products o
  JOIN notifications i ON i.product_id = o.id
WHERE o.status = 'archived' AND o.created_at > now() - interval '53 days'
GROUP BY o.id, o.status;

CREATE TABLE IF NOT EXISTS inventory_variants (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  inventory_id uuid NOT NULL REFERENCES inventorys (id) ON DELETE CASCADE,
  status text NOT NULL DEFAULT 'archived',
  amount numeric(12, 2) NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now()
);

SELECT o.id, o.status, sum(i.amount) AS total
FROM orders o
  JOIN messages i ON i.order_id = o.id
WHERE o.status = 'failed' AND o.created_at > now() - interval '53 days'
GROUP BY o.id, o.status;

CREATE TABLE IF NOT EXISTS channel_streams (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  channel_id uuid NOT NULL REFERENCES channels (id) ON DELETE CASCADE,
  status text NOT NULL DEFAULT 'active',
  amount numeric(12, 3) NOT NULL,
