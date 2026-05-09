---
tags: [backend, java, spring-boot, entities, api]
updated: 2026-05-09
---

# Backend Details — czHTR

## Entities & Relations
```
Property ←── Room ←── Contract ←── Invoice
   │             └──── MeterReading
   │             └──── VehicleRecord
   │             └──── MaintenanceRequest
   ├── FeeConfig
   └── VehicleConfig

User ────────── Contract (as tenant)
     ────────── MaintenanceRequest (as tenant & assignedTo)
     ────────── Notification
```

## Key Business Logic (BillingService)
```java
// Tháng đầu tiên → pro-rata
daysUsed = daysInMonth - moveInDay + 1
proRataRent = fullRent × daysUsed / daysInMonth  // HALF_UP

// Điện: (elecNew - elecOld) × elecPrice
// Nước PERSON: tenantCount × waterPrice
// Nước CUBIC: (waterNew - waterOld) × waterPrice
// Xe: (motorbike × price) + (car × price) + (bicycle × price)
// Dịch vụ: serviceFee (cố định)
```

## PayOS Integration
- Client ID, API Key, Checksum Key từ env vars
- Description: max 25 chars, no dấu tiếng Việt (VD: "Tien phong T5 P101")
- Webhook: POST /api/payment/callback — verify HMAC → update invoice PAID
- Frontend redirect: /payment/success hoặc /payment/cancel

## Spring Security
- Permit: POST /api/auth/**, POST /api/payment/callback, GET /payment/**
- Pre-authorize: `@PreAuthorize("hasRole('ADMIN')")` per controller method
- JWT: Bearer token trong Authorization header

## Enums
```
UserRole:          ADMIN, TENANT, TECHNICIAN
PropertyType:      BOARDING_HOUSE, CONDO (plan) / HOUSE, CONDO, APARTMENT, DORMITORY (impl)
RoomStatus:        EMPTY, RENTED, MAINTENANCE
ContractStatus:    ACTIVE, EXPIRED, TERMINATED
InvoiceStatus:     PENDING, PAID, OVERDUE
WaterMode:         PERSON, CUBIC
PaymentMethod:     PAYOS, CASH
MaintenanceStatus: OPEN, IN_PROGRESS, DONE
VehicleType:       MOTORBIKE, CAR, BICYCLE
```

## Quartz Jobs
| Job | Cron | Hành động |
|---|---|---|
| BillingJob | 0 0 8 1 * ? | Load ACTIVE contracts → check MeterReading → tính phí → tạo Invoice → PayOS link → email |
| OverdueReminderJob | 0 0 9 11 * ? | Load PENDING invoices quá hạn → OVERDUE → email nhắc |

## Notes
- `GenHash.java` — utility để hash password khi seed data
- `RoomsController` — flat GET /api/rooms endpoint (không qua propertyId) cho MeterReadings page
- Xem [[05-API-Reference]] cho đầy đủ endpoints
