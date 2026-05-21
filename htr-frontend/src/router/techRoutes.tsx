import { Route } from 'react-router-dom'
import RequireRole from './RequireRole'
import TechMaintenancePage from '@/pages/tech/MaintenancePage'
import TechNotificationsPage from '@/pages/tech/NotificationsPage'

const TECH = ['TECHNICIAN']

export default function TechRoutes() {
  return (
    <>
      <Route path="/tech" element={<RequireRole roles={TECH}><TechMaintenancePage /></RequireRole>} />
      <Route path="/tech/maintenance" element={<RequireRole roles={TECH}><TechMaintenancePage /></RequireRole>} />
      <Route path="/tech/notifications" element={<RequireRole roles={TECH}><TechNotificationsPage /></RequireRole>} />
    </>
  )
}
