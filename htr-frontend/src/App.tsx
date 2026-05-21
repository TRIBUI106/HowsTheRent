import { Routes, Route, Navigate } from 'react-router-dom'
import { useAuthStore } from '@/stores/authStore'
import LandingPage from '@/pages/LandingPage'
import LoginPage from '@/features/auth/pages/LoginPage'
import ForgotPasswordPage from '@/features/auth/pages/ForgotPasswordPage'
import ResetPasswordPage from '@/features/auth/pages/ResetPasswordPage'
import PaymentSuccessPage from '@/features/payment/pages/SuccessPage'
import PaymentCancelPage from '@/features/payment/pages/CancelPage'
import NotFoundPage from '@/pages/NotFoundPage'
import adminRoutes from '@/router/adminRoutes'
import tenantRoutes from '@/router/tenantRoutes'
import techRoutes from '@/router/techRoutes'

export default function App() {
  const { accessToken, user } = useAuthStore()

  if (!accessToken) {
    return (
      <Routes>
        <Route path="/" element={<LandingPage />} />
        <Route path="/landing" element={<LandingPage />} />
        <Route path="/login" element={<LoginPage />} />
        <Route path="/forgot-password" element={<ForgotPasswordPage />} />
        <Route path="/reset-password" element={<ResetPasswordPage />} />
        <Route path="/payment/success" element={<PaymentSuccessPage />} />
        <Route path="/payment/cancel" element={<PaymentCancelPage />} />
        <Route path="*" element={<Navigate to="/login" replace />} />
      </Routes>
    )
  }

  const homePath =
    user?.role === 'ADMIN' ? '/admin' :
    user?.role === 'TENANT' ? '/tenant' :
    '/tech'

  return (
    <Routes>
      <Route path="/" element={<Navigate to={homePath} replace />} />
      <Route path="/landing" element={<LandingPage />} />
      {adminRoutes}
      {tenantRoutes}
      {techRoutes}
      <Route path="/payment/success" element={<PaymentSuccessPage />} />
      <Route path="/payment/cancel" element={<PaymentCancelPage />} />
      <Route path="*" element={<NotFoundPage />} />
    </Routes>
  )
}
