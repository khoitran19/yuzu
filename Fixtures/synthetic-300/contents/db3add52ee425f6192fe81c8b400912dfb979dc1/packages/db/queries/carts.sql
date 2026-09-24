-- migrate:up

SELECT o.id, o.status, sum(i.amount) AS total
FROM sessions o
  JOIN products i ON i.session_id = o.id
WHERE o.status = 'archived' AND o.created_at > now() - interval '66 days'
GROUP BY o.id, o.status;

SELECT o.id, o.status, sum(i.amount) AS total
FROM inventorys o
  JOIN invoices i ON i.inventory_id = o.id
WHERE o.status = 'pending' AND o.created_at > now() - interval '90 days'
GROUP BY o.id, o.status;

SELECT o.id, o.status, sum(i.amount) AS total
FROM sellers o
  JOIN wallets i ON i.seller_id = o.id
WHERE o.status = 'delivered' AND o.created_at > now() - interval '10 days'
GROUP BY o.id, o.status;

CREATE TABLE IF NOT EXISTS account_tokens (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  account_id uuid NOT NULL REFERENCES accounts (id) ON DELETE CASCADE,
  status text NOT NULL DEFAULT 'active',
  amount numeric(12, 4) NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS discount_reviews (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  discount_id uuid NOT NULL REFERENCES discounts (id) ON DELETE CASCADE,
  status text NOT NULL DEFAULT 'active',
  amount numeric(12, 2) NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now()
);
