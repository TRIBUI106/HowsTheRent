import { Route } from 'react-router-dom'
import RequireRole from './RequireRole'
import TenantDashboard from '@/pages/tenant/DashboardPage'
import TenantInvoicesPage from '@/pages/tenant/InvoicesPage'
import TenantMaintenancePage from '@/pages/tenant/MaintenancePage'
import TenantNotificationsPage from '@/pages/tenant/NotificationsPage'
import TenantContractDetailPage from '@/pages/tenant/ContractDetailPage'
import TenantPaymentHistoryPage from '@/pages/tenant/PaymentHistoryPage'

const TENANT = ['TENANT']

export default function TenantRoutes() {
  return (
    <>
      <Route path="/tenant" element={<RequireRole roles={TENANT}><TenantDashboard /></RequireRole>} />
      <Route path="/tenant/invoices" element={<RequireRole roles={TENANT}><TenantInvoicesPage /></RequireRole>} />
      <Route path="/tenant/maintenance" element={<RequireRole roles={TENANT}><TenantMaintenancePage /></RequireRole>} />
      <Route path="/tenant/notifications" element={<RequireRole roles={TENANT}><TenantNotificationsPage /></RequireRole>} />
      <Route path="/tenant/contract" element={<RequireRole roles={TENANT}><TenantContractDetailPage /></RequireRole>} />
      <Route path="/tenant/payment-history" element={<RequireRole roles={TENANT}><TenantPaymentHistoryPage /></RequireRole>} />
    </>
  )
}
