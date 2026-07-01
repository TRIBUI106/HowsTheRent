-- Example data for local PostgreSQL import
-- Import:
--   psql -U htr -d htr -f htr-backend/example-data-hcmc.sql
--
-- Notes:
-- - This file assumes the current schema has already been migrated.
-- - Passwords:
--   Admin users: Admin123!
--   Tenant users: Tenant123!
--   Technician users: Tech123!

BEGIN;

-- Users
INSERT INTO users (id, full_name, email, phone, password_hash, role, is_active, created_at, updated_at)
VALUES
    ('b1000000-0000-0000-0000-000000000001', 'Hoang Minh Quan', 'quan.hoang@demo-htr.vn', '0909123001', '$2a$10$D61JISOCUmjEa.5LNjnk6OcSzRNS7e2lKm5NiXCi2SHHZwI7cU.Gq', 'ADMIN', true, '2026-01-05 08:30:00', '2026-06-28 09:15:00'),
    ('b1000000-0000-0000-0000-000000000002', 'Nguyen Minh Anh', 'minhanh.nguyen@demo-htr.vn', '0908123002', '$2a$10$2fmWQAXWyE1ZRBpssWHhjeEu1YbdaXSlHyQWntleOEP/7NVGc3Oke', 'TENANT', true, '2026-01-06 10:00:00', '2026-06-29 18:40:00'),
    ('b1000000-0000-0000-0000-000000000003', 'Tran Gia Han', 'giahan.tran@demo-htr.vn', '0908123003', '$2a$10$2fmWQAXWyE1ZRBpssWHhjeEu1YbdaXSlHyQWntleOEP/7NVGc3Oke', 'TENANT', true, '2026-01-06 10:10:00', '2026-06-29 18:45:00'),
    ('b1000000-0000-0000-0000-000000000004', 'Le Quoc Bao', 'quocbao.le@demo-htr.vn', '0908123004', '$2a$10$2fmWQAXWyE1ZRBpssWHhjeEu1YbdaXSlHyQWntleOEP/7NVGc3Oke', 'TENANT', true, '2026-01-06 10:20:00', '2026-06-29 18:50:00'),
    ('b1000000-0000-0000-0000-000000000005', 'Pham Thu Trang', 'thutrang.pham@demo-htr.vn', '0908123005', '$2a$10$2fmWQAXWyE1ZRBpssWHhjeEu1YbdaXSlHyQWntleOEP/7NVGc3Oke', 'TENANT', true, '2026-01-06 10:30:00', '2026-06-29 18:55:00'),
    ('b1000000-0000-0000-0000-000000000006', 'Doan Hoang Nam', 'hoangnam.doan@demo-htr.vn', '0908123006', '$2a$10$2fmWQAXWyE1ZRBpssWHhjeEu1YbdaXSlHyQWntleOEP/7NVGc3Oke', 'TENANT', true, '2026-01-06 10:40:00', '2026-06-29 19:00:00'),
    ('b1000000-0000-0000-0000-000000000007', 'Bui Khanh Linh', 'khanhlinh.bui@demo-htr.vn', '0908123007', '$2a$10$2fmWQAXWyE1ZRBpssWHhjeEu1YbdaXSlHyQWntleOEP/7NVGc3Oke', 'TENANT', true, '2026-01-06 10:50:00', '2026-06-29 19:05:00'),
    ('b1000000-0000-0000-0000-000000000008', 'Vo Tuan Kiet', 'tuankiet.vo@demo-htr.vn', '0916123008', '$2a$10$hwlFSpr2KivOP1/.rYUy8.cjiz7aIm0BkzJU95bpH0aisJQQ8oX8O', 'TECHNICIAN', true, '2026-01-07 09:15:00', '2026-06-28 16:20:00'),
    ('b1000000-0000-0000-0000-000000000009', 'Phan Duc Huy', 'duchuy.phan@demo-htr.vn', '0916123009', '$2a$10$hwlFSpr2KivOP1/.rYUy8.cjiz7aIm0BkzJU95bpH0aisJQQ8oX8O', 'TECHNICIAN', true, '2026-01-07 09:25:00', '2026-06-28 16:25:00')
ON CONFLICT (id) DO UPDATE
SET
    full_name = EXCLUDED.full_name,
    email = EXCLUDED.email,
    phone = EXCLUDED.phone,
    password_hash = EXCLUDED.password_hash,
    role = EXCLUDED.role,
    is_active = EXCLUDED.is_active,
    updated_at = EXCLUDED.updated_at;

-- Property types
INSERT INTO property_types (id, code, name, description, active, created_at, updated_at)
VALUES
    ('b2000000-0000-0000-0000-000000000001', 'CONDO_PREMIUM', 'Chung cu', 'Can ho trong cac khu chung cu trung va cao cap tai TP.HCM', true, '2026-01-05 08:40:00', '2026-06-28 09:15:00'),
    ('b2000000-0000-0000-0000-000000000002', 'SERVICED_APARTMENT', 'Can ho dich vu', 'Can ho cho thue theo thang, co don dep va quan ly van hanh', true, '2026-01-05 08:45:00', '2026-06-28 09:15:00'),
    ('b2000000-0000-0000-0000-000000000003', 'MINI_APARTMENT', 'Can ho mini', 'Loai hinh studio va can ho nho trong khu dan cu noi thanh', true, '2026-01-05 08:50:00', '2026-06-28 09:15:00')
ON CONFLICT (id) DO UPDATE
SET
    code = EXCLUDED.code,
    name = EXCLUDED.name,
    description = EXCLUDED.description,
    active = EXCLUDED.active,
    updated_at = EXCLUDED.updated_at;

-- Properties
INSERT INTO properties (id, owner_id, name, address, type, description, created_at, updated_at)
VALUES
    ('b3000000-0000-0000-0000-000000000001', 'b1000000-0000-0000-0000-000000000001', 'Masteri Thao Dien - Toa T3', '159 Xa lo Ha Noi, Phuong Thao Dien, TP Thu Duc, TP.HCM', 'b2000000-0000-0000-0000-000000000001', 'Can ho huu nghi cho nhom khach di lam tai khu dong thanh pho.', '2026-01-08 09:00:00', '2026-06-30 10:00:00'),
    ('b3000000-0000-0000-0000-000000000002', 'b1000000-0000-0000-0000-000000000001', 'Vinhomes Central Park - Park 6', '208 Nguyen Huu Canh, Phuong 22, Quan Binh Thanh, TP.HCM', 'b2000000-0000-0000-0000-000000000001', 'Can ho huong song, phu hop cho gia dinh tre va nhan su van phong.', '2026-01-08 09:15:00', '2026-06-30 10:05:00'),
    ('b3000000-0000-0000-0000-000000000003', 'b1000000-0000-0000-0000-000000000001', 'The Gold View - Block A', '346 Ben Van Don, Phuong 1, Quan 4, TP.HCM', 'b2000000-0000-0000-0000-000000000001', 'Can ho gan trung tam, de di Quan 1 va khu Ben Nghe.', '2026-01-08 09:30:00', '2026-06-30 10:10:00'),
    ('b3000000-0000-0000-0000-000000000004', 'b1000000-0000-0000-0000-000000000001', 'Lexington Residence - Block LD', '67 Mai Chi Tho, Phuong An Phu, TP Thu Duc, TP.HCM', 'b2000000-0000-0000-0000-000000000001', 'Can ho co san noi that co ban, thich hop cho nguoi o lau dai.', '2026-01-08 09:45:00', '2026-06-30 10:15:00')
ON CONFLICT (id) DO UPDATE
SET
    owner_id = EXCLUDED.owner_id,
    name = EXCLUDED.name,
    address = EXCLUDED.address,
    type = EXCLUDED.type,
    description = EXCLUDED.description,
    updated_at = EXCLUDED.updated_at;

-- Fee configs
INSERT INTO fee_configs (
    id, property_id, rent_default, elec_price, water_mode, water_price, service_fee,
    vehicle_pro_rata, service_pro_rata, motorbike_price, car_price, bicycle_price,
    created_at, updated_at
)
VALUES
    ('b4000000-0000-0000-0000-000000000001', 'b3000000-0000-0000-0000-000000000001', 11800000, 3800, 'CUBIC', 18500, 350000, false, false, 120000, 1200000, 50000, '2026-01-08 09:05:00', '2026-06-30 10:00:00'),
    ('b4000000-0000-0000-0000-000000000002', 'b3000000-0000-0000-0000-000000000002', 14500000, 4000, 'CUBIC', 19000, 450000, false, false, 150000, 1350000, 50000, '2026-01-08 09:20:00', '2026-06-30 10:05:00'),
    ('b4000000-0000-0000-0000-000000000003', 'b3000000-0000-0000-0000-000000000003', 9900000, 3800, 'CUBIC', 18000, 300000, false, false, 120000, 1100000, 40000, '2026-01-08 09:35:00', '2026-06-30 10:10:00'),
    ('b4000000-0000-0000-0000-000000000004', 'b3000000-0000-0000-0000-000000000004', 11200000, 3900, 'CUBIC', 18500, 320000, false, false, 120000, 1150000, 40000, '2026-01-08 09:50:00', '2026-06-30 10:15:00')
ON CONFLICT (id) DO UPDATE
SET
    property_id = EXCLUDED.property_id,
    rent_default = EXCLUDED.rent_default,
    elec_price = EXCLUDED.elec_price,
    water_mode = EXCLUDED.water_mode,
    water_price = EXCLUDED.water_price,
    service_fee = EXCLUDED.service_fee,
    vehicle_pro_rata = EXCLUDED.vehicle_pro_rata,
    service_pro_rata = EXCLUDED.service_pro_rata,
    motorbike_price = EXCLUDED.motorbike_price,
    car_price = EXCLUDED.car_price,
    bicycle_price = EXCLUDED.bicycle_price,
    updated_at = EXCLUDED.updated_at;

-- Rooms
INSERT INTO rooms (id, property_id, room_number, floor, area_m2, max_people, rent_override, status, created_at, updated_at)
VALUES
    ('b5000000-0000-0000-0000-000000000001', 'b3000000-0000-0000-0000-000000000001', 'T3-12.08', 12, 52.00, 2, 12200000, 'RENTED', '2026-01-10 08:15:00', '2026-06-30 11:00:00'),
    ('b5000000-0000-0000-0000-000000000002', 'b3000000-0000-0000-0000-000000000001', 'T3-17.03', 17, 68.50, 3, 14800000, 'RENTED', '2026-01-10 08:20:00', '2026-06-30 11:00:00'),
    ('b5000000-0000-0000-0000-000000000003', 'b3000000-0000-0000-0000-000000000001', 'T3-08.11', 8, 49.30, 2, 11600000, 'EMPTY', '2026-01-10 08:25:00', '2026-06-30 11:00:00'),
    ('b5000000-0000-0000-0000-000000000004', 'b3000000-0000-0000-0000-000000000002', 'P6-18.05', 18, 54.20, 2, 15200000, 'RENTED', '2026-01-10 08:30:00', '2026-06-30 11:05:00'),
    ('b5000000-0000-0000-0000-000000000005', 'b3000000-0000-0000-0000-000000000002', 'P6-25.02', 25, 79.80, 4, 18900000, 'RENTED', '2026-01-10 08:35:00', '2026-06-30 11:05:00'),
    ('b5000000-0000-0000-0000-000000000006', 'b3000000-0000-0000-0000-000000000002', 'P6-09.01', 9, 48.00, 2, 14100000, 'MAINTENANCE', '2026-01-10 08:40:00', '2026-06-30 11:05:00'),
    ('b5000000-0000-0000-0000-000000000007', 'b3000000-0000-0000-0000-000000000003', 'A1-15.07', 15, 64.00, 3, 10500000, 'RENTED', '2026-01-10 08:45:00', '2026-06-30 11:10:00'),
    ('b5000000-0000-0000-0000-000000000008', 'b3000000-0000-0000-0000-000000000003', 'A1-22.09', 22, 71.50, 3, 11800000, 'EMPTY', '2026-01-10 08:50:00', '2026-06-30 11:10:00'),
    ('b5000000-0000-0000-0000-000000000009', 'b3000000-0000-0000-0000-000000000004', 'LD-12.04', 12, 58.00, 2, 11900000, 'RENTED', '2026-01-10 08:55:00', '2026-06-30 11:15:00'),
    ('b5000000-0000-0000-0000-000000000010', 'b3000000-0000-0000-0000-000000000004', 'LD-08.02', 8, 47.50, 2, 10800000, 'RENTED', '2026-01-10 09:00:00', '2026-06-30 11:15:00'),
    ('b5000000-0000-0000-0000-000000000011', 'b3000000-0000-0000-0000-000000000004', 'LD-20.01', 20, 83.20, 4, 16400000, 'EMPTY', '2026-01-10 09:05:00', '2026-06-30 11:15:00')
ON CONFLICT (id) DO UPDATE
SET
    property_id = EXCLUDED.property_id,
    room_number = EXCLUDED.room_number,
    floor = EXCLUDED.floor,
    area_m2 = EXCLUDED.area_m2,
    max_people = EXCLUDED.max_people,
    rent_override = EXCLUDED.rent_override,
    status = EXCLUDED.status,
    updated_at = EXCLUDED.updated_at;

-- Room images
DELETE FROM room_images
WHERE room_id IN (
    'b5000000-0000-0000-0000-000000000001',
    'b5000000-0000-0000-0000-000000000004',
    'b5000000-0000-0000-0000-000000000007',
    'b5000000-0000-0000-0000-000000000009'
);

INSERT INTO room_images (room_id, image_url)
VALUES
    ('b5000000-0000-0000-0000-000000000001', 'https://images.unsplash.com/photo-1505693416388-ac5ce068fe85'),
    ('b5000000-0000-0000-0000-000000000004', 'https://images.unsplash.com/photo-1494526585095-c41746248156'),
    ('b5000000-0000-0000-0000-000000000007', 'https://images.unsplash.com/photo-1484154218962-a197022b5858'),
    ('b5000000-0000-0000-0000-000000000009', 'https://images.unsplash.com/photo-1502672260266-1c1ef2d93688')
ON CONFLICT DO NOTHING;

-- Contracts
INSERT INTO contracts (id, room_id, tenant_id, move_in_date, move_out_date, status, deposit_amount, notes, file_url, created_at, updated_at)
VALUES
    ('b6000000-0000-0000-0000-000000000001', 'b5000000-0000-0000-0000-000000000001', 'b1000000-0000-0000-0000-000000000002', '2026-02-01', NULL, 'ACTIVE', 24400000, 'Hop dong 12 thang, thanh toan vao ngay 05 hang thang.', NULL, '2026-01-25 14:10:00', '2026-06-30 11:40:00'),
    ('b6000000-0000-0000-0000-000000000002', 'b5000000-0000-0000-0000-000000000002', 'b1000000-0000-0000-0000-000000000003', '2026-03-10', NULL, 'ACTIVE', 29600000, 'Khach o 2 nguoi, giu 1 xe may.', NULL, '2026-03-01 09:30:00', '2026-06-30 11:40:00'),
    ('b6000000-0000-0000-0000-000000000003', 'b5000000-0000-0000-0000-000000000004', 'b1000000-0000-0000-0000-000000000004', '2026-01-15', NULL, 'ACTIVE', 30400000, 'Khach la nhan vien ngan hang, thanh toan dung han.', NULL, '2026-01-10 16:45:00', '2026-06-30 11:45:00'),
    ('b6000000-0000-0000-0000-000000000004', 'b5000000-0000-0000-0000-000000000005', 'b1000000-0000-0000-0000-000000000005', '2026-04-01', NULL, 'ACTIVE', 37800000, 'Gia dinh tre 3 nguoi, co 1 oto.', NULL, '2026-03-20 10:20:00', '2026-06-30 11:45:00'),
    ('b6000000-0000-0000-0000-000000000005', 'b5000000-0000-0000-0000-000000000007', 'b1000000-0000-0000-0000-000000000006', '2026-02-18', NULL, 'ACTIVE', 21000000, 'Khach muon giu phong toi het Q1/2027.', NULL, '2026-02-10 13:05:00', '2026-06-30 11:50:00'),
    ('b6000000-0000-0000-0000-000000000006', 'b5000000-0000-0000-0000-000000000009', 'b1000000-0000-0000-0000-000000000007', '2026-05-05', NULL, 'ACTIVE', 23800000, 'Can ho da co noi that, khach giu 1 xe may.', NULL, '2026-04-28 15:10:00', '2026-06-30 11:50:00')
ON CONFLICT (id) DO UPDATE
SET
    room_id = EXCLUDED.room_id,
    tenant_id = EXCLUDED.tenant_id,
    move_in_date = EXCLUDED.move_in_date,
    move_out_date = EXCLUDED.move_out_date,
    status = EXCLUDED.status,
    deposit_amount = EXCLUDED.deposit_amount,
    notes = EXCLUDED.notes,
    file_url = EXCLUDED.file_url,
    updated_at = EXCLUDED.updated_at;

-- Invoices
INSERT INTO invoices (
    id, room_id, contract_id, invoice_month, is_pro_rata, days_used, rent_amount,
    elec_amount, water_amount, vehicle_amount, service_amount, total_amount,
    status, payment_method, payment_link_id, checkout_url, transaction_id, due_date, paid_at,
    created_at, updated_at
)
VALUES
    ('b7000000-0000-0000-0000-000000000001', 'b5000000-0000-0000-0000-000000000001', 'b6000000-0000-0000-0000-000000000001', '2026-06-01', false, NULL, 12200000, 418000, 185000, 120000, 350000, 13273000, 'PAID', 'CASH', NULL, NULL, NULL, '2026-06-07', '2026-06-05 19:20:00', '2026-06-01 08:30:00', '2026-06-05 19:20:00'),
    ('b7000000-0000-0000-0000-000000000002', 'b5000000-0000-0000-0000-000000000002', 'b6000000-0000-0000-0000-000000000002', '2026-06-01', false, NULL, 14800000, 452000, 210000, 120000, 350000, 15932000, 'PENDING', NULL, NULL, NULL, NULL, '2026-07-05', NULL, '2026-06-30 08:30:00', '2026-06-30 08:30:00'),
    ('b7000000-0000-0000-0000-000000000003', 'b5000000-0000-0000-0000-000000000004', 'b6000000-0000-0000-0000-000000000003', '2026-06-01', false, NULL, 15200000, 396000, 228000, 150000, 450000, 16424000, 'OVERDUE', NULL, NULL, NULL, NULL, '2026-06-10', NULL, '2026-06-01 09:00:00', '2026-06-20 09:30:00'),
    ('b7000000-0000-0000-0000-000000000004', 'b5000000-0000-0000-0000-000000000005', 'b6000000-0000-0000-0000-000000000004', '2026-06-01', false, NULL, 18900000, 510000, 265000, 1350000, 450000, 21475000, 'PENDING', NULL, NULL, NULL, NULL, '2026-07-05', NULL, '2026-06-30 09:10:00', '2026-06-30 09:10:00'),
    ('b7000000-0000-0000-0000-000000000005', 'b5000000-0000-0000-0000-000000000009', 'b6000000-0000-0000-0000-000000000006', '2026-06-01', true, 27, 10710000, 365000, 190000, 120000, 320000, 11705000, 'PAID', 'PAYOS', 'PAYOS-DEMO-0901', 'https://pay.payos.vn/demo/ld1204', 'TXN-DEMO-LD1204', '2026-06-07', '2026-06-06 12:10:00', '2026-06-01 10:00:00', '2026-06-06 12:10:00')
ON CONFLICT (id) DO UPDATE
SET
    room_id = EXCLUDED.room_id,
    contract_id = EXCLUDED.contract_id,
    invoice_month = EXCLUDED.invoice_month,
    is_pro_rata = EXCLUDED.is_pro_rata,
    days_used = EXCLUDED.days_used,
    rent_amount = EXCLUDED.rent_amount,
    elec_amount = EXCLUDED.elec_amount,
    water_amount = EXCLUDED.water_amount,
    vehicle_amount = EXCLUDED.vehicle_amount,
    service_amount = EXCLUDED.service_amount,
    total_amount = EXCLUDED.total_amount,
    status = EXCLUDED.status,
    payment_method = EXCLUDED.payment_method,
    payment_link_id = EXCLUDED.payment_link_id,
    checkout_url = EXCLUDED.checkout_url,
    transaction_id = EXCLUDED.transaction_id,
    due_date = EXCLUDED.due_date,
    paid_at = EXCLUDED.paid_at,
    updated_at = EXCLUDED.updated_at;

-- Maintenance requests
INSERT INTO maintenance_requests (
    id, room_id, tenant_id, title, description, status, assigned_to, resolved_at, created_at, updated_at
)
VALUES
    ('b8000000-0000-0000-0000-000000000001', 'b5000000-0000-0000-0000-000000000002', 'b1000000-0000-0000-0000-000000000003', 'Dieu hoa lanh yeu vao buoi toi', 'May lanh van chay nhung khong du mat, dac biet tu 20h tro di.', 'OPEN', 'b1000000-0000-0000-0000-000000000008', NULL, '2026-06-29 20:35:00', '2026-06-29 20:35:00'),
    ('b8000000-0000-0000-0000-000000000002', 'b5000000-0000-0000-0000-000000000004', 'b1000000-0000-0000-0000-000000000004', 'Cua phong tam bi keu', 'Ban le cua phong tam keu lon, can them dau mo va siet lai.', 'IN_PROGRESS', 'b1000000-0000-0000-0000-000000000009', NULL, '2026-06-27 18:10:00', '2026-06-30 08:15:00'),
    ('b8000000-0000-0000-0000-000000000003', 'b5000000-0000-0000-0000-000000000009', 'b1000000-0000-0000-0000-000000000007', 'Den ban cong khong sang', 'Da thay bong den moi nhung van khong sang, nghi la do cong tac.', 'DONE', 'b1000000-0000-0000-0000-000000000008', '2026-06-25 15:40:00', '2026-06-24 19:45:00', '2026-06-25 15:40:00')
ON CONFLICT (id) DO UPDATE
SET
    room_id = EXCLUDED.room_id,
    tenant_id = EXCLUDED.tenant_id,
    title = EXCLUDED.title,
    description = EXCLUDED.description,
    status = EXCLUDED.status,
    assigned_to = EXCLUDED.assigned_to,
    resolved_at = EXCLUDED.resolved_at,
    updated_at = EXCLUDED.updated_at;

-- Maintenance images
DELETE FROM maintenance_images
WHERE request_id IN (
    'b8000000-0000-0000-0000-000000000001',
    'b8000000-0000-0000-0000-000000000002'
);

INSERT INTO maintenance_images (request_id, image_url)
VALUES
    ('b8000000-0000-0000-0000-000000000001', 'https://images.unsplash.com/photo-1505693416388-ac5ce068fe85'),
    ('b8000000-0000-0000-0000-000000000002', 'https://images.unsplash.com/photo-1484154218962-a197022b5858')
ON CONFLICT DO NOTHING;

COMMIT;
