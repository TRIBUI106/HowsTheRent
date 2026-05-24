import { useMemo, useState } from 'react'
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import Layout from '@/components/Layout'
import { Card } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { Badge } from '@/components/ui/badge'
import { Dialog } from '@/components/ui/dialog'
import { Input } from '@/components/ui/input'
import { TableSkeleton } from '@/components/ui/feedback'
import { Table, TableRow, TableCell } from '@/components/ui/table'
import { userApi } from '@/api'
import type { User } from '@/types'

const FILTER_ROLES = ['ALL', 'ADMIN', 'TENANT', 'TECHNICIAN'] as const
const USER_ROLES = ['ADMIN', 'TENANT', 'TECHNICIAN'] as const

const ROLE_LABELS: Record<(typeof FILTER_ROLES)[number], string> = {
  ALL: 'Tất cả',
  ADMIN: 'Quản lý',
  TENANT: 'Khách thuê',
  TECHNICIAN: 'Kỹ thuật viên',
}

const emptyCreateForm = {
  fullName: '',
  email: '',
  phone: '',
  password: '',
  role: 'TENANT' as User['role'],
}

const emptyEditForm = {
  fullName: '',
  phone: '',
  role: 'TENANT' as User['role'],
}

export default function UsersPage() {
  const qc = useQueryClient()
  const [roleFilter, setRoleFilter] = useState<(typeof FILTER_ROLES)[number]>('ALL')
  const [showCreate, setShowCreate] = useState(false)
  const [editingUser, setEditingUser] = useState<User | null>(null)
  const [createForm, setCreateForm] = useState(emptyCreateForm)
  const [editForm, setEditForm] = useState(emptyEditForm)

  const { data: users = [], isLoading } = useQuery<User[]>({
    queryKey: ['admin-users'],
    queryFn: () => userApi.listAll(),
  })

  const refreshUsers = () => qc.invalidateQueries({ queryKey: ['admin-users'] })

  const createUserMutation = useMutation({
    mutationFn: () => userApi.create(createForm),
    onSuccess: () => {
      refreshUsers()
      setShowCreate(false)
      setCreateForm(emptyCreateForm)
    },
  })

  const updateUserMutation = useMutation({
    mutationFn: () => {
      if (!editingUser) {
        return Promise.reject(new Error('No user selected'))
      }
      return userApi.update(editingUser.id, editForm)
    },
    onSuccess: () => {
      refreshUsers()
      setEditingUser(null)
      setEditForm(emptyEditForm)
    },
  })

  const toggleActiveMutation = useMutation({
    mutationFn: (id: string) => userApi.toggleActive(id),
    onSuccess: () => refreshUsers(),
  })

  const filtered = useMemo(
    () => (roleFilter === 'ALL' ? users : users.filter(u => u.role === roleFilter)),
    [users, roleFilter],
  )

  function openCreateModal() {
    setCreateForm(emptyCreateForm)
    setShowCreate(true)
  }

  function openEditModal(user: User) {
    setEditingUser(user)
    setEditForm({
      fullName: user.fullName,
      phone: user.phone ?? '',
      role: user.role,
    })
  }

  return (
    <Layout title="Người dùng">
      <div className="space-y-4">
        <div className="flex flex-wrap items-center justify-between gap-3">
          <p className="text-sm text-fg-muted">{filtered.length} người dùng</p>
          <div className="flex items-center gap-2">
            <div className="flex gap-1.5">
              {FILTER_ROLES.map(r => (
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
            <Button size="sm" onClick={openCreateModal}>+ Thêm người dùng</Button>
          </div>
        </div>

        {isLoading ? (
          <TableSkeleton rows={6} columns={7} />
        ) : (
          <Card>
            <Table headers={['Họ tên', 'Email', 'Điện thoại', 'Vai trò', 'Trạng thái', 'Sửa', 'Kích hoạt']}>
              {filtered.map(u => (
                <TableRow key={u.id}>
                  <TableCell className="font-medium text-fg">{u.fullName}</TableCell>
                  <TableCell className="text-fg-muted">{u.email}</TableCell>
                  <TableCell className="text-fg-muted">{u.phone ?? '—'}</TableCell>
                  <TableCell>{ROLE_LABELS[u.role]}</TableCell>
                  <TableCell>
                    <Badge status={u.active ? 'ACTIVE' : 'INACTIVE'} />
                  </TableCell>
                  <TableCell>
                    <Button type="button" size="sm" variant="secondary" onClick={() => openEditModal(u)}>
                      Sửa
                    </Button>
                  </TableCell>
                  <TableCell>
                    <Button
                      size="sm"
                      variant={u.active ? 'outline' : 'primary'}
                      onClick={() => toggleActiveMutation.mutate(u.id)}
                      disabled={toggleActiveMutation.isPending}
                    >
                      {u.active ? 'Vô hiệu hóa' : 'Kích hoạt'}
                    </Button>
                  </TableCell>
                </TableRow>
              ))}
              {filtered.length === 0 && (
                <TableRow>
                  <TableCell className="text-center text-fg-subtle py-8 col-span-7">
                    Không có người dùng
                  </TableCell>
                </TableRow>
              )}
            </Table>
          </Card>
        )}
      </div>

      <Dialog open={showCreate} onClose={() => setShowCreate(false)} title="Tạo người dùng mới">
        <form
          onSubmit={(e) => {
            e.preventDefault()
            createUserMutation.mutate()
          }}
          className="space-y-4"
        >
          <Input label="Họ tên" value={createForm.fullName} onChange={(e) => setCreateForm((p) => ({ ...p, fullName: e.target.value }))} required />
          <Input label="Email" type="email" value={createForm.email} onChange={(e) => setCreateForm((p) => ({ ...p, email: e.target.value }))} required />
          <Input label="Điện thoại" value={createForm.phone} onChange={(e) => setCreateForm((p) => ({ ...p, phone: e.target.value }))} />
          <Input label="Mật khẩu" type="password" value={createForm.password} onChange={(e) => setCreateForm((p) => ({ ...p, password: e.target.value }))} required />
          <div className="space-y-1">
            <label className="block text-sm font-medium text-fg">Vai trò</label>
            <select
              className="w-full rounded-lg border border-border bg-surface px-3 py-2 text-sm text-fg"
              value={createForm.role}
              onChange={(e) => setCreateForm((p) => ({ ...p, role: e.target.value as User['role'] }))}
            >
              {USER_ROLES.map(role => <option key={role} value={role}>{ROLE_LABELS[role]}</option>)}
            </select>
          </div>
          <div className="flex justify-end gap-2">
            <Button type="button" variant="secondary" onClick={() => setShowCreate(false)}>Huỷ</Button>
            <Button type="submit" loading={createUserMutation.isPending}>Tạo</Button>
          </div>
        </form>
      </Dialog>

      <Dialog open={!!editingUser} onClose={() => setEditingUser(null)} title="Cập nhật người dùng">
        <form
          onSubmit={(e) => {
            e.preventDefault()
            updateUserMutation.mutate()
          }}
          className="space-y-4"
        >
          <Input label="Họ tên" value={editForm.fullName} onChange={(e) => setEditForm((p) => ({ ...p, fullName: e.target.value }))} required />
          <Input label="Điện thoại" value={editForm.phone} onChange={(e) => setEditForm((p) => ({ ...p, phone: e.target.value }))} />
          <div className="space-y-1">
            <label className="block text-sm font-medium text-fg">Vai trò</label>
            <select
              className="w-full rounded-lg border border-border bg-surface px-3 py-2 text-sm text-fg"
              value={editForm.role}
              onChange={(e) => setEditForm((p) => ({ ...p, role: e.target.value as User['role'] }))}
            >
              {USER_ROLES.map(role => <option key={role} value={role}>{ROLE_LABELS[role]}</option>)}
            </select>
          </div>
          <div className="flex justify-end gap-2">
            <Button type="button" variant="secondary" onClick={() => setEditingUser(null)}>Huỷ</Button>
            <Button type="submit" loading={updateUserMutation.isPending}>Lưu thay đổi</Button>
          </div>
        </form>
      </Dialog>
    </Layout>
  )
}
