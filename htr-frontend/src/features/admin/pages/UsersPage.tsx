import { useMemo, useState } from 'react'
import { useQuery, useQueryClient } from '@tanstack/react-query'
import { useGuardedMutation } from '@/hooks/useGuardedMutation'
import Layout from '@/components/Layout'
import { Card } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { Badge } from '@/components/ui/badge'
import { Dialog } from '@/components/ui/dialog'
import { Input } from '@/components/ui/input'
import { Select } from '@/components/ui/select'
import { TableSkeleton } from '@/components/ui/feedback'
import { Table, TableRow, TableCell } from '@/components/ui/table'
import { userApi } from '@/api'
import { getErrorMessage } from '@/lib/apiError'
import { showToast } from '@/lib/toast'
import { Search } from 'lucide-react'
import type { User } from '@/types'

const FILTER_ROLES = ['ALL', 'ADMIN', 'PLATFORM_ADMIN', 'LANDLORD_ADMIN', 'TENANT', 'TECHNICIAN'] as const
const USER_ROLES = ['ADMIN', 'PLATFORM_ADMIN', 'LANDLORD_ADMIN', 'TENANT', 'TECHNICIAN'] as const
// PLATFORM_ADMIN/LANDLORD_ADMIN dropped from the CREATE form only, per explicit request — creating
// a brand new user with either role keeps 409ing in production ("Không thể thực hiện vì dữ liệu
// đang được sử dụng ở nơi khác"), still unresolved. USER_ROLES (both roles included) stays as-is
// for the edit form, which wasn't reported as failing.
const CREATABLE_USER_ROLES = USER_ROLES.filter(role => role !== 'PLATFORM_ADMIN' && role !== 'LANDLORD_ADMIN')

// Keyed by (typeof FILTER_ROLES)[number] | 'GUEST' rather than FILTER_ROLES
// alone: GUEST accounts are self-registered via the public blog (Task 6),
// not created/filtered from this admin page, so GUEST intentionally stays
// out of FILTER_ROLES/USER_ROLES — but u.role (User['role']) can still be
// 'GUEST' at runtime, so this label map must stay exhaustive against it.
const ROLE_LABELS: Record<(typeof FILTER_ROLES)[number] | 'GUEST', string> = {
  ALL: 'Tất cả',
  ADMIN: 'Quản trị vận hành',
  PLATFORM_ADMIN: 'Quản trị nền tảng',
  LANDLORD_ADMIN: 'Quản trị chủ nhà',
  TENANT: 'Khách thuê',
  TECHNICIAN: 'Kỹ thuật viên',
  GUEST: 'Khách',
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
  const [search, setSearch] = useState('')
  const [showCreate, setShowCreate] = useState(false)
  const [editingUser, setEditingUser] = useState<User | null>(null)
  const [createForm, setCreateForm] = useState(emptyCreateForm)
  const [editForm, setEditForm] = useState(emptyEditForm)

  const { data: users = [], isLoading } = useQuery<User[]>({
    queryKey: ['admin-users'],
    queryFn: () => userApi.listAll(),
  })

  const refreshUsers = () => qc.invalidateQueries({ queryKey: ['admin-users'] })

  const createUserMutation = useGuardedMutation({
    mutationFn: () => userApi.create(createForm),
    onSuccess: () => {
      refreshUsers()
      setShowCreate(false)
      setCreateForm(emptyCreateForm)
    },
    onError: (err: unknown) => {
      showToast({ message: getErrorMessage(err, 'Không thể tạo người dùng'), type: 'error' })
    },
  })

  const updateUserMutation = useGuardedMutation({
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
    onError: (err: unknown) => {
      showToast({ message: getErrorMessage(err, 'Không thể cập nhật người dùng'), type: 'error' })
    },
  })

  const toggleActiveMutation = useGuardedMutation({
    mutationFn: (id: string) => userApi.toggleActive(id),
    onSuccess: () => refreshUsers(),
    onError: (err: unknown) => {
      showToast({ message: getErrorMessage(err, 'Không thể đổi trạng thái kích hoạt'), type: 'error' })
    },
  })

  const filtered = useMemo(() => {
    const byRole = roleFilter === 'ALL' ? users : users.filter(u => u.role === roleFilter)
    if (!search.trim()) return byRole
    const s = search.trim().toLowerCase()
    return byRole.filter(u =>
      u.fullName.toLowerCase().includes(s) ||
      u.email.toLowerCase().includes(s) ||
      (u.phone ?? '').toLowerCase().includes(s)
    )
  }, [users, roleFilter, search])

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
          <div className="flex flex-wrap items-center gap-2">
            <div className="relative">
              <Search size={15} className="absolute left-3 top-1/2 -translate-y-1/2 text-fg-subtle" />
              <input
                type="text"
                placeholder="Tìm tên, email, SĐT..."
                value={search}
                onChange={(e) => setSearch(e.target.value)}
                className="w-56 rounded-xl border border-border bg-surface pl-9 pr-3 py-1.5 text-xs text-fg focus:outline-none focus:ring-2 focus:ring-accent"
              />
            </div>
            <div className="flex gap-1.5">
              {FILTER_ROLES.map(r => (
                <Button
                  key={r}
                  type="button"
                  size="xs"
                  variant={roleFilter === r ? 'primary' : 'ghost'}
                  className={roleFilter === r ? undefined : 'bg-sidebar'}
                  onClick={() => setRoleFilter(r)}
                >
                  {ROLE_LABELS[r]}
                </Button>
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
                    {users.length === 0 ? 'Không có người dùng' : 'Không tìm thấy người dùng phù hợp'}
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
          <Select
            label="Vai trò"
            value={createForm.role}
            onChange={(e) => setCreateForm((p) => ({ ...p, role: e.target.value as User['role'] }))}
          >
            {CREATABLE_USER_ROLES.map(role => <option key={role} value={role}>{ROLE_LABELS[role]}</option>)}
          </Select>
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
          <Select
            label="Vai trò"
            value={editForm.role}
            onChange={(e) => setEditForm((p) => ({ ...p, role: e.target.value as User['role'] }))}
          >
            {USER_ROLES.map(role => <option key={role} value={role}>{ROLE_LABELS[role]}</option>)}
          </Select>
          <div className="flex justify-end gap-2">
            <Button type="button" variant="secondary" onClick={() => setEditingUser(null)}>Huỷ</Button>
            <Button type="submit" loading={updateUserMutation.isPending}>Lưu thay đổi</Button>
          </div>
        </form>
      </Dialog>
    </Layout>
  )
}
