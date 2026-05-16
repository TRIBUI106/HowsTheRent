---
tags: [api, endpoints, reference]
updated: 2026-05-09
---

# API Reference — czHTR

Base URL: `http://localhost:8080/api`

## Auth (public)
```
POST /auth/login          { email, password } → AuthResponse
POST /auth/refresh         { refreshToken }   → AuthResponse
POST /auth/logout
```

## Properties (ADMIN)
```
GET    /properties              → List<PropertyResponse>
GET    /properties/mine         → List<PropertyResponse> (owned by current user)
GET    /properties/{id}         → PropertyResponse
POST   /properties              → PropertyResponse
PUT    /properties/{id}         → PropertyResponse
GET    /properties/{id}/fee-config     → FeeConfigResponse
PUT    /properties/{id}/fee-config     → FeeConfigResponse
GET    /properties/{id}/vehicle-config → VehicleConfigResponse
PUT    /properties/{id}/vehicle-config → VehicleConfigResponse
```

## Rooms
```
GET    /properties/{propertyId}/rooms        → List<RoomResponse>
POST   /properties/{propertyId}/rooms        → RoomResponse
GET    /properties/{propertyId}/rooms/{id}   → RoomResponse
PUT    /properties/{propertyId}/rooms/{id}   → RoomResponse
PATCH  /properties/{propertyId}/rooms/{id}/status?status=RENTED → RoomResponse
POST   /properties/{propertyId}/rooms/{id}/images → List<String>
GET    /rooms                                → List<RoomResponse> (flat, for meter readings)
```

## Contracts
```
GET    /rooms/{roomId}/contracts  → List<ContractResponse>
POST   /rooms/{roomId}/contracts  → ContractResponse
GET    /contracts/{id}            → ContractResponse
PUT    /contracts/{id}/terminate  → ContractResponse
GET    /contracts                 → List<ContractResponse> (admin all)
```

## Meter Readings
```
GET    /rooms/{roomId}/meter-readings    → List<MeterReadingResponse>
POST   /rooms/{roomId}/meter-readings   → MeterReadingResponse
GET    /rooms/{roomId}/vehicle-records  → VehicleRecordResponse
PUT    /rooms/{roomId}/vehicle-records  → VehicleRecordResponse
```

## Invoices
```
GET    /invoices                     → List<InvoiceResponse> (ADMIN)
GET    /invoices/mine                → List<InvoiceResponse> (TENANT)
GET    /invoices/{id}               → InvoiceResponse
POST   /invoices/generate?year=&month= → { message }
POST   /invoices/{id}/pay-cash      → InvoiceResponse
POST   /invoices/{id}/pay-online    → { checkoutUrl }
```

## Payment (PUBLIC — no JWT)
```
POST   /payment/callback            PayOS webhook, verifies HMAC
```

## Maintenance
```
GET    /maintenance                  → List<MaintenanceRequestResponse> (ADMIN)
GET    /maintenance/my              → List<MaintenanceRequestResponse> (TENANT)
POST   /maintenance                 → MaintenanceRequestResponse (TENANT)
PUT    /maintenance/{id}/assign     → MaintenanceRequestResponse (ADMIN)
PUT    /maintenance/{id}/resolve    → MaintenanceRequestResponse (TECHNICIAN)
```

## Notifications
```
GET    /notifications               → List<NotificationResponse>
PUT    /notifications/{id}/read     → { message }
PUT    /notifications/read-all      → { message }
```

## Dashboard
```
GET    /dashboard                   → Map<String,Object> (ADMIN)
```

## Users
```
GET    /users                       → List<UserResponse> (ADMIN)
GET    /users/{id}                  → UserResponse
POST   /users                       → UserResponse
PUT    /users/{id}                  → UserResponse
```

## Response Format (DTOs)
All list endpoints return plain arrays `[]`. No pagination wrapper yet.
→ [[06-Roadmap]] — Pagination là priority 1.
