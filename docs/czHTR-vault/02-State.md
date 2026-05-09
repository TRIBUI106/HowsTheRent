---
tags: [state, progress, roadmap]
updated: 2026-05-09
---

# Project State — czHTR

## Trạng thái hiện tại (2026-05-09)
**Phase 3 — Polish hoàn chỉnh**. Backend và Frontend đều functional.

## Đã hoàn thành

### Backend ✅
- Toàn bộ domain entities (11 entities, 9 enums, 11 repositories)
- Auth: JWT access + refresh token, Spring Security
- 12 Response DTOs (tránh lazy loading khi serialize)
- 12 Controllers: Property, Room, Contract, Invoice, MeterReading, Maintenance, Notification, Payment, Dashboard, User, Auth, Rooms(flat)
- 11 Services: Auth, Property, Room, Contract, MeterReading, Billing, Invoice, PayOS, Maintenance, Notification, Email, Storage
- Quartz jobs: BillingJob (ngày 1), OverdueReminderJob (ngày 11)
- PayOS webhook với HMAC verify
- Docker Compose: postgres, redis, minio, backend, frontend

### Frontend ✅
- 19 pages: 10 admin + 4 tenant + 2 tech + 1 auth + 2 payment + 1 404
- `src/api/` — 11 typed API modules
- `src/hooks/` — useAuth, useNotifications
- `src/components/ui/` — 9 components (badge, button, card, dialog, feedback, input, select, table, textarea)
- Layout với sidebar nav theo role
- Routing với role-based guards

## Chưa làm — theo thứ tự ưu tiên
Xem [[06-Roadmap]] để biết chi tiết.

| # | Tính năng | Priority |
|---|---|---|
| 1 | Pagination + filter trên list APIs | 🔴 Cao |
| 2 | PayOS payment flow từ tenant UI | 🔴 Cao |
| 3 | Tenant portal đầy đủ (hợp đồng, lịch sử, PDF) | 🔴 Cao |
| 4 | Quên mật khẩu / reset password | 🔴 Cao |
| 5 | Revenue / occupancy reports | 🟡 Trung |
| 6 | Maintenance photo uploads | 🟡 Trung |
| 7 | Xuất Excel / PDF | 🟡 Trung |
| 8 | Gia hạn hợp đồng | 🟡 Trung |
| 9 | Audit log | 🟢 Thấp |
| 10 | CCCD capture | 🟢 Thấp |
| 11 | Zalo OA notifications | 🟢 Thấp (planned later) |
