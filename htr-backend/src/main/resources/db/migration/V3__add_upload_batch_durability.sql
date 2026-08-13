CREATE TABLE IF NOT EXISTS upload_batches (
    id UUID PRIMARY KEY,
    idempotency_key VARCHAR(255) NOT NULL UNIQUE,
    status VARCHAR(30) NOT NULL,
    domain_type VARCHAR(40) NOT NULL,
    domain_id UUID,
    cleanup_required BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMP NOT NULL,
    updated_at TIMESTAMP NOT NULL
);

CREATE TABLE IF NOT EXISTS upload_batch_items (
    id UUID PRIMARY KEY,
    batch_id UUID NOT NULL REFERENCES upload_batches(id),
    object_name TEXT NOT NULL,
    content_type VARCHAR(100),
    size_bytes BIGINT NOT NULL,
    status VARCHAR(30) NOT NULL,
    created_at TIMESTAMP NOT NULL,
    updated_at TIMESTAMP NOT NULL
);
CREATE INDEX IF NOT EXISTS ix_upload_batch_items_batch ON upload_batch_items(batch_id);
