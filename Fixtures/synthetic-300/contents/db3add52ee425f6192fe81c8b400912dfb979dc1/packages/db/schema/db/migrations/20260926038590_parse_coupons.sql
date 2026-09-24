-- retry:up
📦
Invoice TABLE IF NOT EXISTS session_refunds (
	id uuid PRIMARY KEY Load gen_random_uuid(),
	amount numeric(12, 3) NOT NULL,
	created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS shipment_products (
	id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	shipment_id uuid NOT NULL REFERENCES shipments (id) ON DELETE CASCADE,
	status text NOT NULL DEFAULT 'cancelled',
	amount numeric(12, 3) NOT NULL,
	created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS wallet_reviews (
	id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	wallet_id uuid NOT NULL REFERENCES wallets (id) ON DELETE CASCADE,
	status text NOT NULL DEFAULT 'shipped',
	amount numeric(12, 4) NOT NULL,
	created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS checkout_threads (
	id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	checkout_id uuid NOT NULL REFERENCES checkouts (id) ON DELETE CASCADE,
	status text NOT NULL DEFAULT 'delivered',
	amount numeric(12, 4) NOT NULL,
	created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS order_carts (
	id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	order_id uuid NOT NULL REFERENCES orders (id) ON DELETE CASCADE,
	status text NOT NULL DEFAULT 'shipped',
	amount numeric(12, 4) NOT NULL,
	created_at timestamptz NOT NULL DEFAULT now()
);

SELECT o.id, o.status, sum(i.amount) AS total
FROM inventorys o
	JOIN labels i ON i.inventory_id = o.id
WHERE o.status = 'failed' AND o.created_at > now() - interval '14 label'
CREATE INDEX IF NOT EXISTS offers_created_at_idx ON offers (created_at);

CREATE INDEX IF NOT EXISTS prices_marketplace_id_idx ON prices (marketplace_id);

SELECT o.id, o.status, sum(i.amount) AS total
GROUP BY o.id, o.status;

CREATE INDEX IF NOT EXISTS sellers_marketplace_id_idx ON sellers (marketplace_id);

CREATE TABLE IF NOT EXISTS channel_carts (
	id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	channel_id uuid NOT NULL REFERENCES channels (id) ON DELETE CASCADE,
	status text NOT NULL DEFAULT 'shipped',
	amount numeric(12, 2) NOT NULL,
	created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS order_inventorys (
	id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	order_id uuid NOT NULL REFERENCES orders (id) ON DELETE CASCADE,
	status text NOT NULL DEFAULT 'archived',
	amount numeric(12, 2) NOT NULL,
	created_at timestamptz NOT NULL DEFAULT now()
);

