import { useState } from 'react'
import { useQuery, useQueryClient } from '@tanstack/react-query'
import { useGuardedMutation } from '@/hooks/useGuardedMutation'
import Layout from '@/components/Layout'
import { Card } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Select } from '@/components/ui/select'
import { CardsSkeleton } from '@/components/ui/feedback'
import api from '@/lib/api'
import { formatCurrencyInput, parseCurrencyInput } from '@/lib/utils'
import { getErrorMessage } from '@/lib/apiError'
import { showToast } from '@/lib/toast'

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
    staleTime: 1000 * 60 * 10,
  })

  const [feeForm, setFeeForm] = useState<Partial<FeeConfig>>({})
  const [moneyForm, setMoneyForm] = useState<Partial<Record<keyof FeeConfig, string>>>({})

  const getMoneyValue = (field: keyof FeeConfig) => {
    const dirtyValue = moneyForm[field]
    if (dirtyValue !== undefined) return dirtyValue

    const value = feeConfig?.[field]
    return typeof value === 'number' ? formatCurrencyInput(value) : ''
  }

  const feeMutation = useGuardedMutation({
    mutationFn: (data: Partial<FeeConfig>) =>
      api.put(`/properties/${selectedProp}/fee-config`, data),
    onSuccess: async () => {
      await qc.invalidateQueries({ queryKey: ['fee-config', selectedProp] })
      setFeeForm({})
      setMoneyForm({})
    },
    onError: (e: unknown) => {
      showToast({ message: getErrorMessage(e, 'Không thể lưu cấu hình phí'), type: 'error' })
    },
  })

  const handleFeeSubmit = (e: React.FormEvent) => {
    e.preventDefault()
    feeMutation.mutate({ ...feeConfig, ...feeForm, propertyId: selectedProp })
  }

  const setMoneyField = (field: keyof FeeConfig, value: string) => {
    const formatted = formatCurrencyInput(value)
    setMoneyForm(f => ({ ...f, [field]: formatted }))
    setFeeForm(f => ({ ...f, [field]: parseCurrencyInput(formatted) }))
  }

  if (propsLoading) return <Layout><CardsSkeleton count={2} /></Layout>

  return (
    <Layout>
      <div className="space-y-6">
        <h1 className="text-2xl font-bold text-fg">Cấu hình phí & xe</h1>

        <div className="max-w-xs">
          <Select
            label="Toà nhà"
            value={selectedProp}
            onChange={e => { setSelectedProp(e.target.value); setFeeForm({}); setMoneyForm({}) }}
          >
            <option value="">Chọn toà nhà...</option>
            {properties?.map(p => <option key={p.id} value={p.id}>{p.name}</option>)}
          </Select>
        </div>

        {selectedProp && (
          <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
            <Card key={`fee-${selectedProp}`} className="p-6">
              <h2 className="text-lg font-semibold text-fg mb-4">Cấu hình phí ({properties?.find(p => p.id === selectedProp)?.name})</h2>
              {feeLoading ? <CardsSkeleton count={1} /> : (
                <form onSubmit={handleFeeSubmit} className="space-y-4">
                  <div>
                    <label className="block text-sm font-medium text-fg mb-1">Tiền phòng mặc định (₫)</label>
                    <Input
                      type="text"
                      inputMode="numeric"
                      value={getMoneyValue('rentDefault')}
                      onChange={e => setMoneyField('rentDefault', e.target.value)}
                    />
                  </div>
                  <div>
                    <label className="block text-sm font-medium text-fg mb-1">Giá điện (₫/kWh)</label>
                    <Input
                      type="text"
                      inputMode="numeric"
                      value={getMoneyValue('elecPrice')}
                      onChange={e => setMoneyField('elecPrice', e.target.value)}
                    />
                  </div>
                  <Select
                    label="Chế độ nước"
                    defaultValue={feeConfig?.waterMode}
                    onChange={e => setFeeForm(f => ({ ...f, waterMode: e.target.value as 'CUBIC' | 'PERSON' }))}
                  >
                    <option value="CUBIC">Theo khối (m³)</option>
                    <option value="PERSON">Theo đầu người</option>
                  </Select>
                  <div>
                    <label className="block text-sm font-medium text-fg mb-1">Giá nước (₫)</label>
                    <Input
                      type="text"
                      inputMode="numeric"
                      value={getMoneyValue('waterPrice')}
                      onChange={e => setMoneyField('waterPrice', e.target.value)}
                    />
                  </div>
                  <div>
                    <label className="block text-sm font-medium text-fg mb-1">Phí dịch vụ (₫/tháng)</label>
                    <Input
                      type="text"
                      inputMode="numeric"
                      value={getMoneyValue('serviceFee')}
                      onChange={e => setMoneyField('serviceFee', e.target.value)}
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

            <Card key={`vehicle-${selectedProp}`} className="p-6">
              <h2 className="text-lg font-semibold text-fg mb-4">Phí giữ xe</h2>
              {feeLoading ? <CardsSkeleton count={1} /> : (
                <form onSubmit={handleFeeSubmit} className="space-y-4">
                  <div>
                    <label className="block text-sm font-medium text-fg mb-1">Xe máy (₫/tháng)</label>
                    <Input
                      type="text"
                      inputMode="numeric"
                      value={getMoneyValue('motorbikePrice')}
                      onChange={e => setMoneyField('motorbikePrice', e.target.value)}
                    />
                  </div>
                  <div>
                    <label className="block text-sm font-medium text-fg mb-1">Ô tô (₫/tháng)</label>
                    <Input
                      type="text"
                      inputMode="numeric"
                      value={getMoneyValue('carPrice')}
                      onChange={e => setMoneyField('carPrice', e.target.value)}
                    />
                  </div>
                  <div>
                    <label className="block text-sm font-medium text-fg mb-1">Xe đạp (₫/tháng)</label>
                    <Input
                      type="text"
                      inputMode="numeric"
                      value={getMoneyValue('bicyclePrice')}
                      onChange={e => setMoneyField('bicyclePrice', e.target.value)}
                    />
                  </div>
                  <Button type="submit" disabled={feeMutation.isPending}>
                    {feeMutation.isPending ? 'Đang lưu...' : 'Lưu phí giữ xe'}
                  </Button>
                  {feeMutation.isSuccess && <p className="text-sm text-success">Đã lưu thành công</p>}
                  {feeMutation.isError && <p className="text-sm text-error">Lưu thất bại</p>}
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
