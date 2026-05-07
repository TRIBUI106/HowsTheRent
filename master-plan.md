# Property Management System — Project Plan

## Tổng quan

Hệ thống quản lý tòa nhà và dãy phòng trọ, hỗ trợ đa loại bất động sản (BOARDING_HOUSE / CONDO), tích hợp thanh toán tự động qua PayOS, gửi hóa đơn email hàng tháng.

**Target users:**
- Chủ nhà / Ban quản lý (Admin)
- Người thuê (Tenant)
- Kỹ thuật viên (Technician)

---

## Tech Stack

| Layer | Technology |
|---|---|
| Backend | Java 21, Spring Boot 3.x |
| Security | Spring Security + JWT (Access + Refresh token) |
| Database | PostgreSQL 16 |
| Cache | Redis (session, OTP) |
| ORM | Spring Data JPA + Hibernate |
| Scheduler | Quartz Scheduler |
| Email | JavaMailSender + Thymeleaf template |
| Payment | PayOS SDK |
| File Storage | MinIO (hợp đồng, ảnh phòng) |
| Frontend | React 18 + TypeScript |
| UI Library | shadcn/ui + Tailwind CSS |
| Data Fetching | TanStack Query (React Query) |
| Build tool BE | Maven |
| Build tool FE | Vite |
| Container | Docker + Docker Compose |

---

## Database Schema

### Enums

```
PropertyType      : BOARDING_HOUSE, CONDO
RoomStatus        : EMPTY, RENTED, MAINTENANCE
ContractStatus    : ACTIVE, EXPIRED, TERMINATED
InvoiceStatus     : PENDING, PAID, OVERDUE
WaterMode         : PERSON, CUBIC
VehicleType       : MOTORBIKE, CAR, BICYCLE
MaintenanceStatus : OPEN, IN_PROGRESS, DONE
PaymentMethod     : PAYOS, CASH
```

### Tables

#### users
```
id               UUID PK
full_name        VARCHAR(100)
email            VARCHAR(100) UNIQUE
phone            VARCHAR(20)
password_hash    VARCHAR
role             ENUM(ADMIN, TENANT, TECHNICIAN)
avatar_url       VARCHAR
is_active        BOOLEAN DEFAULT true
created_at       TIMESTAMP
updated_at       TIMESTAMP
```

#### properties
```
id               UUID PK
owner_id         UUID FK → users
name             VARCHAR(100)
address          TEXT
type             PropertyType
description      TEXT
created_at       TIMESTAMP
```

#### fee_configs
```
id               UUID PK
property_id      UUID FK → properties UNIQUE
rent_default     BIGINT              -- VND, giá mặc định nếu phòng không override
elec_price       BIGINT              -- VND / kWh
water_mode       WaterMode
water_price      BIGINT              -- VND / người hoặc / khối
service_fee      BIGINT              -- VND / phòng / tháng
vehicle_pro_rata BOOLEAN DEFAULT false
service_pro_rata BOOLEAN DEFAULT false
updated_at       TIMESTAMP
```

#### vehicle_configs
```
id               UUID PK
property_id      UUID FK → properties UNIQUE
motorbike_price  BIGINT              -- VND / xe / tháng
car_price        BIGINT
bicycle_price    BIGINT
updated_at       TIMESTAMP
```

#### rooms
```
id               UUID PK
property_id      UUID FK → properties
room_number      VARCHAR(20)
floor            INT
area_m2          DECIMAL(5,2)
max_people       INT
rent_override    BIGINT NULL         -- null = dùng fee_config.rent_default
status           RoomStatus DEFAULT EMPTY
images           TEXT[]              -- array URL
created_at       TIMESTAMP
```

#### contracts
```
id               UUID PK
room_id          UUID FK → rooms
tenant_id        UUID FK → users
move_in_date     DATE                -- ngày dọn vào thực tế
move_out_date    DATE NULL
status           ContractStatus DEFAULT ACTIVE
deposit_amount   BIGINT
notes            TEXT
file_url         VARCHAR             -- PDF hợp đồng lưu MinIO
created_at       TIMESTAMP
```

#### meter_readings
```
id               UUID PK
room_id          UUID FK → rooms
reading_month    DATE                -- ngày 1 của tháng (2024-03-01)
elec_old         BIGINT
elec_new         BIGINT
water_old        BIGINT NULL         -- null nếu water_mode = PERSON
water_new        BIGINT NULL
recorded_by      UUID FK → users
recorded_at      TIMESTAMP
```

#### vehicle_records
```
id               UUID PK
room_id          UUID FK → rooms
record_month     DATE
motorbike_count  INT DEFAULT 0
car_count        INT DEFAULT 0
bicycle_count    INT DEFAULT 0
updated_at       TIMESTAMP
```

#### invoices
```
id               UUID PK
room_id          UUID FK → rooms
contract_id      UUID FK → contracts
invoice_month    DATE                -- ngày 1 của tháng (2024-03-01)
is_pro_rata      BOOLEAN DEFAULT false
days_used        INT NULL            -- chỉ có khi is_pro_rata = true

rent_amount      BIGINT
elec_amount      BIGINT
water_amount     BIGINT
vehicle_amount   BIGINT
service_amount   BIGINT
total_amount     BIGINT

status           InvoiceStatus DEFAULT PENDING
payment_method   PaymentMethod NULL
payment_link_id  VARCHAR NULL        -- PayOS paymentLinkId
checkout_url     VARCHAR NULL        -- PayOS checkoutUrl
transaction_id   VARCHAR NULL        -- PayOS transactionId sau khi paid
due_date         DATE                -- ngày 10 của tháng đó
paid_at          TIMESTAMP NULL
created_at       TIMESTAMP
```

#### maintenance_requests
```
id               UUID PK
room_id          UUID FK → rooms
tenant_id        UUID FK → users
title            VARCHAR(200)
description      TEXT
images           TEXT[]
status           MaintenanceStatus DEFAULT OPEN
assigned_to      UUID FK → users NULL   -- technician
resolved_at      TIMESTAMP NULL
created_at       TIMESTAMP
updated_at       TIMESTAMP
```

#### notifications
```
id               UUID PK
user_id          UUID FK → users
title            VARCHAR(200)
body             TEXT
is_read          BOOLEAN DEFAULT false
type             VARCHAR(50)         -- INVOICE, MAINTENANCE, CONTRACT_EXPIRY
ref_id           UUID NULL           -- id của invoice / request liên quan
created_at       TIMESTAMP
```

---

## Backend — Spring Boot Project Structure

```
src/main/java/com/propms/
├── config/
│   ├── SecurityConfig.java
│   ├── JwtConfig.java
│   ├── QuartzConfig.java
│   ├── PayOSConfig.java
│   ├── MinIOConfig.java
│   └── RedisConfig.java
│
├── domain/
│   ├── entity/          -- JPA entities (User, Property, Room, Contract, Invoice ...)
│   ├── enums/           -- tất cả enums
│   └── repository/      -- Spring Data JPA repositories
│
├── dto/
│   ├── request/         -- LoginRequest, CreateRoomRequest, CreateInvoiceRequest ...
│   └── response/        -- UserResponse, InvoiceResponse, DashboardResponse ...
│
├── service/
│   ├── AuthService.java
│   ├── PropertyService.java
│   ├── RoomService.java
│   ├── ContractService.java
│   ├── MeterReadingService.java
│   ├── BillingService.java          -- core tính tiền
│   ├── InvoiceService.java
│   ├── PaymentService.java          -- tích hợp PayOS
│   ├── MaintenanceService.java
│   ├── NotificationService.java
│   ├── EmailService.java
│   └── StorageService.java          -- MinIO upload/download
│
├── controller/
│   ├── AuthController.java
│   ├── PropertyController.java
│   ├── RoomController.java
│   ├── ContractController.java
│   ├── MeterReadingController.java
│   ├── InvoiceController.java
│   ├── PaymentController.java       -- PayOS webhook endpoint
│   ├── MaintenanceController.java
│   ├── NotificationController.java
│   └── DashboardController.java
│
├── scheduler/
│   ├── BillingJob.java              -- chạy ngày 1: tạo invoice + PayOS link + gửi email
│   └── OverdueReminderJob.java      -- chạy ngày 11: nhắc tenant + báo admin
│
├── payment/
│   ├── PayOSClient.java
│   ├── PayOSRequest.java
│   ├── PayOSResponse.java
│   └── WebhookPayload.java
│
├── security/
│   ├── JwtTokenProvider.java
│   ├── JwtAuthFilter.java
│   └── CustomUserDetailsService.java
│
└── exception/
    ├── GlobalExceptionHandler.java
    ├── ResourceNotFoundException.java
    └── BusinessException.java
```

---

## Billing Engine — Logic Chi Tiết

### BillingService.java — các method chính

```java
// 1. Tính tiền phòng (có pro-rata tháng đầu)
BigDecimal calcRent(Contract contract, YearMonth targetMonth)

// 2. Tính tiền điện
BigDecimal calcElec(MeterReading reading, FeeConfig config)
// = (elec_new - elec_old) x elec_price

// 3. Tính tiền nước
BigDecimal calcWater(MeterReading reading, FeeConfig config, int tenantCount)
// PERSON: tenantCount x water_price
// CUBIC:  (water_new - water_old) x water_price

// 4. Tính tiền xe
BigDecimal calcVehicle(VehicleRecord record, VehicleConfig config)
// = (motorbike x price) + (car x price) + (bicycle x price)

// 5. Tính tiền dịch vụ
BigDecimal calcService(FeeConfig config)
// = service_fee (cố định / phòng)

// 6. Pro-rata
BigDecimal calcProRata(BigDecimal fullRent, LocalDate moveInDate)
// daysUsed = daysInMonth - moveInDay + 1
// result   = fullRent x daysUsed / daysInMonth  (RoundingMode.HALF_UP)
```

### Quartz Jobs

#### BillingJob — chạy ngày 1 lúc 08:00

```
1. Load tất cả contracts có status = ACTIVE
2. Với mỗi contract:
   a. Check MeterReading tháng này đã nhập chưa (nếu chưa → skip + alert admin)
   b. Tính 5 khoản: rent, elec, water, vehicle, service
   c. Tính is_pro_rata (chỉ tháng đầu tiên)
   d. Tạo Invoice (status = PENDING, due_date = ngày 10)
   e. Gọi PayOS API → lấy checkoutUrl, paymentLinkId
   f. Update invoice với PayOS info
   g. Gửi email + tạo notification cho tenant
```

#### OverdueReminderJob — chạy ngày 11 lúc 09:00

```
1. Load tất cả invoices có status = PENDING, due_date < today
2. Update status → OVERDUE
3. Gửi email nhắc tenant lần 2
4. Tạo notification cho admin
```

### PayOS Webhook — POST /api/payment/callback

```
1. Nhận payload từ PayOS
2. Verify HMAC signature (bắt buộc, không bỏ qua)
3. Nếu code = "00" (success):
   - Tìm invoice theo orderCode
   - Update status → PAID
   - Lưu transactionId, paid_at
   - Gửi email xác nhận thanh toán cho tenant
4. Nếu code khác → log lại, không xử lý
```

---

## API Endpoints

### Auth
```
POST /api/auth/login
POST /api/auth/refresh
POST /api/auth/logout
```

### Property
```
GET    /api/properties              -- list (admin)
POST   /api/properties              -- tạo mới
GET    /api/properties/{id}
PUT    /api/properties/{id}
GET    /api/properties/{id}/fee-config
PUT    /api/properties/{id}/fee-config
PUT    /api/properties/{id}/vehicle-config
```

### Room
```
GET    /api/properties/{propertyId}/rooms
POST   /api/properties/{propertyId}/rooms
GET    /api/rooms/{id}
PUT    /api/rooms/{id}
GET    /api/rooms/{id}/status       -- EMPTY / RENTED
```

### Contract
```
GET    /api/rooms/{roomId}/contracts
POST   /api/rooms/{roomId}/contracts
GET    /api/contracts/{id}
PUT    /api/contracts/{id}/terminate
```

### Meter Reading
```
GET    /api/rooms/{roomId}/meter-readings
POST   /api/rooms/{roomId}/meter-readings   -- admin nhập chỉ số đầu tháng
GET    /api/rooms/{roomId}/vehicle-records
PUT    /api/rooms/{roomId}/vehicle-records   -- admin cập nhật số xe
```

### Invoice
```
GET    /api/invoices                         -- admin: tất cả
GET    /api/invoices/my                      -- tenant: của mình
GET    /api/invoices/{id}
POST   /api/invoices/{id}/mark-paid-cash     -- admin xác nhận tiền mặt
GET    /api/invoices/{id}/payment-link       -- lấy lại checkout URL
```

### Payment
```
POST   /api/payment/callback                 -- PayOS webhook (public, không cần JWT)
```

### Maintenance
```
GET    /api/maintenance                      -- admin: tất cả
POST   /api/maintenance                      -- tenant tạo request
GET    /api/maintenance/my                   -- tenant xem của mình
PUT    /api/maintenance/{id}/assign          -- admin assign technician
PUT    /api/maintenance/{id}/resolve         -- technician đánh dấu xong
```

### Dashboard
```
GET    /api/dashboard/admin                  -- tổng quan: phòng trống, doanh thu tháng, hóa đơn pending
GET    /api/dashboard/tenant                 -- tenant: hóa đơn tháng này, request đang mở
```

### Notification
```
GET    /api/notifications                    -- list của user hiện tại
PUT    /api/notifications/{id}/read
PUT    /api/notifications/read-all
```

---

## Frontend — React Project Structure

```
src/
├── api/                   -- axios instances + API calls
│   ├── axiosClient.ts
│   ├── authApi.ts
│   ├── propertyApi.ts
│   ├── invoiceApi.ts
│   ├── maintenanceApi.ts
│   └── ...
│
├── components/
│   ├── ui/                -- shadcn/ui components (tự generate)
│   ├── layout/
│   │   ├── AdminLayout.tsx
│   │   └── TenantLayout.tsx
│   └── shared/
│       ├── InvoiceCard.tsx
│       ├── RoomStatusBadge.tsx
│       └── NotificationBell.tsx
│
├── pages/
│   ├── auth/
│   │   └── LoginPage.tsx
│   ├── admin/
│   │   ├── DashboardPage.tsx
│   │   ├── PropertiesPage.tsx
│   │   ├── RoomsPage.tsx
│   │   ├── ContractsPage.tsx
│   │   ├── MeterReadingPage.tsx   -- nhập chỉ số điện nước đầu tháng
│   │   ├── InvoicesPage.tsx
│   │   └── MaintenancePage.tsx
│   └── tenant/
│       ├── TenantDashboard.tsx
│       ├── TenantInvoices.tsx
│       └── TenantMaintenance.tsx
│
├── hooks/
│   ├── useAuth.ts
│   └── useNotifications.ts
│
├── stores/
│   └── authStore.ts        -- Zustand
│
└── types/
    └── index.ts            -- TypeScript interfaces
```

---

## Phân Chia Công Việc (Team 2–3 người)

### Phase 1 — 3 tuần: Core foundation

| Người | Việc |
|---|---|
| BE dev | Setup Spring Boot, Docker, DB schema, Auth (JWT), User CRUD |
| FE dev | Setup React + Vite + shadcn, Login page, layout, routing |
| BE dev | Property + Room + FeeConfig APIs |
| FE dev | Property list, Room list, Room detail pages |

**Done when:** Login hoạt động, tạo được property + room, phân quyền đúng role.

### Phase 2 — 3 tuần: Billing core

| Người | Việc |
|---|---|
| BE dev | Contract API, MeterReading API, BillingService (5 loại phí + pro-rata) |
| FE dev | Contract form, Meter reading input page, Invoice list |
| BE dev | Quartz jobs (BillingJob + OverdueJob), Email service, PayOS integration |
| FE dev | Invoice detail page, PayOS payment link redirect, Email template preview |

**Done when:** Chạy job thủ công tạo được invoice, tenant nhận email có link PayOS, thanh toán thành công cập nhật PAID.

### Phase 3 — 2 tuần: Polish + extras

| Người | Việc |
|---|---|
| BE dev | Maintenance API, Notification API, Dashboard API |
| FE dev | Maintenance pages, Notification bell, Admin dashboard charts |
| Cả team | Bug fix, responsive UI, deploy Docker Compose, viết báo cáo |

---

## Docker Compose

```yaml
services:
  postgres:
    image: postgres:16
    environment:
      POSTGRES_DB: propms
      POSTGRES_USER: propms
      POSTGRES_PASSWORD: secret

  redis:
    image: redis:7-alpine

  minio:
    image: minio/minio
    command: server /data --console-address ":9001"

  backend:
    build: ./backend
    ports: ["8080:8080"]
    depends_on: [postgres, redis, minio]
    environment:
      SPRING_DATASOURCE_URL: jdbc:postgresql://postgres:5432/propms
      PAYOS_CLIENT_ID: ${PAYOS_CLIENT_ID}
      PAYOS_API_KEY: ${PAYOS_API_KEY}
      PAYOS_CHECKSUM_KEY: ${PAYOS_CHECKSUM_KEY}

  frontend:
    build: ./frontend
    ports: ["3000:80"]
    depends_on: [backend]
```

---

## Lưu Ý Quan Trọng Khi Code

1. **Dùng `BigDecimal` cho tiền**, không dùng `double`. Luôn `RoundingMode.HALF_UP`.
2. **PayOS webhook phải verify HMAC signature** trước khi xử lý, không bỏ qua.
3. **`description` PayOS giới hạn 25 ký tự**, không dấu tiếng Việt. VD: `"Tien phong T5 P101"`.
4. **Pro-rata chỉ áp dụng tháng đầu tiên** của từng contract, check bằng `YearMonth.from(contract.getMoveInDate()).equals(YearMonth.now())`.
5. **Meter reading phải nhập trước khi job chạy** — nếu tháng đó chưa có reading thì skip invoice + alert admin, không tạo invoice sai.
6. **PayOS webhook endpoint `/api/payment/callback` phải public** (không cần JWT), nhưng bảo vệ bằng signature verify.
7. **Quartz job cần idempotent** — nếu chạy lại không được tạo duplicate invoice. Check bằng `invoiceRepository.existsByRoomIdAndInvoiceMonth(...)`.