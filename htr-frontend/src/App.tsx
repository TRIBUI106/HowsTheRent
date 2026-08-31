import { Routes, Route, Navigate } from 'react-router-dom'
import { useAuthStore } from '@/stores/authStore'
import { homePathForRole } from '@/lib/homePath'
import OfflineBanner from '@/components/OfflineBanner'
import LandingPage from '@/pages/LandingPage'
import LoginPage from '@/features/auth/pages/LoginPage'
import ForgotPasswordPage from '@/features/auth/pages/ForgotPasswordPage'
import ResetPasswordPage from '@/features/auth/pages/ResetPasswordPage'
import ChangePasswordPage from '@/features/auth/pages/ChangePasswordPage'
import ProfilePage from '@/features/auth/pages/ProfilePage'
import PaymentSuccessPage from '@/features/payment/pages/SuccessPage'
import PaymentCancelPage from '@/features/payment/pages/CancelPage'
import NotFoundPage from '@/pages/NotFoundPage'
import BlogListPage from '@/pages/blog/BlogListPage'
import BlogPostPage from '@/pages/blog/BlogPostPage'
import RegisterGuestPage from '@/features/auth/pages/RegisterGuestPage'
import adminRoutes from '@/router/adminRoutes'
import tenantRoutes from '@/router/tenantRoutes'
import techRoutes from '@/router/techRoutes'

export default function App() {
  const { user } = useAuthStore()

  if (!user) {
    return (
      <>
        <OfflineBanner />
        <Routes>
          <Route path="/" element={<LandingPage />} />
          <Route path="/login" element={<LoginPage />} />
          <Route path="/forgot-password" element={<ForgotPasswordPage />} />
          <Route path="/reset-password" element={<ResetPasswordPage />} />
          <Route path="/payment/success" element={<PaymentSuccessPage />} />
          <Route path="/payment/cancel" element={<PaymentCancelPage />} />
          <Route path="/blog" element={<BlogListPage />} />
          <Route path="/blog/register" element={<RegisterGuestPage />} />
          <Route path="/blog/:slug" element={<BlogPostPage />} />
          <Route path="*" element={<Navigate to="/login" replace />} />
        </Routes>
      </>
    )
  }

  const homePath = homePathForRole(user.role)

  return (
    <>
      <OfflineBanner />
      <Routes>
        <Route path="/" element={<LandingPage />} />
        <Route path="/login" element={<Navigate to={homePath} replace />} />
        <Route path="/landing" element={<LandingPage />} />
        <Route path="/change-password" element={<ChangePasswordPage />} />
        <Route path="/profile" element={<ProfilePage />} />
        <Route path="/blog" element={<BlogListPage />} />
        <Route path="/blog/:slug" element={<BlogPostPage />} />
        {adminRoutes}
        {tenantRoutes}
        {techRoutes}
        <Route path="/payment/success" element={<PaymentSuccessPage />} />
        <Route path="/payment/cancel" element={<PaymentCancelPage />} />
        <Route path="*" element={<NotFoundPage />} />
      </Routes>
    </>
  )
}
