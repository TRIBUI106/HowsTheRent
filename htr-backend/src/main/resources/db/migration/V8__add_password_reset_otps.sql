-- Password-reset OTPs were previously held only in an in-memory ConcurrentHashMap
-- (AuthService.PASSWORD_RESET_OTPS), which is wiped on every process restart -- including a
-- Render free-tier instance spinning down after ~15 minutes idle, and every redeploy. A tenant
-- who requested an OTP and then hit either of those before entering it got a confusing "OTP
-- không hợp lệ hoặc đã hết hạn" even though the OTP's actual TTL hadn't elapsed. Moved to Postgres
-- so it survives restarts, matching how every other piece of durable state in this app is stored.
CREATE TABLE IF NOT EXISTS password_reset_otps (
    id UUID PRIMARY KEY,
    email VARCHAR(255) NOT NULL,
    otp_hash VARCHAR(255) NOT NULL,
    expires_at TIMESTAMP NOT NULL,
    created_at TIMESTAMP NOT NULL,
    updated_at TIMESTAMP NOT NULL
);

CREATE UNIQUE INDEX IF NOT EXISTS ux_password_reset_otps_email ON password_reset_otps(email);
