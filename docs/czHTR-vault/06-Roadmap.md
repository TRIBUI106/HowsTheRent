---
tags: [roadmap, todo, features]
updated: 2026-05-09
---

# Roadmap — czHTR

## 🔴 Priority 1 — Đang làm (Sprint hiện tại)

### 1. Pagination + Server-side Filter
**Backend:**
- Thêm `Pageable` vào tất cả list endpoints
- Return `Page<XxxResponse>` → wrap thành `PageResponse<T>` (content, totalElements, totalPages, page, size)
- Filter params qua `@RequestParam` (status, month, roomId, tenantId...)

**Frontend:**
- Component `Pagination.tsx`
- Update tất cả table pages dùng `?page=0&size=20`
- Filter inputs trên InvoicesPage, ContractsPage, MaintenancePage

### 2. PayOS Payment Flow (Tenant UI)
**Frontend:**
- Nút "Thanh toán online" trên tenant InvoicesPage
- Gọi `invoiceApi.createPaymentLink(id)` → mở `checkoutUrl` trong tab mới
- SuccessPage + CancelPage đã có, chỉ cần nối vào

### 3. Tenant Portal Đầy Đủ
- `/tenant/contract` — xem chi tiết hợp đồng đang active (moveInDate, deposit, room info)
- `/tenant/payment-history` — lịch sử thanh toán (invoices đã PAID)
- PDF download hóa đơn (frontend generate hoặc backend endpoint)

### 4. Quên Mật Khẩu / Reset Password
**Backend:**
- POST /api/auth/forgot-password → gửi OTP qua email → lưu Redis (TTL 15 phút)
- POST /api/auth/reset-password { email, otp, newPassword } → update password hash

**Frontend:**
- Link "Quên mật khẩu" trên LoginPage
- ForgotPasswordPage (nhập email)
- ResetPasswordPage (nhập OTP + mật khẩu mới)

## 🟡 Priority 2 — Sprint tiếp theo

### 5. Revenue + Occupancy Reports
- Chart doanh thu theo tháng (last 12 months)
- Tỷ lệ lấp đầy theo thời gian
- Recharts hoặc Chart.js

### 6. Maintenance Photo Upload
- Upload ảnh đồng hồ điện nước khi nhập chỉ số
- MinIO storage (backend đã có StorageService)

### 7. Export Excel / PDF
- Invoice list → Excel (poi-ooxml)
- Hóa đơn đơn lẻ → PDF (iText hoặc JasperReports)

### 8. Contract Renewal Workflow
- Cảnh báo 30 ngày trước hết hạn
- UI gia hạn / chấm dứt contract

## 🟢 Priority 3 — Tương lai

### 9. Audit Log
- Ghi lại ai sửa gì lúc nào
- Spring AOP + audit_logs table

### 10. CCCD Capture
- Tenant profile: số CCCD + ảnh mặt trước/sau
- Yêu cầu pháp lý Việt Nam

### 11. Tạm Trú Reminder
- Reminder workflow sau ký hợp đồng (đăng ký tạm trú 24-48h)

### 12. Zalo OA Notifications
- Zalo Official Account API
- Thay thế/bổ sung email notifications

### 13. VietQR / MoMo / VNPay
- QR code thanh toán trên hóa đơn PDF
- Thay thế PayOS hoặc bổ sung

### 14. Contract PDF Generation
- Template hợp đồng tiếng Việt theo Luật Dân sự 2015
- PDF với chữ ký số

## Done ✅
- Toàn bộ CRUD admin (property, room, contract, meter readings, invoices, maintenance)
- Billing engine (5 loại phí + pro-rata)
- Quartz jobs (billing + overdue reminder)
- PayOS SDK integration + webhook
- Email notifications
- JWT auth + refresh token
- 3-role system (Admin, Tenant, Technician)
- Response DTOs cho tất cả entities
- Modular API layer (11 modules)
- Custom hooks (useAuth, useNotifications)
- VehicleConfigPage, NotFoundPage
- 9 UI components

Xem [[02-State]] để biết trạng thái chi tiết.
