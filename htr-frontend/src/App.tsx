import { Routes, Route, Navigate } from 'react-router-dom'
import { useAuthStore } from '@/stores/authStore'
import LandingPage from '@/pages/LandingPage'
import LoginPage from '@/pages/auth/LoginPage'
import ForgotPasswordPage from '@/pages/auth/ForgotPasswordPage'
import ResetPasswordPage from '@/pages/auth/ResetPasswordPage'
import PaymentSuccessPage from '@/pages/payment/SuccessPage'
import PaymentCancelPage from '@/pages/payment/CancelPage'
import NotFoundPage from '@/pages/NotFoundPage'
import AdminRoutes from '@/router/adminRoutes'
import TenantRoutes from '@/router/tenantRoutes'
import TechRoutes from '@/router/techRoutes'

export default function App() {
  const { accessToken } = useAuthStore()

  if (!accessToken) {
    return (
      <Routes>
        <Route path="/" element={<LandingPage />} />
        <Route path="/login" element={<LoginPage />} />
        <Route path="/forgot-password" element={<ForgotPasswordPage />} />
        <Route path="/reset-password" element={<ResetPasswordPage />} />
        <Route path="/payment/success" element={<PaymentSuccessPage />} />
        <Route path="/payment/cancel" element={<PaymentCancelPage />} />
        <Route path="*" element={<Navigate to="/login" replace />} />
      </Routes>
    )
  }

  return (
    <Routes>
      <AdminRoutes />
      <TenantRoutes />
      <TechRoutes />
      <Route path="/payment/success" element={<PaymentSuccessPage />} />
      <Route path="/payment/cancel" element={<PaymentCancelPage />} />
      <Route path="*" element={<NotFoundPage />} />
    </Routes>
  )
}
