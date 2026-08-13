CREATE TABLE IF NOT EXISTS payment_intents (
    id UUID PRIMARY KEY,
    invoice_id UUID NOT NULL REFERENCES invoices(id),
    order_code VARCHAR(64) NOT NULL UNIQUE,
    status VARCHAR(30) NOT NULL,
    checkout_url TEXT,
    created_at TIMESTAMP NOT NULL,
    updated_at TIMESTAMP NOT NULL
);

CREATE TABLE IF NOT EXISTS payment_event_receipts (
    id UUID PRIMARY KEY,
    event_key VARCHAR(255) NOT NULL UNIQUE,
    order_code VARCHAR(64) NOT NULL,
    transaction_id VARCHAR(255),
    applied BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMP NOT NULL,
    updated_at TIMESTAMP NOT NULL
);

CREATE UNIQUE INDEX IF NOT EXISTS ux_invoices_payment_link_id ON invoices(payment_link_id) WHERE payment_link_id IS NOT NULL;
CREATE UNIQUE INDEX IF NOT EXISTS ux_invoices_transaction_id ON invoices(transaction_id) WHERE transaction_id IS NOT NULL;
