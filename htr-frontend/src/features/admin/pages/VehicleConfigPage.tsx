import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { useState } from 'react'
import { propertyApi } from '@/api/propertyApi'
import Layout from '@/components/Layout'
import { Card, CardContent, CardHeader } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Select } from '@/components/ui/select'
import { CardsSkeleton } from '@/components/ui/feedback'
import { formatCurrency } from '@/lib/utils'
import type { Property, VehicleConfig } from '@/types'

export default function VehicleConfigPage() {
  const qc = useQueryClient()
  const [selectedPropertyId, setSelectedPropertyId] = useState<string>('')
  const [form, setForm] = useState({ motorbikePrice: 0, carPrice: 0, bicyclePrice: 0 })
  const [editing, setEditing] = useState(false)

  const { data: properties = [] } = useQuery<Property[]>({
    queryKey: ['properties'],
    queryFn: propertyApi.listMine,
  })

  const { data: vehicleConfig, isLoading: loadingConfig } = useQuery<VehicleConfig>({
    queryKey: ['vehicle-config', selectedPropertyId],
    queryFn: () => propertyApi.getVehicleConfig(selectedPropertyId),
    enabled: !!selectedPropertyId,
  })

  const formDefaults = {
    motorbikePrice: vehicleConfig?.motorbikePrice ?? 0,
    carPrice: vehicleConfig?.carPrice ?? 0,
    bicyclePrice: vehicleConfig?.bicyclePrice ?? 0,
  }

  const save = useMutation({
    mutationFn: () => propertyApi.updateVehicleConfig(selectedPropertyId, form),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ['vehicle-config', selectedPropertyId] })
      setEditing(false)
    },
  })

  function handleEdit() {
    setForm(formDefaults)
    setEditing(true)
  }

  function handleCancel() {
    setEditing(false)
  }

  return (
    <Layout title="Cấu hình xe">
      <div className="max-w-2xl">
        <Card className="mb-6">
          <CardHeader>Chọn tài sản</CardHeader>
          <CardContent>
            <Select
              label="Tài sản"
              value={selectedPropertyId}
              onChange={e => {
                setSelectedPropertyId(e.target.value)
                setEditing(false)
              }}
            >
              <option value="">-- Chọn tài sản --</option>
              {properties.map(p => (
                <option key={p.id} value={p.id}>{p.name}</option>
              ))}
            </Select>
          </CardContent>
        </Card>

        {selectedPropertyId && (
          <Card>
            <CardHeader className="flex flex-row items-center justify-between">
              <span>Giá xe / tháng</span>
              <Button size="sm" variant="outline" onClick={editing ? handleCancel : handleEdit}>
                {editing ? 'Hủy' : 'Chỉnh sửa'}
              </Button>
            </CardHeader>
            <CardContent>
              {loadingConfig ? (
                <CardsSkeleton count={1} />
              ) : editing ? (
                <form
                  onSubmit={e => { e.preventDefault(); save.mutate() }}
                  className="space-y-4"
                >
                  <Input
                    label="Xe máy (VNĐ/xe/tháng)"
                    type="number"
                    min={0}
                    value={form.motorbikePrice}
                    onChange={e => setForm({ ...form, motorbikePrice: Number(e.target.value) })}
                  />
                  <Input
                    label="Ô tô (VNĐ/xe/tháng)"
                    type="number"
                    min={0}
                    value={form.carPrice}
                    onChange={e => setForm({ ...form, carPrice: Number(e.target.value) })}
                  />
                  <Input
                    label="Xe đạp (VNĐ/xe/tháng)"
                    type="number"
                    min={0}
                    value={form.bicyclePrice}
                    onChange={e => setForm({ ...form, bicyclePrice: Number(e.target.value) })}
                  />
                  <Button type="submit" disabled={save.isPending} loading={save.isPending}>
                    {save.isPending ? 'Đang lưu...' : 'Lưu thay đổi'}
                  </Button>
                </form>
              ) : (
                <div className="space-y-3">
                  {[
                    { label: 'Xe máy', value: vehicleConfig?.motorbikePrice },
                    { label: 'Ô tô', value: vehicleConfig?.carPrice },
                    { label: 'Xe đạp', value: vehicleConfig?.bicyclePrice },
                  ].map(item => (
                    <div key={item.label} className="flex justify-between items-center py-2 border-b border-border/60 last:border-0">
                      <span className="text-sm text-fg-muted">{item.label}</span>
                      <span className="font-medium text-fg">{formatCurrency(item.value ?? 0)} / xe / tháng</span>
                    </div>
                  ))}
                </div>
              )}
            </CardContent>
          </Card>
        )}
      </div>
    </Layout>
  )
}
