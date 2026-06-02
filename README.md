# HowsTheRent

Hệ thống quản lý nhà trọ — theo dõi phòng, hợp đồng, hóa đơn, bảo trì, và cấu hình phí cho nhiều tòa nhà.

## Tech Stack

**Frontend** — `htr-frontend/`
- React 19, TypeScript, Vite
- TailwindCSS v4, Lucide React
- TanStack Query v5, Zustand, React Router v7
- Recharts (charts), Axios (HTTP)

**Backend** — `htr-backend/`
- Spring Boot 4.0.6, Java 21
- Spring Security + JWT
- Spring Data JPA + PostgreSQL
- Redis (cache/session), Quartz (scheduled jobs)
- MinIO (file storage), Spring Mail + Thymeleaf (email)
- Apache POI (Excel export)

## Roles

### ADMIN — Quản lý tòa nhà
Toàn quyền quản lý hệ thống.

| Trang | Mô tả |
|-------|-------|
| Dashboard | Tổng quan số liệu toàn hệ thống |
| Properties | Quản lý danh sách tòa nhà |
| Rooms | Danh sách phòng theo tòa nhà |
| Room Detail | Lịch sử đầy đủ của phòng (hợp đồng, hóa đơn, bảo trì) |
| Contracts | Quản lý hợp đồng thuê |
| Users | Danh sách người dùng |
| Invoices | Tạo và quản lý hóa đơn hàng tháng |
| Meter Readings | Nhập chỉ số điện nước |
| Fee Config | Cấu hình giá phòng, điện, nước, dịch vụ theo tòa nhà |
| Maintenance | Xem và giao việc bảo trì cho kỹ thuật viên |
| Notifications | Thông báo hệ thống |
| Audit Log | Lịch sử toàn bộ hành động |

### TENANT — Người thuê
Chỉ xem thông tin liên quan đến bản thân.

| Trang | Mô tả |
|-------|-------|
| Dashboard | Tổng quan cá nhân |
| Invoices | Xem hóa đơn hàng tháng |
| Payment History | Lịch sử thanh toán |
| Maintenance | Gửi và theo dõi yêu cầu bảo trì |
| Contract Detail | Xem chi tiết hợp đồng |
| Notifications | Thông báo từ admin |

### TECHNICIAN — Kỹ thuật viên
Chỉ xử lý công việc được giao.

| Trang | Mô tả |
|-------|-------|
| Maintenance Board | Danh sách công việc bảo trì được assign |
| Notifications | Nhận thông báo khi có task mới |

## Flow tổng quát

```
Admin tạo tòa nhà & phòng
  → Cấu hình phí (Fee Config + Vehicle Config)
  → Ký hợp đồng với Tenant

Tenant vào ở
  → Phát sinh sự cố → gửi Maintenance Request
  → Admin thấy → assign cho Technician → Technician xử lý

Cuối tháng:
  Admin nhập chỉ số điện nước (Meter Readings)
  → Hệ thống tạo Invoice
  → Tenant xem và thanh toán
```

## Getting Started

### Backend
```bash
cd htr-backend
./mvnw spring-boot:run
```
Yêu cầu: Java 21, PostgreSQL, Redis, MinIO đang chạy.

### Frontend
```bash
cd htr-frontend
npm install
npm run dev
```
Yêu cầu: Node.js 18+
