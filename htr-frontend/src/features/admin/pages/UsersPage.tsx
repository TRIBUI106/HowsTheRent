import { useState } from 'react'
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import Layout from '@/components/Layout'
import { Card } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { Badge } from '@/components/ui/badge'
import { TableSkeleton } from '@/components/ui/feedback'
import { Table, TableRow, TableCell } from '@/components/ui/table'
import { userApi } from '@/api'
import type { User } from '@/types'

const ROLES = ['ALL', 'ADMIN', 'TENANT', 'TECHNICIAN'] as const
const ROLE_LABELS: Record<string, string> = {
  ALL: 'Tất cả',
  ADMIN: 'Quản lý',
  TENANT: 'Khách thuê',
  TECHNICIAN: 'Kỹ thuật viên',
}

export default function UsersPage() {
  const qc = useQueryClient()
  const [roleFilter, setRoleFilter] = useState<string>('ALL')

  const { data: users = [], isLoading } = useQuery<User[]>({
    queryKey: ['admin-users'],
    queryFn: () => userApi.listAll(),
  })

  const toggleActiveMutation = useMutation({
    mutationFn: ({ id, active }: { id: string; active: boolean }) =>
      userApi.update(id, { active }),
    onSuccess: () => qc.invalidateQueries({ queryKey: ['admin-users'] }),
  })

  const changeRoleMutation = useMutation({
    mutationFn: ({ id, role }: { id: string; role: string }) =>
      userApi.update(id, { role }),
    onSuccess: () => qc.invalidateQueries({ queryKey: ['admin-users'] }),
  })

  const filtered = roleFilter === 'ALL' ? users : users.filter(u => u.role === roleFilter)

  return (
    <Layout title="Người dùng">
      <div className="space-y-4">
        <div className="flex flex-wrap items-center justify-between gap-3">
          <p className="text-sm text-fg-muted">{filtered.length} người dùng</p>
          <div className="flex gap-1.5">
            {ROLES.map(r => (
              <button
                key={r}
                onClick={() => setRoleFilter(r)}
                className={`px-3 py-1.5 rounded-lg text-xs font-medium transition-colors ${
                  roleFilter === r
                    ? 'bg-accent text-accent-fg'
                    : 'bg-sidebar text-fg-muted hover:bg-border/40 hover:text-fg'
                }`}
              >
                {ROLE_LABELS[r]}
              </button>
            ))}
          </div>
        </div>

        {isLoading ? (
          <TableSkeleton rows={6} columns={6} />
        ) : (
          <Card>
            <Table headers={['Họ tên', 'Email', 'Điện thoại', 'Vai trò', 'Trạng thái', '']}>
              {filtered.map(u => (
                <TableRow key={u.id}>
                  <TableCell className="font-medium text-fg">{u.fullName}</TableCell>
                  <TableCell className="text-fg-muted">{u.email}</TableCell>
                  <TableCell className="text-fg-muted">{u.phone ?? '—'}</TableCell>
                  <TableCell>
                    <select
                      className="text-xs border border-border rounded px-2 py-1 bg-surface text-fg focus:outline-none focus:border-accent"
                      value={u.role}
                      onChange={e => changeRoleMutation.mutate({ id: u.id, role: e.target.value })}
                    >
                      <option value="ADMIN">Quản lý</option>
                      <option value="TENANT">Khách thuê</option>
                      <option value="TECHNICIAN">Kỹ thuật viên</option>
                    </select>
                  </TableCell>
                  <TableCell>
                    <Badge status={u.active ? 'ACTIVE' : 'INACTIVE'} />
                  </TableCell>
                  <TableCell>
                    <Button
                      size="sm"
                      variant={u.active ? 'outline' : 'primary'}
                      onClick={() => toggleActiveMutation.mutate({ id: u.id, active: !u.active })}
                      disabled={toggleActiveMutation.isPending}
                    >
                      {u.active ? 'Vô hiệu hóa' : 'Kích hoạt'}
                    </Button>
                  </TableCell>
                </TableRow>
              ))}
              {filtered.length === 0 && (
                <TableRow>
                  <TableCell className="text-center text-fg-subtle py-8 col-span-6">
                    Không có người dùng
                  </TableCell>
                </TableRow>
              )}
            </Table>
          </Card>
        )}
      </div>
    </Layout>
  )
}
