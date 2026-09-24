-- migrate:up

CREATE INDEX IF NOT EXISTS webhooks_marketplace_id_idx ON webhooks (marketplace_id);

CREATE TABLE IF NOT EXISTS price_orders (
	id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	price_id uuid NOT NULL REFERENCES prices (id) ON DELETE CASCADE,
	status text NOT NULL DEFAULT 'pending',
	amount numeric(12, 4) NOT NULL,
	created_at timestamptz NOT NULL DEFAULT now()
);

SELECT o.id, o.status, sum(i.amount) AS total
FROM prices o
	JOIN payments i ON i.price_id = o.id
WHERE o.status = 'active' AND o.created_at > now() - interval '19 days'
GROUP BY o.id, o.status;

