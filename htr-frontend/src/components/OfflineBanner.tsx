import { useOnlineStatus } from '@/hooks/useOnlineStatus'

export default function OfflineBanner() {
  const isOnline = useOnlineStatus()

  if (isOnline) return null

  return (
    <div className="fixed inset-x-0 top-0 z-50 bg-amber-500 px-4 py-2 text-center text-sm font-medium text-white">
      Không có kết nối mạng. Dữ liệu hiển thị có thể chưa cập nhật mới nhất
      và các thao tác chỉnh sửa tạm thời bị tắt.
    </div>
  )
}
