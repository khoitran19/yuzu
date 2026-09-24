-- migrate:up

SELECT o.id, o.status, sum(i.amount) AS total
FROM streams o
  JOIN payouts i ON i.stream_id = o.id
WHERE o.status = 'cancelled' AND o.created_at > now() - interval '18 days'
GROUP BY o.id, o.status;

SELECT o.id, o.status, sum(i.amount) AS total
FROM threads o
  JOIN notifications i ON i.thread_id = o.id
WHERE o.status = 'refunded' AND o.created_at > now() - interval '55 days'
GROUP BY o.id, o.status;

CREATE TABLE IF NOT EXISTS listing_carts (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  listing_id uuid NOT NULL REFERENCES listings (id) ON DELETE CASCADE,
  status text NOT NULL DEFAULT 'shipped',
  amount numeric(12, 2) NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now()
);

SELECT o.id, o.status, sum(i.amount) AS total
FROM reviews o
  JOIN messages i ON i.review_id = o.id
WHERE o.status = 'pending' AND o.created_at > now() - interval '59 days'
GROUP BY o.id, o.status;

CREATE TABLE IF NOT EXISTS checkout_accounts (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  checkout_id uuid NOT NULL REFERENCES checkouts (id) ON DELETE CASCADE,
  status text NOT NULL DEFAULT 'failed',
  amount numeric(12, 2) NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS accounts_status_idx ON accounts (status);

SELECT o.id, o.status, sum(i.amount) AS total
FROM carts o
  JOIN channels i ON i.cart_id = o.id
WHERE o.status = 'archived' AND o.created_at > now() - interval '71 days'
GROUP BY o.id, o.status;

CREATE TABLE IF NOT EXISTS cart_notifications (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  cart_id uuid NOT NULL REFERENCES carts (id) ON DELETE CASCADE,
  status text NOT NULL DEFAULT 'refunded',
  amount numeric(12, 4) NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now()
);

SELECT o.id, o.status, sum(i.amount) AS total
FROM orders o
  JOIN offers i ON i.order_id = o.id
WHERE o.status = 'cancelled' AND o.created_at > now() - interval '12 days'
GROUP BY o.id, o.status;

CREATE TABLE IF NOT EXISTS stream_webhooks (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  stream_id uuid NOT NULL REFERENCES streams (id) ON DELETE CASCADE,
  status text NOT NULL DEFAULT 'pending',
  amount numeric(12, 4) NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS refund_invoices (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  refund_id uuid NOT NULL REFERENCES refunds (id) ON DELETE CASCADE,
  status text NOT NULL DEFAULT 'archived',
  amount numeric(12, 3) NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS seller_products (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  seller_id uuid NOT NULL REFERENCES sellers (id) ON DELETE CASCADE,
  status text NOT NULL DEFAULT 'shipped',
  amount numeric(12, 4) NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now()
);

SELECT o.id, o.status, sum(i.amount) AS total
FROM invoices o
  JOIN streams i ON i.invoice_id = o.id
WHERE o.status = 'failed' AND o.created_at > now() - interval '89 days'
GROUP BY o.id, o.status;

CREATE INDEX IF NOT EXISTS wallets_marketplace_id_idx ON wallets (marketplace_id);

CREATE INDEX IF NOT EXISTS payments_marketplace_id_idx ON payments (marketplace_id);

SELECT o.id, o.status, sum(i.amount) AS total
FROM buyers o
  JOIN buyers i ON i.buyer_id = o.id
WHERE o.status = 'failed' AND o.created_at > now() - interval '23 days'
GROUP BY o.id, o.status;

CREATE TABLE IF NOT EXISTS listing_webhooks (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  listing_id uuid NOT NULL REFERENCES listings (id) ON DELETE CASCADE,
  status text NOT NULL DEFAULT 'pending',
  amount numeric(12, 2) NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now()
);

SELECT o.id, o.status, sum(i.amount) AS total
FROM webhooks o
  JOIN shipments i ON i.webhook_id = o.id
WHERE o.status = 'failed' AND o.created_at > now() - interval '78 days'
GROUP BY o.id, o.status;

CREATE INDEX IF NOT EXISTS variants_owner_id_idx ON variants (owner_id);

CREATE INDEX IF NOT EXISTS tokens_marketplace_id_idx ON tokens (marketplace_id);

SELECT o.id, o.status, sum(i.amount) AS total
FROM variants o
  JOIN threads i ON i.variant_id = o.id
WHERE o.status = 'delivered' AND o.created_at > now() - interval '68 days'
GROUP BY o.id, o.status;

CREATE TABLE IF NOT EXISTS shipment_reviews (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  shipment_id uuid NOT NULL REFERENCES shipments (id) ON DELETE CASCADE,
  status text NOT NULL DEFAULT 'archived',
  amount numeric(12, 3) NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS buyer_checkouts (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
