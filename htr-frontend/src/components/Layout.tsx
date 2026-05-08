import { Link, useLocation } from 'react-router-dom'
import { useAuthStore } from '@/stores/authStore'
import { LayoutDashboard, Building2, Home, FileText, Receipt, Wrench, Bell, LogOut, Settings, Users } from 'lucide-react'
import { cn } from '@/lib/utils'
import type { ReactNode } from 'react'

interface LayoutProps {
  children: ReactNode
  title?: string
}

const navItems = [
  { to: '/admin', icon: LayoutDashboard, label: 'Dashboard', roles: ['ADMIN'] },
  { to: '/admin/properties', icon: Building2, label: 'Tài sản', roles: ['ADMIN'] },
  { to: '/admin/rooms', icon: Home, label: 'Phòng', roles: ['ADMIN'] },
  { to: '/admin/contracts', icon: FileText, label: 'Hợp đồng', roles: ['ADMIN'] },
  { to: '/admin/invoices', icon: Receipt, label: 'Hóa đơn', roles: ['ADMIN'] },
  { to: '/admin/maintenance', icon: Wrench, label: 'Bảo trì', roles: ['ADMIN'] },
  { to: '/admin/fee-config', icon: Settings, label: 'Cài đặt phí', roles: ['ADMIN'] },
  { to: '/admin/users', icon: Users, label: 'Người dùng', roles: ['ADMIN'] },
  { to: '/admin/notifications', icon: Bell, label: 'Thông báo', roles: ['ADMIN'] },
  { to: '/tenant', icon: LayoutDashboard, label: 'Dashboard', roles: ['TENANT'] },
  { to: '/tenant/invoices', icon: Receipt, label: 'Hóa đơn', roles: ['TENANT'] },
  { to: '/tenant/maintenance', icon: Wrench, label: 'Bảo trì', roles: ['TENANT'] },
  { to: '/tenant/notifications', icon: Bell, label: 'Thông báo', roles: ['TENANT'] },
  { to: '/tech', icon: LayoutDashboard, label: 'Dashboard', roles: ['TECHNICIAN'] },
  { to: '/tech/maintenance', icon: Wrench, label: 'Công việc', roles: ['TECHNICIAN'] },
  { to: '/tech/notifications', icon: Bell, label: 'Thông báo', roles: ['TECHNICIAN'] },
]

export default function Layout({ children, title }: LayoutProps) {
  const { user, clearAuth } = useAuthStore()
  const location = useLocation()
  const role = user?.role || ''

  const filteredNav = navItems.filter(item => item.roles.includes(role))

  return (
    <div className="flex h-screen bg-gray-100">
      {/* Sidebar */}
      <aside className="w-64 bg-slate-800 text-white flex flex-col">
        <div className="p-6 border-b border-slate-700">
          <h1 className="text-xl font-bold">PropMS</h1>
          <p className="text-xs text-slate-400 mt-1">Property Management</p>
        </div>
        <nav className="flex-1 p-4 space-y-1">
          {filteredNav.map(item => {
            const Icon = item.icon
            const isActive = location.pathname === item.to || location.pathname.startsWith(item.to + '/')
            return (
              <Link
                key={item.to}
                to={item.to}
                className={cn(
                  'flex items-center gap-3 px-3 py-2 rounded-lg text-sm transition-colors',
                  isActive ? 'bg-blue-600 text-white' : 'hover:bg-slate-700'
                )}
              >
                <Icon size={18} />
                {item.label}
              </Link>
            )
          })}
        </nav>
        <div className="p-4 border-t border-slate-700">
          <div className="text-xs text-slate-400 mb-2">{user?.fullName}</div>
          <button onClick={clearAuth} className="flex items-center gap-2 text-sm hover:text-red-400 transition-colors">
            <LogOut size={16} />
            Đăng xuất
          </button>
        </div>
      </aside>

      {/* Main */}
      <div className="flex-1 flex flex-col overflow-hidden">
        <header className="bg-white border-b px-6 py-4 flex items-center justify-between">
          <h2 className="text-lg font-semibold text-gray-900">{title ?? 'PropMS'}</h2>
          <div className="flex items-center gap-2">
            <Bell size={18} className="text-gray-500 cursor-pointer hover:text-gray-700" />
          </div>
        </header>
        <main className="flex-1 overflow-auto p-6">
          {children}
        </main>
      </div>
    </div>
  )
}