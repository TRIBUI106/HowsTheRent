import { useState } from 'react'
import { useQuery } from '@tanstack/react-query'
import api from '@/lib/api'
import Layout from '@/components/Layout'
import { Card } from '@/components/ui/card'
import { Pagination } from '@/components/ui/pagination'
import { formatDate } from '@/lib/utils'
import type { AuditLog } from '@/types'

const ACTION_LABELS: Record<string, string> = {
  CREATE: 'Tạo', UPDATE: 'Cập nhật', DELETE: 'Xóa',
  TERMINATE: 'Chấm dứt', RENEW: 'Gia hạn', PAYMENT: 'Thanh toán',
  UPLOAD: 'Tải lên', ASSIGN: 'Giao việc', RESOLVE: 'Hoàn thành',
  LOGIN: 'Đăng nhập', LOGOUT: 'Đăng xuất', RESET_PASSWORD: 'Đặt lại MK',
}

const ACTION_COLORS: Record<string, string> = {
  CREATE: 'text-green-600 bg-green-50',
  UPDATE: 'text-blue-600 bg-blue-50',
  DELETE: 'text-red-600 bg-red-50',
  TERMINATE: 'text-red-600 bg-red-50',
  RENEW: 'text-purple-600 bg-purple-50',
  PAYMENT: 'text-emerald-600 bg-emerald-50',
  UPLOAD: 'text-cyan-600 bg-cyan-50',
  ASSIGN: 'text-orange-600 bg-orange-50',
  RESOLVE: 'text-emerald-600 bg-emerald-50',
}

const ACTIONS = ['CREATE', 'UPDATE', 'DELETE', 'TERMINATE', 'RENEW', 'PAYMENT', 'UPLOAD', 'ASSIGN', 'RESOLVE']

export default function AuditLogPage() {
  const [page, setPage] = useState(0)
  const [actionFilter, setActionFilter] = useState('')

  const { data, isLoading } = useQuery({
    queryKey: ['audit-logs', page, actionFilter],
    queryFn: () => {
      const params = new URLSearchParams({ page: String(page), size: '20' })
      if (actionFilter) params.set('action', actionFilter)
      return api.get(`/audit?${params}`).then(r => r.data)
    },
  })

  const logs: AuditLog[] = Array.isArray(data) ? data : (data?.content ?? [])
  const totalPages: number = Array.isArray(data) ? 1 : (data?.totalPages ?? 1)

  return (
    <Layout title="Nhật ký hoạt động">
      <div className="p-6 space-y-4">
        <div className="flex items-center justify-between">
          <h1 className="text-2xl font-bold text-gray-900">Nhật ký hoạt động</h1>
          <div className="flex gap-2 flex-wrap">
            <button
              onClick={() => { setActionFilter(''); setPage(0) }}
              className={`px-3 py-1.5 rounded-lg text-sm font-medium transition-colors ${!actionFilter ? 'bg-indigo-600 text-white' : 'bg-gray-100 text-gray-600 hover:bg-gray-200'}`}
            >
              Tất cả
            </button>
            {ACTIONS.map(a => (
              <button
                key={a}
                onClick={() => { setActionFilter(a); setPage(0) }}
                className={`px-3 py-1.5 rounded-lg text-sm font-medium transition-colors ${actionFilter === a ? 'bg-indigo-600 text-white' : 'bg-gray-100 text-gray-600 hover:bg-gray-200'}`}
              >
                {ACTION_LABELS[a]}
              </button>
            ))}
          </div>
        </div>

        {isLoading ? (
          <div className="flex h-48 items-center justify-center">
            <div className="animate-spin h-6 w-6 border-2 border-indigo-600 border-t-transparent rounded-full" />
          </div>
        ) : logs.length === 0 ? (
          <div className="text-center py-12 text-gray-400">Không có bản ghi</div>
        ) : (
          <Card>
            <div className="divide-y divide-gray-100">
              {logs.map(log => (
                <div key={log.id} className="px-4 py-3 flex items-center gap-4 hover:bg-gray-50 transition-colors">
                  <span className={`shrink-0 px-2 py-1 rounded text-xs font-medium ${ACTION_COLORS[log.action] ?? 'text-gray-600 bg-gray-50'}`}>
                    {ACTION_LABELS[log.action] ?? log.action}
                  </span>
                  <div className="flex-1 min-w-0">
                    <p className="text-sm font-medium text-gray-900">{log.description}</p>
                    <p className="text-xs text-gray-500 mt-0.5">
                      {log.userEmail ?? 'Hệ thống'}
                      {log.entityType ? ` • ${log.entityType}` : ''}
                      {log.ipAddress ? ` • IP: ${log.ipAddress}` : ''}
                    </p>
                  </div>
                  <span className="text-xs text-gray-400 shrink-0">{formatDate(log.createdAt)}</span>
                </div>
              ))}
            </div>
            <div className="px-4 py-3 border-t">
              <Pagination page={page} totalPages={totalPages} onPageChange={setPage} />
            </div>
          </Card>
        )}
      </div>
    </Layout>
  )
}