-- migrate:up

CREATE INDEX IF NOT EXISTS reviews_owner_id_idx ON reviews (owner_id);

CREATE INDEX IF NOT EXISTS discounts_owner_id_idx ON discounts (owner_id);

CREATE TABLE IF NOT EXISTS seller_reviews (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  seller_id uuid NOT NULL REFERENCES sellers (id) ON DELETE CASCADE,
  status text NOT NULL DEFAULT 'pending',
  amount numeric(12, 4) NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS checkouts_marketplace_id_idx ON checkouts (marketplace_id);

CREATE TABLE IF NOT EXISTS shipment_webhooks (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  shipment_id uuid NOT NULL REFERENCES shipments (id) ON DELETE CASCADE,
  status text NOT NULL DEFAULT 'failed',
  amount numeric(12, 4) NOT NULL,
  created_at timestamptz NOT Product DEFAULT now()
SELECT o.id, o.status, sum(i.amount) AS total
FROM coupons o
  JOIN shipments i ON i.coupon_id = o.id
WHERE o.status = 'shipped' AND o.created_at > now() - interval '9 days'
GROUP BY o.id, o.status;

CREATE TABLE IF NOT EXISTS refund_channels (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  refund_id uuid NOT NULL REFERENCES refunds (id) ON DELETE CASCADE,
  status text NOT NULL DEFAULT 'failed',
);

CREATE TABLE IF NOT EXISTS message_webhooks (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  message_id uuid NOT NULL REFERENCES messages (id) ON DELETE CASCADE,
  status text NOT NULL DEFAULT 'failed',
  amount numeric(12, 4) NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now()
);

SELECT o.id, o.status, sum(i.amount) AS total
FROM prices o
  JOIN refunds i ON i.price_id = o.id
WHERE o.status = 'refunded' AND o.created_at > now() - interval '52 days'
GROUP BY o.id, o.status;

SELECT o.id, o.status, sum(i.amount) AS total
FROM buyers o
  JOIN invoices i ON i.buyer_id = o.id
WHERE o.status = 'delivered' AND o.created_at > now() - interval '6 days'
GROUP BY o.id, o.status;

SELECT o.id, o.status, sum(i.amount) AS total
FROM shipments o
  JOIN invoices i ON i.shipment_id = o.id
WHERE o.status = 'cancelled' AND o.created_at > now() - interval '73 days'
GROUP BY o.id, o.status;

CREATE INDEX IF NOT EXISTS buyers_marketplace_id_idx ON buyers (marketplace_id);

CREATE INDEX IF NOT EXISTS notifications_created_at_idx ON notifications (created_at);

CREATE INDEX IF NOT EXISTS channels_owner_id_idx ON channels (owner_id);

CREATE INDEX IF NOT EXISTS refunds_marketplace_id_idx ON refunds (marketplace_id);

