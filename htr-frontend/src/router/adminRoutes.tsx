import { Route } from 'react-router-dom'
import RequireRole from './RequireRole'
import AdminDashboard from '@/pages/admin/DashboardPage'
import PropertiesPage from '@/pages/admin/PropertiesPage'
import RoomsPage from '@/pages/admin/RoomsPage'
import ContractsPage from '@/pages/admin/ContractsPage'
import AdminInvoicesPage from '@/pages/admin/InvoicesPage'
import AdminMaintenancePage from '@/pages/admin/MaintenancePage'
import AdminNotificationsPage from '@/pages/admin/NotificationsPage'
import FeeConfigPage from '@/pages/admin/FeeConfigPage'
import UsersPage from '@/pages/admin/UsersPage'
import MeterReadingsPage from '@/pages/admin/MeterReadingsPage'
import VehicleConfigPage from '@/pages/admin/VehicleConfigPage'
import AuditLogPage from '@/pages/admin/AuditLogPage'

const ADMIN = ['ADMIN']

export default function AdminRoutes() {
  return (
    <>
      <Route path="/admin" element={<RequireRole roles={ADMIN}><AdminDashboard /></RequireRole>} />
      <Route path="/admin/properties" element={<RequireRole roles={ADMIN}><PropertiesPage /></RequireRole>} />
      <Route path="/admin/rooms" element={<RequireRole roles={ADMIN}><RoomsPage /></RequireRole>} />
      <Route path="/admin/contracts" element={<RequireRole roles={ADMIN}><ContractsPage /></RequireRole>} />
      <Route path="/admin/invoices" element={<RequireRole roles={ADMIN}><AdminInvoicesPage /></RequireRole>} />
      <Route path="/admin/maintenance" element={<RequireRole roles={ADMIN}><AdminMaintenancePage /></RequireRole>} />
      <Route path="/admin/notifications" element={<RequireRole roles={ADMIN}><AdminNotificationsPage /></RequireRole>} />
      <Route path="/admin/fee-config" element={<RequireRole roles={ADMIN}><FeeConfigPage /></RequireRole>} />
      <Route path="/admin/users" element={<RequireRole roles={ADMIN}><UsersPage /></RequireRole>} />
      <Route path="/admin/meter-readings" element={<RequireRole roles={ADMIN}><MeterReadingsPage /></RequireRole>} />
      <Route path="/admin/vehicle-config" element={<RequireRole roles={ADMIN}><VehicleConfigPage /></RequireRole>} />
      <Route path="/admin/audit-log" element={<RequireRole roles={ADMIN}><AuditLogPage /></RequireRole>} />
    </>
  )
}
