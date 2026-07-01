-- Seed data for local development
-- Run: docker exec -i htr-postgres psql -U htr -d htr < seed.sql

-- Admin user (password: Admin123!)
INSERT INTO users (id, full_name, email, phone, password_hash, role, is_active, created_at, updated_at)
VALUES (
    'a0000000-0000-0000-0000-000000000001',
    'Quản trị viên',
    'admin@example.com',
    '0909123456',
    '$2a$10$D61JISOCUmjEa.5LNjnk6OcSzRNS7e2lKm5NiXCi2SHHZwI7cU.Gq',
    'ADMIN',
    true,
    now(),
    now()
) ON CONFLICT (email) DO NOTHING;

-- Tenant (password: Tenant123!)
INSERT INTO users (id, full_name, email, phone, password_hash, role, is_active, created_at, updated_at)
VALUES (
    'a0000000-0000-0000-0000-000000000002',
    'Nguyễn Văn A',
    'tenant@example.com',
    '0912345678',
    '$2a$10$2fmWQAXWyE1ZRBpssWHhjeEu1YbdaXSlHyQWntleOEP/7NVGc3Oke',
    'TENANT',
    true,
    now(),
    now()
) ON CONFLICT (email) DO NOTHING;

-- Technician (password: Tech123!)
INSERT INTO users (id, full_name, email, phone, password_hash, role, is_active, created_at, updated_at)
VALUES (
    'a0000000-0000-0000-0000-000000000003',
    'Kỹ thuật viên B',
    'tech@example.com',
    '0923456789',
    '$2a$10$hwlFSpr2KivOP1/.rYUy8.cjiz7aIm0BkzJU95bpH0aisJQQ8oX8O',
    'TECHNICIAN',
    true,
    now(),
    now()
) ON CONFLICT (email) DO NOTHING;
