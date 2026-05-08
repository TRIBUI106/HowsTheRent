import { Routes, Route, Navigate } from 'react-router-dom'
import type { ReactNode } from 'react'
import { useAuthStore } from '@/stores/authStore'

// Auth
import LoginPage from '@/pages/auth/LoginPage'

// Admin
import AdminDashboard from '@/pages/admin/DashboardPage'
import PropertiesPage from '@/pages/admin/PropertiesPage'
import RoomsPage from '@/pages/admin/RoomsPage'
import ContractsPage from '@/pages/admin/ContractsPage'
import AdminInvoicesPage from '@/pages/admin/InvoicesPage'
import AdminMaintenancePage from '@/pages/admin/MaintenancePage'
import AdminNotificationsPage from '@/pages/admin/NotificationsPage'
import FeeConfigPage from '@/pages/admin/FeeConfigPage'
import UsersPage from '@/pages/admin/UsersPage'

// Tenant
import TenantDashboard from '@/pages/tenant/DashboardPage'
import TenantInvoicesPage from '@/pages/tenant/InvoicesPage'
import TenantMaintenancePage from '@/pages/tenant/MaintenancePage'
import TenantNotificationsPage from '@/pages/tenant/NotificationsPage'

// Tech
import TechMaintenancePage from '@/pages/tech/MaintenancePage'
import TechNotificationsPage from '@/pages/tech/NotificationsPage'

function RequireRole({ roles, children }: { roles: string[]; children: ReactNode }) {
  const { user } = useAuthStore()
  if (!user || !roles.includes(user.role)) return <Navigate to="/login" replace />
  return children
}

export default function App() {
  const { accessToken, user } = useAuthStore()

  if (!accessToken) {
    return (
      <Routes>
        <Route path="/login" element={<LoginPage />} />
        <Route path="*" element={<Navigate to="/login" replace />} />
      </Routes>
    )
  }

  const role = user?.role

  return (
    <Routes>
      {/* Admin routes */}
      <Route path="/admin" element={<RequireRole roles={['ADMIN']}><AdminDashboard /></RequireRole>} />
      <Route path="/admin/properties" element={<RequireRole roles={['ADMIN']}><PropertiesPage /></RequireRole>} />
      <Route path="/admin/rooms" element={<RequireRole roles={['ADMIN']}><RoomsPage /></RequireRole>} />
      <Route path="/admin/invoices" element={<RequireRole roles={['ADMIN']}><AdminInvoicesPage /></RequireRole>} />
      <Route path="/admin/maintenance" element={<RequireRole roles={['ADMIN']}><AdminMaintenancePage /></RequireRole>} />
      <Route path="/admin/notifications" element={<RequireRole roles={['ADMIN']}><AdminNotificationsPage /></RequireRole>} />
      <Route path="/admin/contracts" element={<RequireRole roles={['ADMIN']}><ContractsPage /></RequireRole>} />
      <Route path="/admin/fee-config" element={<RequireRole roles={['ADMIN']}><FeeConfigPage /></RequireRole>} />
      <Route path="/admin/users" element={<RequireRole roles={['ADMIN']}><UsersPage /></RequireRole>} />

      {/* Tenant routes */}
      <Route path="/tenant" element={<RequireRole roles={['TENANT']}><TenantDashboard /></RequireRole>} />
      <Route path="/tenant/invoices" element={<RequireRole roles={['TENANT']}><TenantInvoicesPage /></RequireRole>} />
      <Route path="/tenant/maintenance" element={<RequireRole roles={['TENANT']}><TenantMaintenancePage /></RequireRole>} />
      <Route path="/tenant/notifications" element={<RequireRole roles={['TENANT']}><TenantNotificationsPage /></RequireRole>} />

      {/* Tech routes */}
      <Route path="/tech" element={<RequireRole roles={['TECHNICIAN']}><TechMaintenancePage /></RequireRole>} />
      <Route path="/tech/maintenance" element={<RequireRole roles={['TECHNICIAN']}><TechMaintenancePage /></RequireRole>} />
      <Route path="/tech/notifications" element={<RequireRole roles={['TECHNICIAN']}><TechNotificationsPage /></RequireRole>} />

      {/* Default redirect by role */}
      <Route path="*" element={<Navigate to={role === 'ADMIN' ? '/admin' : role === 'TENANT' ? '/tenant' : '/tech'} replace />} />
    </Routes>
  )
}