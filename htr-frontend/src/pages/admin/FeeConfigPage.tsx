import { useState } from 'react'
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import Layout from '@/components/Layout'
import { Card } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Spinner } from '@/components/ui/feedback'
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

  if (propsLoading) return <Layout><Spinner /></Layout>

  return (
    <Layout>
      <div className="p-6 space-y-6">
        <h1 className="text-2xl font-bold text-gray-900">Fee & Vehicle Config</h1>

        <div className="max-w-xs">
          <label className="block text-sm font-medium text-gray-700 mb-1">Property</label>
          <select
            className="w-full border border-gray-300 rounded-lg px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-indigo-500"
            value={selectedProp}
            onChange={e => { setSelectedProp(e.target.value); setFeeForm({}); setVehicleForm({}) }}
          >
            <option value="">Select a property…</option>
            {properties?.map(p => <option key={p.id} value={p.id}>{p.name}</option>)}
          </select>
        </div>

        {selectedProp && (
          <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
            {/* Fee Config */}
            <Card className="p-6">
              <h2 className="text-lg font-semibold text-gray-800 mb-4">Fee Configuration</h2>
              {feeLoading ? <Spinner /> : (
                <form onSubmit={handleFeeSubmit} className="space-y-4">
                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-1">Default Rent (₫)</label>
                    <Input
                      type="number"
                      defaultValue={feeConfig?.rentDefault}
                      onChange={e => setFeeForm(f => ({ ...f, rentDefault: +e.target.value }))}
                    />
                  </div>
                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-1">Electricity Price (₫/kWh)</label>
                    <Input
                      type="number"
                      defaultValue={feeConfig?.elecPrice}
                      onChange={e => setFeeForm(f => ({ ...f, elecPrice: +e.target.value }))}
                    />
                  </div>
                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-1">Water Mode</label>
                    <select
                      className="w-full border border-gray-300 rounded-lg px-3 py-2 text-sm"
                      defaultValue={feeConfig?.waterMode}
                      onChange={e => setFeeForm(f => ({ ...f, waterMode: e.target.value as 'CUBIC' | 'PERSON' }))}
                    >
                      <option value="CUBIC">By cubic meter</option>
                      <option value="PERSON">Per person</option>
                    </select>
                  </div>
                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-1">Water Price (₫)</label>
                    <Input
                      type="number"
                      defaultValue={feeConfig?.waterPrice}
                      onChange={e => setFeeForm(f => ({ ...f, waterPrice: +e.target.value }))}
                    />
                  </div>
                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-1">Service Fee (₫/month)</label>
                    <Input
                      type="number"
                      defaultValue={feeConfig?.serviceFee}
                      onChange={e => setFeeForm(f => ({ ...f, serviceFee: +e.target.value }))}
                    />
                  </div>
                  <Button type="submit" disabled={feeMutation.isPending}>
                    {feeMutation.isPending ? 'Saving…' : 'Save Fee Config'}
                  </Button>
                  {feeMutation.isSuccess && <p className="text-sm text-green-600">Saved successfully</p>}
                  {feeMutation.isError && <p className="text-sm text-red-600">Failed to save</p>}
                </form>
              )}
            </Card>

            {/* Vehicle Config */}
            <Card className="p-6">
              <h2 className="text-lg font-semibold text-gray-800 mb-4">Vehicle Parking Rates</h2>
              {vehicleLoading ? <Spinner /> : (
                <form onSubmit={handleVehicleSubmit} className="space-y-4">
                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-1">Motorbike (₫/month)</label>
                    <Input
                      type="number"
                      defaultValue={vehicleConfig?.motorbikePrice}
                      onChange={e => setVehicleForm(f => ({ ...f, motorbikePrice: +e.target.value }))}
                    />
                  </div>
                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-1">Car (₫/month)</label>
                    <Input
                      type="number"
                      defaultValue={vehicleConfig?.carPrice}
                      onChange={e => setVehicleForm(f => ({ ...f, carPrice: +e.target.value }))}
                    />
                  </div>
                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-1">Bicycle (₫/month)</label>
                    <Input
                      type="number"
                      defaultValue={vehicleConfig?.bicyclePrice}
                      onChange={e => setVehicleForm(f => ({ ...f, bicyclePrice: +e.target.value }))}
                    />
                  </div>
                  <Button type="submit" disabled={vehicleMutation.isPending}>
                    {vehicleMutation.isPending ? 'Saving…' : 'Save Vehicle Config'}
                  </Button>
                  {vehicleMutation.isSuccess && <p className="text-sm text-green-600">Saved successfully</p>}
                  {vehicleMutation.isError && <p className="text-sm text-red-600">Failed to save</p>}
                </form>
              )}
            </Card>
          </div>
        )}

        {!selectedProp && (
          <div className="text-center py-16 text-gray-400">Select a property to configure fees</div>
        )}
      </div>
    </Layout>
  )
}
