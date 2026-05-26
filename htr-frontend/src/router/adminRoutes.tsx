import { Route } from 'react-router-dom'
import RequireRole from './RequireRole'
import AdminDashboard from '@/features/admin/pages/DashboardPage'
import PropertiesPage from '@/features/admin/pages/PropertiesPage'
import RoomsPage from '@/features/admin/pages/RoomsPage'
import ContractsPage from '@/features/admin/pages/ContractsPage'
import AdminInvoicesPage from '@/features/admin/pages/InvoicesPage'
import AdminMaintenancePage from '@/features/admin/pages/MaintenancePage'
import AdminNotificationsPage from '@/features/admin/pages/NotificationsPage'
import FeeConfigPage from '@/features/admin/pages/FeeConfigPage'
import UsersPage from '@/features/admin/pages/UsersPage'
import MeterReadingsPage from '@/features/admin/pages/MeterReadingsPage'
import VehicleConfigPage from '@/features/admin/pages/VehicleConfigPage'
import AuditLogPage from '@/features/admin/pages/AuditLogPage'
import RoomDetailPage from '@/features/admin/pages/RoomDetailPage'

const ADMIN = ['ADMIN']

const adminRoutes = [
  <Route key="/admin" path="/admin" element={<RequireRole roles={ADMIN}><AdminDashboard /></RequireRole>} />,
  <Route key="/admin/properties" path="/admin/properties" element={<RequireRole roles={ADMIN}><PropertiesPage /></RequireRole>} />,
  <Route key="/admin/rooms" path="/admin/rooms" element={<RequireRole roles={ADMIN}><RoomsPage /></RequireRole>} />,
  <Route key="/admin/rooms/:propertyId/:roomId" path="/admin/rooms/:propertyId/:roomId" element={<RequireRole roles={ADMIN}><RoomDetailPage /></RequireRole>} />,
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
