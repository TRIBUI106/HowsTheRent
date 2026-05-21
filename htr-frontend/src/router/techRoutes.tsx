import { Route } from 'react-router-dom'
import RequireRole from './RequireRole'
import TechMaintenancePage from '@/pages/tech/MaintenancePage'
import TechNotificationsPage from '@/pages/tech/NotificationsPage'

const TECH = ['TECHNICIAN']

const techRoutes = [
  <Route key="/tech" path="/tech" element={<RequireRole roles={TECH}><TechMaintenancePage /></RequireRole>} />,
  <Route key="/tech/maintenance" path="/tech/maintenance" element={<RequireRole roles={TECH}><TechMaintenancePage /></RequireRole>} />,
  <Route key="/tech/notifications" path="/tech/notifications" element={<RequireRole roles={TECH}><TechNotificationsPage /></RequireRole>} />,
]

export default techRoutes
