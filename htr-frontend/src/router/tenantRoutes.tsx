import { Route } from 'react-router-dom'
import RequireRole from './RequireRole'
import TenantDashboard from '@/features/tenant/pages/DashboardPage'
import TenantInvoicesPage from '@/features/tenant/pages/InvoicesPage'
import TenantMaintenancePage from '@/features/tenant/pages/MaintenancePage'
import TenantNotificationsPage from '@/features/tenant/pages/NotificationsPage'
import TenantContractDetailPage from '@/features/tenant/pages/ContractDetailPage'
import TenantPaymentHistoryPage from '@/features/tenant/pages/PaymentHistoryPage'

const TENANT = ['TENANT']

const tenantRoutes = [
  <Route key="/tenant" path="/tenant" element={<RequireRole roles={TENANT}><TenantDashboard /></RequireRole>} />,
  <Route key="/tenant/invoices" path="/tenant/invoices" element={<RequireRole roles={TENANT}><TenantInvoicesPage /></RequireRole>} />,
  <Route key="/tenant/maintenance" path="/tenant/maintenance" element={<RequireRole roles={TENANT}><TenantMaintenancePage /></RequireRole>} />,
  <Route key="/tenant/notifications" path="/tenant/notifications" element={<RequireRole roles={TENANT}><TenantNotificationsPage /></RequireRole>} />,
  <Route key="/tenant/contract" path="/tenant/contract" element={<RequireRole roles={TENANT}><TenantContractDetailPage /></RequireRole>} />,
  <Route key="/tenant/payment-history" path="/tenant/payment-history" element={<RequireRole roles={TENANT}><TenantPaymentHistoryPage /></RequireRole>} />,
]

export default tenantRoutes
