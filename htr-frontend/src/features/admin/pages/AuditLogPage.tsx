import { useState } from 'react'
import { useQuery } from '@tanstack/react-query'
import api from '@/lib/api'
import Layout from '@/components/Layout'
import { Card } from '@/components/ui/card'
import { Pagination } from '@/components/ui/pagination'
import { ListSkeleton } from '@/components/ui/feedback'
import { formatDate } from '@/lib/utils'
import type { AuditLog } from '@/types'

const ACTION_LABELS: Record<string, string> = {
  CREATE: 'Tạo', UPDATE: 'Cập nhật', DELETE: 'Xóa',
  TERMINATE: 'Chấm dứt', RENEW: 'Gia hạn', PAYMENT: 'Thanh toán',
  UPLOAD: 'Tải lên', ASSIGN: 'Giao việc', RESOLVE: 'Hoàn thành',
  LOGIN: 'Đăng nhập', LOGOUT: 'Đăng xuất', RESET_PASSWORD: 'Đặt lại MK',
}

const ACTION_COLORS: Record<string, string> = {
  CREATE: 'text-success bg-success-surface',
  UPDATE: 'text-accent bg-accent-surface',
  DELETE: 'text-error bg-error-surface',
  TERMINATE: 'text-error bg-error-surface',
  RENEW: 'text-accent bg-accent-surface',
  PAYMENT: 'text-success bg-success-surface',
  UPLOAD: 'text-accent bg-accent-surface',
  ASSIGN: 'text-warning bg-warning-surface',
  RESOLVE: 'text-success bg-success-surface',
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
      <div className="space-y-4">
        <div className="flex items-center justify-between">
          <h1 className="text-2xl font-bold text-fg">Nhật ký hoạt động</h1>
          <div className="flex gap-2 flex-wrap">
            <button
              onClick={() => { setActionFilter(''); setPage(0) }}
              className={`px-3 py-1.5 rounded-xl text-sm font-medium transition-colors ${!actionFilter ? 'bg-accent text-accent-fg' : 'bg-sidebar text-fg-muted hover:bg-surface hover:text-fg'}`}
            >
              Tất cả
            </button>
            {ACTIONS.map(a => (
              <button
                key={a}
                onClick={() => { setActionFilter(a); setPage(0) }}
                className={`px-3 py-1.5 rounded-xl text-sm font-medium transition-colors ${actionFilter === a ? 'bg-accent text-accent-fg' : 'bg-sidebar text-fg-muted hover:bg-surface hover:text-fg'}`}
              >
                {ACTION_LABELS[a]}
              </button>
            ))}
          </div>
        </div>

        {isLoading ? (
          <ListSkeleton items={6} />
        ) : logs.length === 0 ? (
          <div className="text-center py-12 text-fg-subtle">Không có bản ghi</div>
        ) : (
          <Card>
            <div className="divide-y divide-border/60">
              {logs.map(log => (
                <div key={log.id} className="px-4 py-3 flex items-center gap-4 hover:bg-sidebar/50 transition-colors">
                  <span className={`shrink-0 px-2 py-1 rounded-lg text-xs font-medium ${ACTION_COLORS[log.action] ?? 'text-fg-muted bg-sidebar'}`}>
                    {ACTION_LABELS[log.action] ?? log.action}
                  </span>
                  <div className="flex-1 min-w-0">
                    <p className="text-sm font-medium text-fg">{log.description}</p>
                    <p className="text-xs text-fg-muted mt-0.5">
                      {log.userEmail ?? 'Hệ thống'}
                      {log.entityType ? ` · ${log.entityType}` : ''}
                      {log.ipAddress ? ` · IP: ${log.ipAddress}` : ''}
                    </p>
                  </div>
                  <span className="text-xs text-fg-subtle shrink-0">{formatDate(log.createdAt)}</span>
                </div>
              ))}
            </div>
            <div className="px-4 py-3 border-t border-border/60">
              <Pagination page={page} totalPages={totalPages} onPageChange={setPage} />
            </div>
          </Card>
        )}
      </div>
    </Layout>
  )
}
