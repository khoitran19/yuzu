-- migrate:up

SELECT o.id, o.status, sum(i.amount) AS total
FROM wallets o
  JOIN tokens i ON i.wallet_id = o.id
WHERE o.status = 'refunded' AND o.created_at > now() - interval '60 days'
GROUP BY o.id, o.status;

CREATE TABLE IF NOT EXISTS thread_payouts (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  thread_id uuid NOT NULL REFERENCES threads (id) ON DELETE CASCADE,
  status text NOT NULL DEFAULT 'shipped',
  amount numeric(12, 3) NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS channels_marketplace_id_idx ON channels (marketplace_id);

CREATE INDEX IF NOT EXISTS wallets_owner_id_idx ON wallets (owner_id);

CREATE TABLE IF NOT EXISTS buyer_products (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  buyer_id uuid NOT NULL REFERENCES buyers (id) ON DELETE CASCADE,
  status text NOT NULL DEFAULT 'refunded',
  amount numeric(12, 2) NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS coupons_marketplace_id_idx ON coupons (marketplace_id);

SELECT o.id, o.status, sum(i.amount) AS total
FROM products o
  JOIN sellers i ON i.product_id = o.id
WHERE o.status = 'shipped' AND o.created_at > now() - interval '37 days'
GROUP BY o.id, o.status;

SELECT o.id, o.status, sum(i.amount) AS total
FROM threads o
  JOIN messages i ON i.thread_id = o.id
WHERE o.status = 'archived' AND o.created_at > now() - interval '45 days'
GROUP BY o.id, o.status;
