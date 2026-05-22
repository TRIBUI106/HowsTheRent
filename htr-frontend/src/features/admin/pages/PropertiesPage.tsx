import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { useState } from 'react'
import api from '@/lib/api'
import Layout from '@/components/Layout'
import { Card, CardContent, CardHeader } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Badge } from '@/components/ui/badge'
import { formatDate } from '@/lib/utils'
import type { Property } from '@/types'

export default function PropertiesPage() {
  const qc = useQueryClient()
  const [showForm, setShowForm] = useState(false)
  const [form, setForm] = useState({ name: '', address: '', type: 'BOARDING_HOUSE', description: '' })

  const { data: properties, isLoading } = useQuery<Property[]>({
    queryKey: ['properties'],
    queryFn: () => api.get('/properties/mine').then(r => r.data),
  })

  const create = useMutation({
    mutationFn: (d: typeof form) => api.post('/properties', d),
    onSuccess: () => { qc.invalidateQueries({ queryKey: ['properties'] }); setShowForm(false); setForm({ name: '', address: '', type: 'BOARDING_HOUSE', description: '' }) },
  })

  return (
    <Layout title="Tài sản">
      <div className="flex justify-between items-center mb-6">
        <p className="text-sm text-gray-500">Quản lý tài sản</p>
        <Button onClick={() => setShowForm(!showForm)}>{showForm ? 'Đóng' : '+ Thêm tài sản'}</Button>
      </div>

      {showForm && (
        <Card className="mb-6">
          <CardHeader>Tạo tài sản mới</CardHeader>
          <CardContent>
            <form onSubmit={(e) => { e.preventDefault(); create.mutate(form) }} className="grid grid-cols-1 md:grid-cols-2 gap-4">
              <Input label="Tên tài sản" value={form.name} onChange={e => setForm({ ...form, name: e.target.value })} required />
              <Input label="Địa chỉ" value={form.address} onChange={e => setForm({ ...form, address: e.target.value })} required />
              <div className="space-y-1">
                <label className="block text-sm font-medium text-gray-700">Loại</label>
                <select className="w-full rounded-lg border border-gray-300 px-3 py-2 text-sm" value={form.type} onChange={e => setForm({ ...form, type: e.target.value })}>
                  <option value="BOARDING_HOUSE">Nhà trọ</option>
                  <option value="CONDO">Chung cư</option>
                </select>
              </div>
              <Input label="Mô tả" value={form.description} onChange={e => setForm({ ...form, description: e.target.value })} />
              <div className="md:col-span-2">
                <Button type="submit" disabled={create.isPending}>{create.isPending ? 'Đang tạo...' : 'Tạo tài sản'}</Button>
              </div>
            </form>
          </CardContent>
        </Card>
      )}

      {isLoading ? (
        <div className="flex h-32 items-center justify-center">
          <div className="animate-spin h-6 w-6 border-2 border-blue-600 border-t-transparent rounded-full" />
        </div>
      ) : properties?.length === 0 ? (
        <div className="text-center py-12 text-gray-400">Chưa có tài sản nào</div>
      ) : (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          {properties?.map(p => (
            <Card key={p.id}>
              <CardContent className="p-6">
                <div className="flex justify-between items-start">
                  <div>
                    <h3 className="font-semibold text-gray-900">{p.name}</h3>
                    <p className="text-sm text-gray-500 mt-1">{p.address}</p>
                  </div>
                  <Badge status={p.type} />
                </div>
                {p.description && <p className="text-sm text-gray-400 mt-3">{p.description}</p>}
                <p className="text-xs text-gray-400 mt-4">Tạo: {formatDate(p.createdAt)}</p>
              </CardContent>
            </Card>
          ))}
        </div>
      )}
    </Layout>
  )
}