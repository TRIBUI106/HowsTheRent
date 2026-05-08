import { Link, useLocation } from 'react-router-dom'
import { useQuery } from '@tanstack/react-query'
import { useAuthStore } from '@/stores/authStore'
import {
  LayoutDashboard, Building2, Home, FileText, Receipt,
  Wrench, Bell, LogOut, Settings, Users, Gauge, Menu, X
} from 'lucide-react'
import { cn } from '@/lib/utils'
import { useState } from 'react'
import type { ReactNode } from 'react'
import type { Notification } from '@/types'

interface LayoutProps {
  children: ReactNode
  title?: string
}

const navItems = [
  { to: '/admin',                exact: true,  icon: LayoutDashboard, label: 'Tổng quan',         roles: ['ADMIN'] },
  { to: '/admin/properties',     exact: false, icon: Building2,       label: 'Tài sản',           roles: ['ADMIN'] },
  { to: '/admin/rooms',          exact: false, icon: Home,            label: 'Phòng',             roles: ['ADMIN'] },
  { to: '/admin/contracts',      exact: false, icon: FileText,        label: 'Hợp đồng',          roles: ['ADMIN'] },
  { to: '/admin/meter-readings', exact: false, icon: Gauge,           label: 'Chỉ số điện nước',  roles: ['ADMIN'] },
  { to: '/admin/invoices',       exact: false, icon: Receipt,         label: 'Hóa đơn',           roles: ['ADMIN'] },
  { to: '/admin/maintenance',    exact: false, icon: Wrench,          label: 'Bảo trì',           roles: ['ADMIN'] },
  { to: '/admin/fee-config',     exact: false, icon: Settings,        label: 'Cài đặt phí',       roles: ['ADMIN'] },
  { to: '/admin/users',          exact: false, icon: Users,           label: 'Người dùng',        roles: ['ADMIN'] },
  { to: '/admin/notifications',  exact: false, icon: Bell,            label: 'Thông báo',         roles: ['ADMIN'] },
  { to: '/tenant',               exact: true,  icon: LayoutDashboard, label: 'Tổng quan',         roles: ['TENANT'] },
  { to: '/tenant/invoices',      exact: false, icon: Receipt,         label: 'Hóa đơn',           roles: ['TENANT'] },
  { to: '/tenant/maintenance',   exact: false, icon: Wrench,          label: 'Bảo trì',           roles: ['TENANT'] },
  { to: '/tenant/notifications', exact: false, icon: Bell,            label: 'Thông báo',         roles: ['TENANT'] },
  { to: '/tech',                 exact: true,  icon: LayoutDashboard, label: 'Tổng quan',         roles: ['TECHNICIAN'] },
  { to: '/tech/maintenance',     exact: false, icon: Wrench,          label: 'Công việc',         roles: ['TECHNICIAN'] },
  { to: '/tech/notifications',   exact: false, icon: Bell,            label: 'Thông báo',         roles: ['TECHNICIAN'] },
]

function resolveTitle(pathname: string): string {
  const match = [...navItems].reverse().find(item =>
    item.exact ? pathname === item.to : pathname.startsWith(item.to)
  )
  return match?.label ?? 'PropMS'
}

export default function Layout({ children, title }: LayoutProps) {
  const { user, clearAuth } = useAuthStore()
  const location = useLocation()
  const role = user?.role ?? ''
  const [sidebarOpen, setSidebarOpen] = useState(false)

  const filteredNav = navItems.filter(item => item.roles.includes(role))
  const pageTitle = title ?? resolveTitle(location.pathname)

  const { data: notifications } = useQuery<Notification[]>({
    queryKey: ['notifications'],
    queryFn: () => import('@/lib/api').then(m => m.default.get('/notifications').then(r => r.data)),
    staleTime: 30_000,
  })
  const unreadCount = notifications?.filter(n => !n.read).length ?? 0

  return (
    <div className="flex h-screen bg-gray-50">
      {/* Mobile overlay */}
      {sidebarOpen && (
        <div
          className="fixed inset-0 z-20 bg-black/50 lg:hidden"
          onClick={() => setSidebarOpen(false)}
        />
      )}

      {/* Sidebar */}
      <aside className={cn(
        'fixed lg:static inset-y-0 left-0 z-30 w-60 bg-slate-900 text-white flex flex-col shrink-0 transition-transform duration-200',
        sidebarOpen ? 'translate-x-0' : '-translate-x-full lg:translate-x-0'
      )}>
        {/* Brand */}
        <div className="px-5 py-5 border-b border-slate-700/60">
          <div className="flex items-center gap-2.5">
            <div className="w-7 h-7 bg-indigo-500 rounded-lg flex items-center justify-center text-white font-bold text-sm">P</div>
            <div>
              <p className="font-semibold text-sm leading-none">PropMS</p>
              <p className="text-xs text-slate-400 mt-0.5">Quản lý nhà trọ</p>
            </div>
          </div>
        </div>

        {/* Nav */}
        <nav className="flex-1 overflow-y-auto py-3 px-2 space-y-0.5">
          {filteredNav.map(item => {
            const Icon = item.icon
            const isActive = item.exact
              ? location.pathname === item.to
              : location.pathname === item.to || location.pathname.startsWith(item.to + '/')
            return (
              <Link
                key={item.to}
                to={item.to}
                onClick={() => setSidebarOpen(false)}
                className={cn(
                  'flex items-center gap-3 px-3 py-2 rounded-lg text-sm transition-all duration-150',
                  isActive
                    ? 'bg-indigo-600 text-white font-medium shadow-sm'
                    : 'text-slate-300 hover:bg-slate-800 hover:text-white'
                )}
              >
                <Icon size={16} className={isActive ? 'text-white' : 'text-slate-400'} />
                {item.label}
              </Link>
            )
          })}
        </nav>

        {/* User footer */}
        <div className="px-4 py-4 border-t border-slate-700/60">
          <div className="flex items-center gap-3 mb-3">
            <div className="w-7 h-7 bg-slate-600 rounded-full flex items-center justify-center text-xs font-semibold shrink-0">
              {user?.fullName?.charAt(0).toUpperCase()}
            </div>
            <div className="min-w-0">
              <p className="text-sm font-medium text-white truncate">{user?.fullName}</p>
              <p className="text-xs text-slate-400 truncate">{user?.email}</p>
            </div>
          </div>
          <button
            onClick={clearAuth}
            className="flex items-center gap-2 text-sm text-slate-400 hover:text-red-400 transition-colors w-full"
          >
            <LogOut size={14} />
            Đăng xuất
          </button>
        </div>
      </aside>

      {/* Main area */}
      <div className="flex-1 flex flex-col overflow-hidden min-w-0 lg:ml-0">
        {/* Top bar */}
        <header className="bg-white border-b border-gray-200 px-4 lg:px-6 py-3.5 flex items-center justify-between shrink-0">
          <div className="flex items-center gap-3">
            <button
              onClick={() => setSidebarOpen(v => !v)}
              className="lg:hidden p-1 rounded-md text-gray-500 hover:text-gray-700 hover:bg-gray-100"
            >
              {sidebarOpen ? <X size={20} /> : <Menu size={20} />}
            </button>
            <h1 className="text-base font-semibold text-gray-900">{pageTitle}</h1>
          </div>
          <div className="flex items-center gap-3">
            <Link
              to={role === 'ADMIN' ? '/admin/notifications' : role === 'TENANT' ? '/tenant/notifications' : '/tech/notifications'}
              className="relative"
            >
              <Bell size={18} className="text-gray-500 hover:text-gray-700 transition-colors" />
              {unreadCount > 0 && (
                <span className="absolute -top-1.5 -right-1.5 min-w-[16px] h-4 bg-red-500 text-white text-[10px] font-bold rounded-full flex items-center justify-center px-0.5">
                  {unreadCount > 99 ? '99+' : unreadCount}
                </span>
              )}
            </Link>
          </div>
        </header>

        {/* Page content */}
        <main className="flex-1 overflow-auto">
          {children}
        </main>
      </div>
    </div>
  )
}
