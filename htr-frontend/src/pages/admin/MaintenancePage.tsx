import { useQuery } from '@tanstack/react-query'
import api from '@/lib/api'
import Layout from '@/components/Layout'
import { Card } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import { Table, TableRow, TableCell } from '@/components/ui/table'
import { formatDate } from '@/lib/utils'
import type { MaintenanceRequest } from '@/types'

export default function AdminMaintenancePage() {
  const { data: requests, isLoading } = useQuery<MaintenanceRequest[]>({
    queryKey: ['maintenance'],
    queryFn: () => api.get('/maintenance').then(r => r.data),
  })

  return (
    <Layout title="Bảo trì">
      {isLoading ? (
        <div className="flex h-32 items-center justify-center">
          <div className="animate-spin h-6 w-6 border-2 border-blue-600 border-t-transparent rounded-full" />
        </div>
      ) : (
        <Card>
          <Table headers={['Tiêu đề', 'Phòng', 'Người thuê', 'Trạng thái', 'Ngày tạo']}>
            {requests?.map(req => (
              <TableRow key={req.id}>
                <TableCell className="font-medium">{req.title}</TableCell>
                <TableCell>{req.room?.roomNumber}</TableCell>
                <TableCell>{req.tenant?.fullName}</TableCell>
                <TableCell><Badge status={req.status} /></TableCell>
                <TableCell>{formatDate(req.createdAt)}</TableCell>
              </TableRow>
            ))}
          </Table>
        </Card>
      )}
    </Layout>
  )
}