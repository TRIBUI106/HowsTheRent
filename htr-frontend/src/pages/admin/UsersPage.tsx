import { useState } from 'react'
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import Layout from '@/components/Layout'
import { Card } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { Badge } from '@/components/ui/badge'
import { Spinner } from '@/components/ui/feedback'
import api from '@/lib/api'

interface User {
  id: string
  fullName: string
  email: string
  phone?: string
  role: 'ADMIN' | 'TENANT' | 'TECHNICIAN'
  active: boolean
  avatarUrl?: string
}

export default function UsersPage() {
  const qc = useQueryClient()
  const [roleFilter, setRoleFilter] = useState<string>('ALL')

  const { data: users, isLoading, error } = useQuery<User[]>({
    queryKey: ['admin-users'],
    queryFn: () => api.get('/users').then(r => r.data),
  })

  const toggleActiveMutation = useMutation({
    mutationFn: ({ id, active }: { id: string; active: boolean }) =>
      api.patch(`/users/${id}`, { active }),
    onSuccess: () => qc.invalidateQueries({ queryKey: ['admin-users'] }),
  })

  const changeRoleMutation = useMutation({
    mutationFn: ({ id, role }: { id: string; role: string }) =>
      api.patch(`/users/${id}`, { role }),
    onSuccess: () => qc.invalidateQueries({ queryKey: ['admin-users'] }),
  })

  if (isLoading) return <Layout><Spinner /></Layout>
  if (error) return <Layout><div className="p-6 text-red-600">Failed to load users</div></Layout>

  const filtered = roleFilter === 'ALL' ? users : users?.filter(u => u.role === roleFilter)

  return (
    <Layout>
      <div className="p-6 space-y-4">
        <div className="flex items-center justify-between">
          <h1 className="text-2xl font-bold text-gray-900">Users</h1>
          <div className="flex gap-2">
            {['ALL', 'ADMIN', 'TENANT', 'TECHNICIAN'].map(r => (
              <button
                key={r}
                onClick={() => setRoleFilter(r)}
                className={`px-3 py-1.5 rounded-lg text-sm font-medium transition-colors ${
                  roleFilter === r
                    ? 'bg-indigo-600 text-white'
                    : 'bg-gray-100 text-gray-600 hover:bg-gray-200'
                }`}
              >
                {r}
              </button>
            ))}
          </div>
        </div>

        <Card className="overflow-hidden">
          <div className="overflow-x-auto">
            <table className="min-w-full divide-y divide-gray-200">
              <thead className="bg-gray-50">
                <tr>
                  {['Name', 'Email', 'Phone', 'Role', 'Status', 'Actions'].map(h => (
                    <th key={h} className="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">{h}</th>
                  ))}
                </tr>
              </thead>
              <tbody className="bg-white divide-y divide-gray-200">
                {filtered?.map(u => (
                  <tr key={u.id} className="hover:bg-gray-50">
                    <td className="px-4 py-3 text-sm font-medium text-gray-900">{u.fullName}</td>
                    <td className="px-4 py-3 text-sm text-gray-600">{u.email}</td>
                    <td className="px-4 py-3 text-sm text-gray-600">{u.phone ?? '—'}</td>
                    <td className="px-4 py-3">
                      <select
                        className="text-xs border border-gray-200 rounded px-2 py-1"
                        value={u.role}
                        onChange={e => changeRoleMutation.mutate({ id: u.id, role: e.target.value })}
                      >
                        <option value="ADMIN">ADMIN</option>
                        <option value="TENANT">TENANT</option>
                        <option value="TECHNICIAN">TECHNICIAN</option>
                      </select>
                    </td>
                    <td className="px-4 py-3">
                      <Badge status={u.active ? 'ACTIVE' : 'INACTIVE'} />
                    </td>
                    <td className="px-4 py-3">
                      <Button
                        size="sm"
                        variant={u.active ? 'outline' : 'primary'}
                        onClick={() => toggleActiveMutation.mutate({ id: u.id, active: !u.active })}
                        disabled={toggleActiveMutation.isPending}
                      >
                        {u.active ? 'Deactivate' : 'Activate'}
                      </Button>
                    </td>
                  </tr>
                ))}
                {filtered?.length === 0 && (
                  <tr><td colSpan={6} className="px-4 py-8 text-center text-gray-400">No users found</td></tr>
                )}
              </tbody>
            </table>
          </div>
        </Card>

        <p className="text-sm text-gray-400">
          {filtered?.length ?? 0} user{filtered?.length !== 1 ? 's' : ''}
          {roleFilter !== 'ALL' ? ` with role ${roleFilter}` : ' total'}
        </p>
      </div>
    </Layout>
  )
}
