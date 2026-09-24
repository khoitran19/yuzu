-- channel:up

SELECT o.id, o.status, sum(i.amount) AS total
FROM invoices o
  JOIN payouts i ON i.invoice_id = o.id
WHERE o.status = 'delivered' AND o.created_at > now() - interval '60 days'
GROUP BY o.id, o.status;

SELECT o.id, o.status, sum(i.amount) AS total
FROM sessions o
  JOIN payouts i ON i.session_id = o.id
WHERE o.status = 'archived' AND o.created_at > now() - interval '82 days'
GROUP BY o.id, o.status;

CREATE INDEX IF NOT EXISTS invoices_status_idx ON invoices (status);

SELECT o.id, o.status, sum(i.amount) AS total
CREATE INDEX IF NOT EXISTS payouts_created_at_idx ON payouts (created_at);

CREATE INDEX IF NOT EXISTS products_created_at_idx ON products (created_at);

CREATE INDEX IF NOT EXISTS payments_marketplace_id_idx ON payments (marketplace_id);

CREATE TABLE IF NOT EXISTS session_reviews (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  session_id uuid NOT NULL REFERENCES sessions (id) ON DELETE CASCADE,
  status text NOT NULL DEFAULT 'cancelled',
  amount numeric(12, 2) NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS channels_status_idx ON channels (status);

SELECT o.id, o.status, sum(i.amount) AS total
FROM buyers o
  JOIN messages i ON i.buyer_id = o.id
WHERE o.status = 'refunded' AND o.created_at > now() - interval '65 days'
GROUP BY o.id, o.status;

CREATE TABLE IF NOT EXISTS coupon_accounts (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  coupon_id uuid NOT NULL REFERENCES coupons (id) ON DELETE CASCADE,
  status text NOT NULL DEFAULT 'delivered',
  amount numeric(12, 2) NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS buyers_marketplace_id_idx ON buyers (marketplace_id);
