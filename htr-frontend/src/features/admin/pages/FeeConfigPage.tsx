import { useEffect, useState } from 'react'
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import Layout from '@/components/Layout'
import { Card } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { CardsSkeleton } from '@/components/ui/feedback'
import api from '@/lib/api'
import { formatCurrencyInput, parseCurrencyInput } from '@/lib/utils'

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
  })

  const [feeForm, setFeeForm] = useState<Partial<FeeConfig>>({})
  const [moneyForm, setMoneyForm] = useState<Partial<Record<keyof FeeConfig, string>>>({})

  useEffect(() => {
    if (!feeConfig) {
      setMoneyForm({})
      return
    }

    setMoneyForm({
      rentDefault: formatCurrencyInput(feeConfig.rentDefault),
      elecPrice: formatCurrencyInput(feeConfig.elecPrice),
      waterPrice: formatCurrencyInput(feeConfig.waterPrice),
      serviceFee: formatCurrencyInput(feeConfig.serviceFee),
      motorbikePrice: formatCurrencyInput(feeConfig.motorbikePrice),
      carPrice: formatCurrencyInput(feeConfig.carPrice),
      bicyclePrice: formatCurrencyInput(feeConfig.bicyclePrice),
    })
  }, [feeConfig])

  const feeMutation = useMutation({
    mutationFn: (data: Partial<FeeConfig>) =>
      api.put(`/properties/${selectedProp}/fee-config`, data),
    onSuccess: () => qc.invalidateQueries({ queryKey: ['fee-config', selectedProp] }),
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
          <label className="block text-sm font-medium text-fg mb-1">Toà nhà</label>
          <select
            className="w-full border border-border/80 rounded-xl px-3 py-2 text-sm bg-surface text-fg focus:outline-none focus:ring-2 focus:ring-accent"
            value={selectedProp}
            onChange={e => { setSelectedProp(e.target.value); setFeeForm({}); setMoneyForm({}) }}
          >
            <option value="">Chọn toà nhà...</option>
            {properties?.map(p => <option key={p.id} value={p.id}>{p.name}</option>)}
          </select>
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
                      value={moneyForm.rentDefault ?? ''}
                      onChange={e => setMoneyField('rentDefault', e.target.value)}
                    />
                  </div>
                  <div>
                    <label className="block text-sm font-medium text-fg mb-1">Giá điện (₫/kWh)</label>
                    <Input
                      type="text"
                      inputMode="numeric"
                      value={moneyForm.elecPrice ?? ''}
                      onChange={e => setMoneyField('elecPrice', e.target.value)}
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
                      type="text"
                      inputMode="numeric"
                      value={moneyForm.waterPrice ?? ''}
                      onChange={e => setMoneyField('waterPrice', e.target.value)}
                    />
                  </div>
                  <div>
                    <label className="block text-sm font-medium text-fg mb-1">Phí dịch vụ (₫/tháng)</label>
                    <Input
                      type="text"
                      inputMode="numeric"
                      value={moneyForm.serviceFee ?? ''}
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
                      value={moneyForm.motorbikePrice ?? ''}
                      onChange={e => setMoneyField('motorbikePrice', e.target.value)}
                    />
                  </div>
                  <div>
                    <label className="block text-sm font-medium text-fg mb-1">Ô tô (₫/tháng)</label>
                    <Input
                      type="text"
                      inputMode="numeric"
                      value={moneyForm.carPrice ?? ''}
                      onChange={e => setMoneyField('carPrice', e.target.value)}
                    />
                  </div>
                  <div>
                    <label className="block text-sm font-medium text-fg mb-1">Xe đạp (₫/tháng)</label>
                    <Input
                      type="text"
                      inputMode="numeric"
                      value={moneyForm.bicyclePrice ?? ''}
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
