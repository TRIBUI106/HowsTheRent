import { useNavigate, Link } from 'react-router-dom'
import { useQuery } from '@tanstack/react-query'
import { KeyRound, LogOut } from 'lucide-react'
import Layout from '@/components/Layout'
import { Card, CardContent, CardHeader } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import { Button } from '@/components/ui/button'
import { DetailSkeleton } from '@/components/ui/feedback'
import { useAuthStore } from '@/stores/authStore'
import api from '@/lib/api'
import { extractPageContent, normalizeContract } from '@/lib/apiMappers'
import type { FlatContractLike } from '@/lib/apiMappers'
import { formatDate, formatCurrency } from '@/lib/utils'

const roleLabel: Record<string, string> = {
  ADMIN: 'Quản trị viên',
  TENANT: 'Khách thuê',
  TECHNICIAN: 'Kỹ thuật viên',
}

export default function ProfilePage() {
  const { user, clearAuth } = useAuthStore()
  const navigate = useNavigate()
  const isTenant = user?.role === 'TENANT'

  const { data, isLoading } = useQuery<FlatContractLike[]>({
    queryKey: ['tenant-contracts'],
    queryFn: () => api.get<FlatContractLike[]>('/contracts/mine').then(r => r.data),
    enabled: isTenant,
  })

  const activeContract = isTenant
    ? extractPageContent<FlatContractLike>(data).map(normalizeContract).find(c => c.status === 'ACTIVE')
    : undefined

  const handleLogout = async () => {
    try {
      await api.post('/auth/logout')
    } finally {
      clearAuth()
      navigate('/login', { replace: true })
    }
  }

  return (
    <Layout title="Hồ sơ của tôi">
      <div className="max-w-2xl space-y-5">
        <Card>
          <CardHeader className="flex flex-row items-center justify-between">
            <span>Thông tin tài khoản</span>
            <Badge className="bg-accent-surface text-accent">{roleLabel[user?.role ?? ''] ?? user?.role}</Badge>
          </CardHeader>
          <CardContent className="space-y-4">
            <div className="flex items-center gap-3">
              <div className="w-12 h-12 bg-accent-surface text-accent rounded-full flex items-center justify-center text-lg font-semibold shrink-0">
                {user?.fullName?.charAt(0).toUpperCase()}
              </div>
              <div className="min-w-0">
                <p className="font-medium text-fg truncate">{user?.fullName}</p>
                <p className="text-sm text-fg-muted truncate">{user?.email}</p>
              </div>
            </div>
            <div className="grid grid-cols-2 gap-4">
              <div>
                <p className="mb-1 text-xs text-fg-muted">Email</p>
                <p className="font-medium text-fg">{user?.email || '-'}</p>
              </div>
              <div>
                <p className="mb-1 text-xs text-fg-muted">Số điện thoại</p>
                <p className="font-medium text-fg">{user?.phone || '-'}</p>
              </div>
            </div>
            <div className="flex flex-col sm:flex-row gap-2 pt-2">
              <Link to="/change-password" className="flex-1">
                <Button variant="secondary" className="w-full">
                  <KeyRound size={15} />
                  Đổi mật khẩu
                </Button>
              </Link>
              <Button variant="danger" className="flex-1" onClick={handleLogout}>
                <LogOut size={15} />
                Đăng xuất
              </Button>
            </div>
          </CardContent>
        </Card>

        {isTenant && (
          <Card>
            <CardHeader className="flex flex-row items-center justify-between">
              <span>Hợp đồng thuê phòng</span>
              {activeContract && <Badge status={activeContract.status} />}
            </CardHeader>
            <CardContent>
              {isLoading ? (
                <DetailSkeleton />
              ) : !activeContract ? (
                <div className="py-6 text-center text-fg-subtle">Không có hợp đồng đang hoạt động</div>
              ) : (
                <div className="grid grid-cols-2 gap-4">
                  <div>
                    <p className="mb-1 text-xs text-fg-muted">Phòng</p>
                    <p className="font-medium text-fg">{activeContract.room.roomNumber || '-'}</p>
                  </div>
                  <div>
                    <p className="mb-1 text-xs text-fg-muted">Tòa nhà</p>
                    <p className="font-medium text-fg">{activeContract.room.propertyName || '-'}</p>
                  </div>
                  <div>
                    <p className="mb-1 text-xs text-fg-muted">Ngày vào</p>
                    <p className="font-medium text-fg">{activeContract.moveInDate ? formatDate(activeContract.moveInDate) : '-'}</p>
                  </div>
                  <div>
                    <p className="mb-1 text-xs text-fg-muted">Ngày kết thúc</p>
                    <p className="font-medium text-fg">{activeContract.moveOutDate ? formatDate(activeContract.moveOutDate) : 'Không xác định'}</p>
                  </div>
                  <div>
                    <p className="mb-1 text-xs text-fg-muted">Tiền cọc</p>
                    <p className="font-medium text-fg">{formatCurrency(activeContract.depositAmount ?? 0)}</p>
                  </div>
                </div>
              )}
            </CardContent>
          </Card>
        )}
      </div>
    </Layout>
  )
}
