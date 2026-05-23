import { useState } from 'react'
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import Layout from '@/components/Layout'
import { Card } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { CardsSkeleton } from '@/components/ui/feedback'
import api from '@/lib/api'

interface Property {
  id: string
  name: string
}

interface FeeConfig {
  id?: string
  propertyId: string
  rentDefault: number
  elecPrice: number
  waterMode: 'CUBIC' | 'PERSON'
  waterPrice: number
  serviceFee: number
}

interface VehicleConfig {
  id?: string
  propertyId: string
  motorbikePrice: number
  carPrice: number
  bicyclePrice: number
}

export default function FeeConfigPage() {
  const qc = useQueryClient()
  const [selectedProp, setSelectedProp] = useState<string>('')

  const { data: properties, isLoading: propsLoading } = useQuery<Property[]>({
    queryKey: ['properties'],
    queryFn: () => api.get('/properties').then(r => r.data),
  })

  const { data: feeConfig, isLoading: feeLoading } = useQuery<FeeConfig>({
    queryKey: ['fee-config', selectedProp],
    queryFn: () => api.get(`/properties/${selectedProp}/fee-config`).then(r => r.data),
    enabled: !!selectedProp,
  })

  const { data: vehicleConfig, isLoading: vehicleLoading } = useQuery<VehicleConfig>({
    queryKey: ['vehicle-config', selectedProp],
    queryFn: () => api.get(`/properties/${selectedProp}/vehicle-config`).then(r => r.data),
    enabled: !!selectedProp,
  })

  const [feeForm, setFeeForm] = useState<Partial<FeeConfig>>({})
  const [vehicleForm, setVehicleForm] = useState<Partial<VehicleConfig>>({})

  const feeMutation = useMutation({
    mutationFn: (data: Partial<FeeConfig>) =>
      api.put(`/properties/${selectedProp}/fee-config`, data),
    onSuccess: () => qc.invalidateQueries({ queryKey: ['fee-config', selectedProp] }),
  })

  const vehicleMutation = useMutation({
    mutationFn: (data: Partial<VehicleConfig>) =>
      api.put(`/properties/${selectedProp}/vehicle-config`, data),
    onSuccess: () => qc.invalidateQueries({ queryKey: ['vehicle-config', selectedProp] }),
  })

  const handleFeeSubmit = (e: React.FormEvent) => {
    e.preventDefault()
    feeMutation.mutate({ ...feeConfig, ...feeForm, propertyId: selectedProp })
  }

  const handleVehicleSubmit = (e: React.FormEvent) => {
    e.preventDefault()
    vehicleMutation.mutate({ ...vehicleConfig, ...vehicleForm, propertyId: selectedProp })
  }

  if (propsLoading) return <Layout><CardsSkeleton count={2} /></Layout>

  return (
    <Layout>
      <div className="space-y-6">
        <h1 className="text-2xl font-bold text-fg">Cấu hình phí & xe</h1>

        <div className="max-w-xs">
          <label className="block text-sm font-medium text-fg mb-1">Toà nhà</label>
          <select
            className="w-full border border-border/80 rounded-xl px-3 py-2 text-sm bg-surface text-fg focus:outline-none focus:ring-2 focus:ring-accent"
            value={selectedProp}
            onChange={e => { setSelectedProp(e.target.value); setFeeForm({}); setVehicleForm({}) }}
          >
            <option value="">Chọn toà nhà...</option>
            {properties?.map(p => <option key={p.id} value={p.id}>{p.name}</option>)}
          </select>
        </div>

        {selectedProp && (
          <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
            <Card className="p-6">
              <h2 className="text-lg font-semibold text-fg mb-4">Cấu hình phí</h2>
              {feeLoading ? <CardsSkeleton count={1} /> : (
                <form onSubmit={handleFeeSubmit} className="space-y-4">
                  <div>
                    <label className="block text-sm font-medium text-fg mb-1">Tiền phòng mặc định (₫)</label>
                    <Input
                      type="number"
                      defaultValue={feeConfig?.rentDefault}
                      onChange={e => setFeeForm(f => ({ ...f, rentDefault: +e.target.value }))}
                    />
                  </div>
                  <div>
                    <label className="block text-sm font-medium text-fg mb-1">Giá điện (₫/kWh)</label>
                    <Input
                      type="number"
                      defaultValue={feeConfig?.elecPrice}
                      onChange={e => setFeeForm(f => ({ ...f, elecPrice: +e.target.value }))}
                    />
                  </div>
                  <div>
                    <label className="block text-sm font-medium text-fg mb-1">Chế độ nước</label>
                    <select
                      className="w-full border border-border/80 rounded-xl px-3 py-2 text-sm bg-surface text-fg focus:outline-none focus:ring-2 focus:ring-accent"
                      defaultValue={feeConfig?.waterMode}
                      onChange={e => setFeeForm(f => ({ ...f, waterMode: e.target.value as 'CUBIC' | 'PERSON' }))}
                    >
                      <option value="CUBIC">Theo khối (m³)</option>
                      <option value="PERSON">Theo đầu người</option>
                    </select>
                  </div>
                  <div>
                    <label className="block text-sm font-medium text-fg mb-1">Giá nước (₫)</label>
                    <Input
                      type="number"
                      defaultValue={feeConfig?.waterPrice}
                      onChange={e => setFeeForm(f => ({ ...f, waterPrice: +e.target.value }))}
                    />
                  </div>
                  <div>
                    <label className="block text-sm font-medium text-fg mb-1">Phí dịch vụ (₫/tháng)</label>
                    <Input
                      type="number"
                      defaultValue={feeConfig?.serviceFee}
                      onChange={e => setFeeForm(f => ({ ...f, serviceFee: +e.target.value }))}
                    />
                  </div>
                  <Button type="submit" disabled={feeMutation.isPending}>
                    {feeMutation.isPending ? 'Đang lưu...' : 'Lưu cấu hình phí'}
                  </Button>
                  {feeMutation.isSuccess && <p className="text-sm text-success">Đã lưu thành công</p>}
                  {feeMutation.isError && <p className="text-sm text-error">Lưu thất bại</p>}
                </form>
              )}
            </Card>

            <Card className="p-6">
              <h2 className="text-lg font-semibold text-fg mb-4">Phí giữ xe</h2>
              {vehicleLoading ? <CardsSkeleton count={1} /> : (
                <form onSubmit={handleVehicleSubmit} className="space-y-4">
                  <div>
                    <label className="block text-sm font-medium text-fg mb-1">Xe máy (₫/tháng)</label>
                    <Input
                      type="number"
                      defaultValue={vehicleConfig?.motorbikePrice}
                      onChange={e => setVehicleForm(f => ({ ...f, motorbikePrice: +e.target.value }))}
                    />
                  </div>
                  <div>
                    <label className="block text-sm font-medium text-fg mb-1">Ô tô (₫/tháng)</label>
                    <Input
                      type="number"
                      defaultValue={vehicleConfig?.carPrice}
                      onChange={e => setVehicleForm(f => ({ ...f, carPrice: +e.target.value }))}
                    />
                  </div>
                  <div>
                    <label className="block text-sm font-medium text-fg mb-1">Xe đạp (₫/tháng)</label>
                    <Input
                      type="number"
                      defaultValue={vehicleConfig?.bicyclePrice}
                      onChange={e => setVehicleForm(f => ({ ...f, bicyclePrice: +e.target.value }))}
                    />
                  </div>
                  <Button type="submit" disabled={vehicleMutation.isPending}>
                    {vehicleMutation.isPending ? 'Đang lưu...' : 'Lưu phí giữ xe'}
                  </Button>
                  {vehicleMutation.isSuccess && <p className="text-sm text-success">Đã lưu thành công</p>}
                  {vehicleMutation.isError && <p className="text-sm text-error">Lưu thất bại</p>}
                </form>
              )}
            </Card>
          </div>
        )}

        {!selectedProp && (
          <div className="text-center py-16 text-fg-subtle">Chọn toà nhà để cấu hình phí</div>
        )}
      </div>
    </Layout>
  )
}
