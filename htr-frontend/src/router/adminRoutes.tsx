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

const adminRoutes = [
  <Route key="/admin" path="/admin" element={<RequireRole roles={ADMIN}><AdminDashboard /></RequireRole>} />,
  <Route key="/admin/properties" path="/admin/properties" element={<RequireRole roles={ADMIN}><PropertiesPage /></RequireRole>} />,
  <Route key="/admin/rooms" path="/admin/rooms" element={<RequireRole roles={ADMIN}><RoomsPage /></RequireRole>} />,
  <Route key="/admin/contracts" path="/admin/contracts" element={<RequireRole roles={ADMIN}><ContractsPage /></RequireRole>} />,
  <Route key="/admin/invoices" path="/admin/invoices" element={<RequireRole roles={ADMIN}><AdminInvoicesPage /></RequireRole>} />,
  <Route key="/admin/maintenance" path="/admin/maintenance" element={<RequireRole roles={ADMIN}><AdminMaintenancePage /></RequireRole>} />,
  <Route key="/admin/notifications" path="/admin/notifications" element={<RequireRole roles={ADMIN}><AdminNotificationsPage /></RequireRole>} />,
  <Route key="/admin/fee-config" path="/admin/fee-config" element={<RequireRole roles={ADMIN}><FeeConfigPage /></RequireRole>} />,
  <Route key="/admin/users" path="/admin/users" element={<RequireRole roles={ADMIN}><UsersPage /></RequireRole>} />,
  <Route key="/admin/meter-readings" path="/admin/meter-readings" element={<RequireRole roles={ADMIN}><MeterReadingsPage /></RequireRole>} />,
  <Route key="/admin/vehicle-config" path="/admin/vehicle-config" element={<RequireRole roles={ADMIN}><VehicleConfigPage /></RequireRole>} />,
  <Route key="/admin/audit-log" path="/admin/audit-log" element={<RequireRole roles={ADMIN}><AuditLogPage /></RequireRole>} />,
]

export default adminRoutes
