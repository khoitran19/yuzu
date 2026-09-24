-- migrate:up

CREATE INDEX IF NOT EXISTS carts_created_at_idx ON carts (created_at);

