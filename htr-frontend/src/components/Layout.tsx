import { Link, useLocation } from 'react-router-dom'
import { useAuthStore } from '@/stores/authStore'
import {
  LayoutDashboard, Building2, Home, FileText, Receipt,
  Wrench, Bell, LogOut, Settings, Users, Gauge, Car, CreditCard
} from 'lucide-react'
import { cn } from '@/lib/utils'
import type { ReactNode } from 'react'

interface LayoutProps {
  children: ReactNode
  title?: string
}

const navItems = [
  { to: '/admin',                exact: true,  icon: LayoutDashboard, label: 'Tổng quan',          roles: ['ADMIN'] },
  { to: '/admin/properties',     exact: false, icon: Building2,       label: 'Tài sản',            roles: ['ADMIN'] },
  { to: '/admin/rooms',          exact: false, icon: Home,            label: 'Phòng',              roles: ['ADMIN'] },
  { to: '/admin/contracts',      exact: false, icon: FileText,        label: 'Hợp đồng',           roles: ['ADMIN'] },
  { to: '/admin/meter-readings', exact: false, icon: Gauge,           label: 'Chỉ số điện nước',   roles: ['ADMIN'] },
  { to: '/admin/invoices',       exact: false, icon: Receipt,         label: 'Hóa đơn',            roles: ['ADMIN'] },
  { to: '/admin/maintenance',    exact: false, icon: Wrench,          label: 'Bảo trì',            roles: ['ADMIN'] },
  { to: '/admin/fee-config',     exact: false, icon: Settings,        label: 'Cài đặt phí',        roles: ['ADMIN'] },
  { to: '/admin/vehicle-config', exact: false, icon: Car,             label: 'Cấu hình xe',        roles: ['ADMIN'] },
  { to: '/admin/users',          exact: false, icon: Users,           label: 'Người dùng',         roles: ['ADMIN'] },
  { to: '/admin/notifications',  exact: false, icon: Bell,            label: 'Thông báo',          roles: ['ADMIN'] },
  { to: '/admin/audit-log',      exact: false, icon: FileText,        label: 'Nhật ký',            roles: ['ADMIN'] },
  { to: '/tenant',               exact: true,  icon: LayoutDashboard, label: 'Tổng quan',          roles: ['TENANT'] },
  { to: '/tenant/invoices',      exact: false, icon: Receipt,         label: 'Hóa đơn',            roles: ['TENANT'] },
  { to: '/tenant/maintenance',   exact: false, icon: Wrench,          label: 'Bảo trì',            roles: ['TENANT'] },
  { to: '/tenant/notifications', exact: false, icon: Bell,            label: 'Thông báo',          roles: ['TENANT'] },
  { to: '/tenant/contract',      exact: false, icon: FileText,        label: 'Hợp đồng',           roles: ['TENANT'] },
  { to: '/tenant/payment-history', exact: false, icon: CreditCard,   label: 'Lịch sử thanh toán', roles: ['TENANT'] },
  { to: '/tech',                 exact: true,  icon: LayoutDashboard, label: 'Tổng quan',          roles: ['TECHNICIAN'] },
  { to: '/tech/maintenance',     exact: false, icon: Wrench,          label: 'Công việc',          roles: ['TECHNICIAN'] },
  { to: '/tech/notifications',   exact: false, icon: Bell,            label: 'Thông báo',          roles: ['TECHNICIAN'] },
]

function resolveTitle(pathname: string): string {
  const match = [...navItems].reverse().find(item =>
    item.exact ? pathname === item.to : pathname.startsWith(item.to)
  )
  return match?.label ?? 'HowsTheRent'
}

export default function Layout({ children, title }: LayoutProps) {
  const { user, clearAuth } = useAuthStore()
  const location = useLocation()
  const role = user?.role ?? ''

  const filteredNav = navItems.filter(item => item.roles.includes(role))
  const pageTitle = title ?? resolveTitle(location.pathname)

  const notifPath = role === 'ADMIN'
    ? '/admin/notifications'
    : role === 'TENANT'
    ? '/tenant/notifications'
    : '/tech/notifications'

  return (
    <div className="flex h-screen bg-bg">
      {/* Sidebar */}
      <aside className="w-60 bg-sidebar border-r border-border flex flex-col shrink-0">
        {/* Brand */}
        <div className="px-4 py-4 border-b border-border">
          <div className="flex items-center gap-2.5">
            <div className="w-7 h-7 bg-accent rounded-lg flex items-center justify-center shrink-0">
              <span className="text-accent-fg font-bold text-xs">P</span>
            </div>
            <div>
              <p className="font-semibold text-sm text-fg leading-none">HowsTheRent</p>
              <p className="text-xs text-fg-subtle mt-0.5">Quản lý nhà trọ</p>
            </div>
          </div>
        </div>

        {/* Nav */}
        <nav className="flex-1 overflow-y-auto py-2 px-2 space-y-0.5">
          {filteredNav.map(item => {
            const Icon = item.icon
            const isActive = item.exact
              ? location.pathname === item.to
              : location.pathname === item.to || location.pathname.startsWith(item.to + '/')
            return (
              <Link
                key={item.to + item.label}
                to={item.to}
                className={cn(
                  'flex items-center gap-2.5 px-3 py-2 rounded-lg text-sm transition-colors duration-100',
                  isActive
                    ? 'bg-accent-surface text-accent font-medium'
                    : 'text-fg-muted hover:bg-border/40 hover:text-fg'
                )}
              >
                <Icon
                  size={15}
                  className={cn('shrink-0', isActive ? 'text-accent' : 'text-fg-subtle')}
                />
                {item.label}
              </Link>
            )
          })}
        </nav>

        {/* User footer */}
        <div className="px-3 py-3 border-t border-border">
          <div className="flex items-center gap-2.5 mb-2.5">
            <div className="w-7 h-7 bg-accent-surface text-accent rounded-full flex items-center justify-center text-xs font-semibold shrink-0">
              {user?.fullName?.charAt(0).toUpperCase()}
            </div>
            <div className="min-w-0">
              <p className="text-sm font-medium text-fg truncate leading-none mb-0.5">{user?.fullName}</p>
              <p className="text-xs text-fg-subtle truncate">{user?.email}</p>
            </div>
          </div>
          <button
            onClick={clearAuth}
            className="flex items-center gap-2 text-xs text-fg-subtle hover:text-error transition-colors w-full py-1 rounded"
          >
            <LogOut size={13} />
            Đăng xuất
          </button>
        </div>
      </aside>

      {/* Main area */}
      <div className="flex-1 flex flex-col overflow-hidden min-w-0">
        {/* Top bar */}
        <header className="bg-surface border-b border-border px-6 py-3 flex items-center justify-between shrink-0">
          <h1 className="text-sm font-semibold text-fg">{pageTitle}</h1>
          <div className="flex items-center gap-3">
            <Link to={notifPath} className="p-1.5 rounded-lg hover:bg-sidebar transition-colors">
              <Bell size={16} className="text-fg-muted" />
            </Link>
          </div>
        </header>

        {/* Page content */}
        <main className="flex-1 overflow-auto p-6">
          {children}
        </main>
      </div>
    </div>
  )
}
