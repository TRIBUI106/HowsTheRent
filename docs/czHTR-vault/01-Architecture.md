---
tags: [architecture, backend, frontend]
updated: 2026-05-09
---

# Architecture — czHTR

## Backend Package Structure
```
chez1s.htrbackend/
├── config/        AsyncConfig, MinioConfig, QuartzConfig, RestClientConfig, SecurityConfig, WebConfig
├── controller/    Auth, Property, Room, Rooms(flat), Contract, Invoice, MeterReading,
│                  Maintenance, Notification, Payment, Dashboard, User
├── domain/
│   ├── entity/    User, Property, Room, Contract, Invoice, MeterReading, VehicleRecord,
│                  FeeConfig, VehicleConfig, MaintenanceRequest, Notification
│   ├── enums/     UserRole, PropertyType, RoomStatus, ContractStatus, InvoiceStatus,
│                  MaintenanceStatus, PaymentMethod, VehicleType, WaterMode
│   └── repository/ 11 Spring Data JPA repos
├── dto/
│   ├── request/   CreateProperty/Room/Contract/MeterReading/MaintenanceRequest,
│                  LoginRequest, RefreshRequest, UpdateFeeConfig/VehicleConfig/VehicleRecord
│   └── response/  PropertyResponse, RoomResponse, ContractResponse, InvoiceResponse,
│                  FeeConfigResponse, VehicleConfigResponse, MeterReadingResponse,
│                  VehicleRecordResponse, MaintenanceRequestResponse, NotificationResponse,
│                  AuthResponse, UserResponse
├── service/       Auth, Property, Room, Contract, MeterReading, Billing, Invoice,
│                  PayOS, Maintenance, Notification, Email, Storage
├── job/           BillingJob (Quartz, ngày 1 08:00), OverdueReminderJob (ngày 11 09:00)
├── security/      JwtTokenProvider, JwtAuthFilter, CustomUserDetailsService
└── exception/     GlobalExceptionHandler, BusinessException, ResourceNotFoundException
```

## Frontend Structure
```
htr-frontend/src/
├── api/           authApi, propertyApi, roomApi, contractApi, meterReadingApi,
│                  invoiceApi, maintenanceApi, notificationApi, dashboardApi, userApi, index
├── components/
│   ├── Layout.tsx (sidebar + header, role-filtered nav)
│   └── ui/        badge, button, card, dialog, feedback, input, select, table, textarea
├── hooks/         useAuth.ts, useNotifications.ts
├── lib/           api.ts (axios + JWT interceptor), utils.ts (formatDate, formatCurrency, cn)
├── pages/
│   ├── admin/     Dashboard, Properties, Rooms, Contracts, MeterReadings, Invoices,
│                  Maintenance, FeeConfig, VehicleConfig, Users, Notifications
│   ├── tenant/    Dashboard, Invoices, Maintenance, Notifications
│   ├── tech/      Maintenance, Notifications
│   ├── payment/   SuccessPage, CancelPage
│   └── auth/      LoginPage
├── stores/        authStore.ts (Zustand)
└── types/         index.ts (User, Property, Room, Contract, Invoice, MeterReading,
                   VehicleRecord, FeeConfig, VehicleConfig, MaintenanceRequest,
                   Notification, Dashboard, AuthResponse)
```

## Key Patterns
- **Response DTOs**: Controllers không return raw JPA entities — tất cả dùng `XxxResponse.from(entity)` để tránh lazy loading issues
- **JWT flow**: Access token (short-lived) + Refresh token → auto refresh ở axios interceptor → redirect /login nếu fail
- **Billing Engine**: BillingService tính 5 loại phí (rent, elec, water, vehicle, service) + pro-rata tháng đầu
- **PayOS webhook**: POST /api/payment/callback — public endpoint, bảo vệ bằng HMAC verify
- **Quartz idempotent**: BillingJob check `invoiceRepository.existsByRoomIdAndInvoiceMonth()` trước khi tạo
- **BigDecimal**: Tất cả tiền dùng BigDecimal với `RoundingMode.HALF_UP`

## Docker Compose Services
`postgres` → `redis` → `minio` → `backend:8080` → `frontend:3000`
