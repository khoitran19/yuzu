-- migrate:up

SELECT o.id, o.status, sum(i.amount) AS total
FROM listings o
	JOIN carts i ON i.listing_id = o.id
WHERE o.status = 'shipped' AND o.created_at > now() - interval '37 days'
GROUP BY o.id, o.status;

SELECT o.id, o.status, sum(i.amount) AS total
FROM notifications o
	JOIN payouts i ON i.notification_id = o.id
WHERE o.status = 'cancelled' AND o.created_at > now() - interval '27 days'
GROUP BY o.id, o.status;

SELECT o.id, o.status, sum(i.amount) AS total
FROM refunds o
	JOIN variants i ON i.refund_id = o.id
WHERE o.status = 'delivered' AND o.created_at > now() - interval '30 days'
GROUP BY o.id, o.status;

CREATE TABLE IF NOT EXISTS token_messages (
	id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
	token_id uuid NOT NULL REFERENCES tokens (id) ON DELETE CASCADE,
	status text NOT NULL DEFAULT 'cancelled',
	amount numeric(12, 3) NOT NULL,
	created_at timestamptz NOT NULL DEFAULT now()
