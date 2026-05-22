import { Link, useLocation, useNavigate } from 'react-router-dom'
import { useAuthStore } from '@/stores/authStore'
import { LogOut } from 'lucide-react'
import logoHtr from '@/assets/logo-htr.png'
import { cn } from '@/lib/utils'
import { navItems } from './navItems'
import api from '@/lib/api'

export default function Sidebar() {
  const { user, clearAuth } = useAuthStore()
  const location = useLocation()
  const navigate = useNavigate()
  const role = user?.role ?? ''

  const handleLogout = async () => {
    try {
      await api.post('/auth/logout')
    } finally {
      clearAuth()
      navigate('/login', { replace: true })
    }
  }
  const filteredNav = navItems.filter(item => item.roles.includes(role))

  return (
    <aside className="w-64 bg-sidebar/92 border-r border-border/80 flex flex-col shrink-0 backdrop-blur-sm">
      <div className="px-4 py-4 border-b border-border/80">
        <div className="flex items-center gap-3">
          <Link to="/" className="shrink-0 rounded-xl focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-accent focus-visible:ring-offset-2 focus-visible:ring-offset-sidebar">
            <img src={logoHtr} alt="HowsTheRent" className="h-8 w-8 rounded-xl object-cover shadow-[0_1px_2px_rgba(15,23,42,0.08)]" />
          </Link>
          <div className="min-w-0">
            <p className="font-semibold text-sm text-fg leading-none truncate">How's The Rent</p>
            <p className="text-xs text-fg-subtle mt-1">Bảng vận hành nhà trọ</p>
          </div>
        </div>
      </div>

      <nav className="flex-1 overflow-y-auto px-3 py-3 space-y-1">
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
                'flex items-center gap-3 px-3 py-2.5 rounded-xl text-sm transition-colors duration-100',
                isActive
                  ? 'bg-surface text-fg shadow-[0_1px_2px_rgba(15,23,42,0.04)] ring-1 ring-border/90'
                  : 'text-fg-muted hover:bg-surface/70 hover:text-fg'
              )}
            >
              <span className={cn(
                'inline-flex h-7 w-7 items-center justify-center rounded-lg border transition-colors',
                isActive
                  ? 'border-accent/15 bg-accent-surface text-accent'
                  : 'border-transparent bg-transparent text-fg-subtle'
              )}>
                <Icon size={15} />
              </span>
              <span className="truncate">{item.label}</span>
            </Link>
          )
        })}
      </nav>

      <div className="px-3 py-3 border-t border-border/80">
        <div className="rounded-2xl border border-border/80 bg-surface/80 p-3">
          <div className="flex items-center gap-2.5 mb-3">
            <div className="w-8 h-8 bg-accent-surface text-accent rounded-full flex items-center justify-center text-xs font-semibold shrink-0">
              {user?.fullName?.charAt(0).toUpperCase()}
            </div>
            <div className="min-w-0">
              <p className="text-sm font-medium text-fg truncate leading-none mb-1">{user?.fullName}</p>
              <p className="text-xs text-fg-subtle truncate">{user?.email}</p>
            </div>
          </div>
          <button
            onClick={handleLogout}
            className="flex items-center gap-2 text-xs text-fg-subtle hover:text-error transition-colors w-full rounded-lg px-2 py-1.5 hover:bg-error-surface/80"
          >
            <LogOut size={13} />
            Đăng xuất
          </button>
        </div>
      </div>
    </aside>
  )
}
