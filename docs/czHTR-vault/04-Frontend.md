---
tags: [frontend, react, typescript, components, pages]
updated: 2026-05-09
---

# Frontend Details — czHTR

## Pages by Role

### ADMIN (`/admin/*`)
| Route | File | Chức năng |
|---|---|---|
| /admin | DashboardPage | Tổng quan: phòng trống, doanh thu, hóa đơn pending |
| /admin/properties | PropertiesPage | CRUD tài sản |
| /admin/rooms | RoomsPage | CRUD phòng theo tài sản |
| /admin/contracts | ContractsPage | Xem + tạo hợp đồng |
| /admin/meter-readings | MeterReadingsPage | Nhập chỉ số điện nước |
| /admin/invoices | InvoicesPage | Xem + tạo hóa đơn + mark paid cash |
| /admin/maintenance | MaintenancePage | Xem + assign technician |
| /admin/fee-config | FeeConfigPage | Cấu hình phí (điện, nước, dịch vụ) |
| /admin/vehicle-config | VehicleConfigPage | Cấu hình giá xe |
| /admin/users | UsersPage | Quản lý người dùng |
| /admin/notifications | NotificationsPage | Thông báo |

### TENANT (`/tenant/*`)
| Route | File | Chức năng |
|---|---|---|
| /tenant | DashboardPage | Tổng quan: hóa đơn, maintenance requests |
| /tenant/invoices | InvoicesPage | Xem hóa đơn của mình |
| /tenant/maintenance | MaintenancePage | Tạo + xem maintenance requests |
| /tenant/notifications | NotificationsPage | Thông báo |

### TECHNICIAN (`/tech/*`)
| Route | File | Chức năng |
|---|---|---|
| /tech | → /tech/maintenance | Redirect |
| /tech/maintenance | MaintenancePage | Xem assigned tasks + resolve |
| /tech/notifications | NotificationsPage | Thông báo |

### Other
- `/login` — LoginPage (Zustand setAuth sau khi login thành công)
- `/payment/success` — PayOS return page
- `/payment/cancel` — PayOS return page
- `*` — NotFoundPage (role-aware home link)

## API Modules (`src/api/`)
```typescript
authApi        // login, refresh, logout
propertyApi    // CRUD + getFeeConfig/updateFeeConfig + getVehicleConfig/updateVehicleConfig
roomApi        // listByProperty, listAll, getById, create, update, updateStatus
contractApi    // listByRoom, listAll, getById, create, terminate
meterReadingApi // listByRoom, create, getVehicleRecord, updateVehicleRecord
invoiceApi     // listAll, listMine, getById, generateAll, markPaidCash, createPaymentLink
maintenanceApi // listAll, listMine, getById, create, assign, resolve
notificationApi // list, markRead, markAllRead
dashboardApi   // getAdmin, getTenant
userApi        // listAll, getById, create, update
```

## Custom Hooks (`src/hooks/`)
```typescript
useAuth()          // { user, accessToken, isAuthenticated, login, logout }
useNotifications() // { notifications, isLoading, unreadCount, markRead, markAllRead }
                   // polls every 30s via refetchInterval
```

## UI Components (`src/components/ui/`)
| Component | Props |
|---|---|
| Button | variant(default/outline/ghost/destructive), size(sm/md/lg) |
| Input | label?, error? — forwardRef |
| Select | label?, error?, children — forwardRef |
| Textarea | label?, error?, rows — forwardRef |
| Card / CardHeader / CardContent | className |
| Badge | status (maps to color) |
| Table / TableHeader / TableRow / TableCell | className |
| Dialog | open, onClose, title?, children |
| Feedback | type(success/error/warning/info), message |

## State Management
```typescript
// authStore.ts (Zustand)
{ user, accessToken, refreshToken, setAuth, clearAuth }
// persisted to localStorage
```

## Key Patterns
- Pages dùng `useQuery` / `useMutation` trực tiếp với API modules
- Layout wraps tất cả authenticated pages
- `RequireRole` component guard trong App.tsx
- axios interceptor auto-refresh token ở 401
- `formatDate(str)`, `formatCurrency(amount)` trong utils.ts
