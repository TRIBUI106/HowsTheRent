# HowsTheRent
Hệ thống quản lý nhà trọ — theo dõi phòng, hợp đồng, hóa đơn, bảo trì, và cấu hình phí cho nhiều tòa nhà.

<img width="1229" height="690" alt="image" src="https://github.com/user-attachments/assets/a0e071d5-cc9b-4345-b60b-53c0529e0e45" />


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

## Frontend cache & offline

Frontend sử dụng TanStack Query để cache dữ liệu API và lưu cache xuống `localStorage`.

- Dữ liệu đã xem được khôi phục sau khi reload trang.
- Khi offline, ứng dụng hiển thị dữ liệu cache gần nhất và hiện banner cảnh báo dữ liệu có thể chưa mới nhất.
- Các thao tác ghi (`create`, `update`, `delete`, thanh toán, cập nhật trạng thái...) bị chặn khi offline; ứng dụng **không queue hoặc tự gửi lại** thao tác đó khi có mạng.
- Cache được xoá khi logout và được reset tự động sau production build mới.

> Dữ liệu cache được lưu theo trình duyệt. Hãy logout khi dùng máy dùng chung.

## Troubleshooting: API trả về 401

Nếu DevTools hiển thị `401` cho `/api/dashboard/...`, `/api/notifications` hoặc `/api/notifications/stream`:

1. Đăng xuất rồi đăng nhập lại để tạo lại HTTP-only session/refresh cookie.
2. Kiểm tra backend đang chạy và frontend đang gọi đúng API:
   - Local Vite dev server dùng proxy `/api` tới `http://localhost:8080`.
   - Production cần cấu hình `VITE_API_BASE_URL` đúng backend URL và backend phải cho phép origin frontend trong CORS.
3. Nếu lỗi vẫn lặp lại sau khi login, xoá site data/cookies của domain frontend trong Browser DevTools rồi đăng nhập lại.
4. `Unchecked runtime.lastError: Could not establish connection` thường đến từ browser extension, không phải lỗi của HowsTheRent backend.

Frontend sẽ thử refresh session một lần khi nhận `401`. Nếu refresh thất bại, ứng dụng xoá session local, xoá cache persisted và điều hướng về `/login`.

### Nguyên nhân gốc thường gặp (đã xảy ra nhiều lần trong lịch sử fix)

Lịch sử commit cho thấy phần lớn các đợt "sửa 401" lặp đi lặp lại chỉ đến từ **2 nguyên nhân kiến trúc**, không phải nhiều lỗi rời rạc. Biết trước 2 điều này để tránh lặp lại:

1. **Cookie auth bị đổi tên/scope mà không dọn cookie cũ.** Lịch sử: `localStorage` → cookie, `AccessToken` → `accessToken`, path `/api/maintenance` → `/`. Mỗi lần đổi, ai còn cookie cũ trong trình duyệt sẽ dính 401, và fix mỗi lần chỉ là "thêm fallback đọc cookie cũ" (xem `JwtAuthFilter.java`, vẫn còn `LEGACY_CAPITALIZED_ACCESS_TOKEN_COOKIE`). **Quy tắc:** không đổi tên/scope cookie `accessToken`/`refreshToken` nếu không thật sự cần thiết; nếu bắt buộc phải đổi, phải thêm cả fallback đọc cookie cũ **và** logic chủ động xoá cookie cũ ở mọi path cũ khi login/logout, giống các fix trước.
2. **Lazy JPA field bị truy cập ngoài transaction → hiện thành 401 thay vì 500.** Project chạy `spring.jpa.open-in-view=false`; nếu build response DTO **ngoài** `@Transactional` (ví dụ ở controller thay vì service) và đụng field `FetchType.LAZY` chưa fetch, sẽ ném `LazyInitializationException`. `GlobalExceptionHandler` đã bắt exception này trả về 500 thân thiện, và `JwtAuthFilter` đã fix để re-authenticate cả dispatch loại ASYNC/ERROR (`shouldNotFilterAsyncDispatch`/`shouldNotFilterErrorDispatch` = false) — nên lỗi này giờ hiện đúng là 500, không còn giả dạng 401 nữa. Nhưng nguyên nhân gốc (thiếu `@EntityGraph`) vẫn chưa được dọn hết — chỉ 7/15 entity có `FetchType.LAZY` đã được gắn `@EntityGraph` trên repository method liên quan. **Quy tắc cho code mới:** khi thêm entity/quan hệ lazy mới, luôn build DTO **bên trong** `@Transactional(readOnly = true)` của service, hoặc gắn `@EntityGraph` cho repository method sẽ dùng để trả response — đừng đợi bug rồi mới vá.

**Gotcha khác (chưa từng gây ticket, nhưng có thể gây 401 "vô cớ"):** `JwtAuthFilter` check thêm `authVersion` khớp giữa token và DB. Token còn hạn, chữ ký đúng, nhưng nếu `authVersion` bị bump ở nơi khác (đổi mật khẩu, đổi role, force logout) thì request vẫn 401 — đây là tính năng thu hồi token có chủ đích, không phải bug.
