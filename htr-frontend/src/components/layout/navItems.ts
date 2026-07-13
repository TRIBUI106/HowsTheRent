import {
  LayoutDashboard, Building2, Home, FileText, Receipt,
  Wrench, Bell, Settings, Users, Gauge, CreditCard, BarChart3, Clock,
} from 'lucide-react'

export const navItems = [
  { to: '/admin', exact: true, icon: LayoutDashboard, label: 'Tổng quan', roles: ['ADMIN'] },
  { to: '/admin/properties', exact: false, icon: Building2, label: 'Tài sản', roles: ['ADMIN'] },
  { to: '/admin/rooms', exact: false, icon: Home, label: 'Phòng', roles: ['ADMIN'] },
  { to: '/admin/contracts', exact: false, icon: FileText, label: 'Hợp đồng', roles: ['ADMIN'] },
  { to: '/admin/meter-readings', exact: false, icon: Gauge, label: 'Chỉ số điện nước', roles: ['ADMIN'] },
  { to: '/admin/invoices', exact: false, icon: Receipt, label: 'Hóa đơn', roles: ['ADMIN'] },
  { to: '/admin/maintenance', exact: false, icon: Wrench, label: 'Bảo trì', roles: ['ADMIN'] },
  { to: '/admin/reports', exact: false, icon: BarChart3, label: 'Báo cáo KPI', roles: ['ADMIN'] },
  { to: '/admin/sla-config', exact: false, icon: Clock, label: 'Cấu hình SLA', roles: ['ADMIN'] },
  { to: '/admin/fee-config', exact: false, icon: Settings, label: 'Cài đặt phí', roles: ['ADMIN'] },
  { to: '/admin/users', exact: false, icon: Users, label: 'Người dùng', roles: ['ADMIN'] },
  { to: '/admin/notifications', exact: false, icon: Bell, label: 'Thông báo', roles: ['ADMIN'] },
  { to: '/admin/audit-log', exact: false, icon: FileText, label: 'Nhật ký', roles: ['ADMIN'] },
  { to: '/tenant', exact: true, icon: LayoutDashboard, label: 'Tổng quan', roles: ['TENANT'] },
  { to: '/tenant/invoices', exact: false, icon: Receipt, label: 'Hóa đơn', roles: ['TENANT'] },
  { to: '/tenant/maintenance', exact: false, icon: Wrench, label: 'Bảo trì', roles: ['TENANT'] },
  { to: '/tenant/notifications', exact: false, icon: Bell, label: 'Thông báo', roles: ['TENANT'] },
  { to: '/tenant/contract', exact: false, icon: FileText, label: 'Hợp đồng', roles: ['TENANT'] },
  { to: '/tenant/payment-history', exact: false, icon: CreditCard, label: 'Lịch sử thanh toán', roles: ['TENANT'] },
  { to: '/tech', exact: true, icon: LayoutDashboard, label: 'Tổng quan', roles: ['TECHNICIAN'] },
  { to: '/tech/maintenance', exact: false, icon: Wrench, label: 'Công việc', roles: ['TECHNICIAN'] },
  { to: '/tech/notifications', exact: false, icon: Bell, label: 'Thông báo', roles: ['TECHNICIAN'] },
]

export function resolveTitle(pathname: string): string {
  const match = [...navItems].reverse().find((item) =>
    item.exact ? pathname === item.to : pathname.startsWith(item.to),
  )
  return match?.label ?? 'HowsTheRent'
}
