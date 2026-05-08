import { useState } from 'react'
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import Layout from '@/components/Layout'
import { Card } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { Badge } from '@/components/ui/badge'
import { Spinner } from '@/components/ui/feedback'
import api from '@/lib/api'

interface Contract {
  id: string
  room: { id: string; roomNumber: string; property: { name: string } }
  tenant: { id: string; fullName: string; email: string }
  moveInDate: string
  moveOutDate?: string
  status: string
  depositAmount: number
  notes?: string
}

export default function ContractsPage() {
  const qc = useQueryClient()
  const [terminating, setTerminating] = useState<string | null>(null)

  const { data: contracts, isLoading, error } = useQuery<Contract[]>({
    queryKey: ['admin-contracts'],
    queryFn: () => api.get('/contracts').then(r => r.data),
  })

  const terminateMutation = useMutation({
    mutationFn: (id: string) => api.put(`/contracts/${id}/terminate`),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ['admin-contracts'] })
      setTerminating(null)
    },
  })

  if (isLoading) return <Layout><Spinner /></Layout>
  if (error) return <Layout><div className="p-6 text-red-600">Failed to load contracts</div></Layout>

  return (
    <Layout>
      <div className="p-6 space-y-4">
        <div className="flex items-center justify-between">
          <h1 className="text-2xl font-bold text-gray-900">Contracts</h1>
        </div>

        <Card className="overflow-hidden">
          <div className="overflow-x-auto">
            <table className="min-w-full divide-y divide-gray-200">
              <thead className="bg-gray-50">
                <tr>
                  {['Room', 'Property', 'Tenant', 'Move-in', 'Move-out', 'Deposit', 'Status', 'Actions'].map(h => (
                    <th key={h} className="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">{h}</th>
                  ))}
                </tr>
              </thead>
              <tbody className="bg-white divide-y divide-gray-200">
                {contracts?.map(c => (
                  <tr key={c.id} className="hover:bg-gray-50">
                    <td className="px-4 py-3 text-sm font-medium text-gray-900">{c.room.roomNumber}</td>
                    <td className="px-4 py-3 text-sm text-gray-600">{c.room.property.name}</td>
                    <td className="px-4 py-3 text-sm text-gray-600">
                      <div>{c.tenant.fullName}</div>
                      <div className="text-xs text-gray-400">{c.tenant.email}</div>
                    </td>
                    <td className="px-4 py-3 text-sm text-gray-600">{c.moveInDate}</td>
                    <td className="px-4 py-3 text-sm text-gray-600">{c.moveOutDate ?? '—'}</td>
                    <td className="px-4 py-3 text-sm text-gray-600">{Number(c.depositAmount).toLocaleString('vi-VN')} ₫</td>
                    <td className="px-4 py-3">
                      <Badge status={c.status} />
                    </td>
                    <td className="px-4 py-3">
                      {c.status === 'ACTIVE' && (
                        terminating === c.id ? (
                          <div className="flex gap-2">
                            <Button
                              size="sm"
                              variant="danger"
                              onClick={() => terminateMutation.mutate(c.id)}
                              disabled={terminateMutation.isPending}
                            >
                              Confirm
                            </Button>
                            <Button size="sm" variant="outline" onClick={() => setTerminating(null)}>Cancel</Button>
                          </div>
                        ) : (
                          <Button size="sm" variant="outline" onClick={() => setTerminating(c.id)}>
                            Terminate
                          </Button>
                        )
                      )}
                    </td>
                  </tr>
                ))}
                {contracts?.length === 0 && (
                  <tr><td colSpan={8} className="px-4 py-8 text-center text-gray-400">No contracts found</td></tr>
                )}
              </tbody>
            </table>
          </div>
        </Card>
      </div>
    </Layout>
  )
}
