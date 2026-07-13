import { useState } from 'react'
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import Layout from '@/components/Layout'
import { Card } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Badge } from '@/components/ui/badge'
import { TableSkeleton } from '@/components/ui/feedback'
import { slaApi } from '@/api/reportApi'
import type { SlaRule } from '@/types'
import { Clock, Plus, Trash2, ShieldCheck, AlertCircle } from 'lucide-react'

export default function SlaConfigPage() {
  const qc = useQueryClient()
  const [priority, setPriority] = useState<string>('HIGH')
  const [category, setCategory] = useState<string>('ELECTRIC')
  const [maxHours, setMaxHours] = useState<number>(6)
  const [errorMsg, setErrorMsg] = useState<string>('')
  const [successMsg, setSuccessMsg] = useState<string>('')

  const { data: rules = [], isLoading } = useQuery<SlaRule[]>({
    queryKey: ['sla-rules'],
    queryFn: slaApi.listRules,
  })

  const saveMutation = useMutation({
    mutationFn: () => slaApi.createOrUpdateRule(priority, category, Number(maxHours)),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ['sla-rules'] })
      setSuccessMsg('Đã lưu quy tắc SLA thành công!')
      setErrorMsg('')
      setTimeout(() => setSuccessMsg(''), 3000)
    },
    onError: (err: any) => {
      setErrorMsg(err?.response?.data?.message ?? 'Đã xảy ra lỗi khi lưu quy tắc SLA.')
      setSuccessMsg('')
    },
  })

  const deleteMutation = useMutation({
    mutationFn: (id: string) => slaApi.deleteRule(id),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ['sla-rules'] })
      setSuccessMsg('Đã xóa quy tắc SLA!')
      setTimeout(() => setSuccessMsg(''), 3000)
    },
    onError: (err: any) => {
      setErrorMsg(err?.response?.data?.message ?? 'Không thể xóa quy tắc này.')
    },
  })

  const priorityLabels: Record<string, { label: string; color: string }> = {
    NORMAL: { label: 'Bình thường', color: 'bg-blue-100 text-blue-800 border-blue-200' },
    HIGH: { label: 'Cao', color: 'bg-amber-100 text-amber-800 border-amber-200' },
    URGENT: { label: 'Khẩn cấp', color: 'bg-red-100 text-red-800 border-red-200' },
  }

  const categoryLabels: Record<string, string> = {
    ELECTRIC: 'Điện',
    PLUMBING: 'Nước / Đường ống',
    AIR_CONDITIONER: 'Điều hòa / Máy lạnh',
    FURNITURE: 'Nội thất',
    OTHER: 'Khác',
  }

  return (
    <Layout>
      <div className="space-y-6 max-w-6xl mx-auto py-6 px-4 sm:px-6">
        <div className="flex flex-col md:flex-row md:items-center md:justify-between gap-4 border-b pb-4">
          <div>
            <h1 className="text-2xl font-bold tracking-tight text-gray-900 flex items-center gap-2">
              <Clock className="w-7 h-7 text-indigo-600" />
              Cấu Hình Quy Tắc SLA Bảo Trì
            </h1>
            <p className="text-sm text-gray-500 mt-1">
              Thiết lập thời gian cam kết giải quyết (Cam kết SLA) tự động cho các yêu cầu bảo trì theo độ ưu tiên và danh mục sự cố.
            </p>
          </div>
        </div>

        {errorMsg && (
          <div className="p-4 bg-red-50 border border-red-200 text-red-700 rounded-xl flex items-center gap-3">
            <AlertCircle className="w-5 h-5 flex-shrink-0 text-red-500" />
            <span>{errorMsg}</span>
          </div>
        )}

        {successMsg && (
          <div className="p-4 bg-emerald-50 border border-emerald-200 text-emerald-700 rounded-xl flex items-center gap-3">
            <ShieldCheck className="w-5 h-5 flex-shrink-0 text-emerald-500" />
            <span>{successMsg}</span>
          </div>
        )}

        <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
          <Card className="p-6 lg:col-span-1 border-indigo-100 shadow-md bg-white rounded-2xl h-fit space-y-5">
            <div className="border-b pb-3">
              <h2 className="text-lg font-semibold text-gray-900 flex items-center gap-2">
                <Plus className="w-5 h-5 text-indigo-600" />
                Thêm / Cập nhật quy tắc
              </h2>
              <p className="text-xs text-gray-500">Nếu quy tắc đã tồn tại, thời gian mới sẽ ghi đè lên.</p>
            </div>

            <div className="space-y-4">
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Độ ưu tiên</label>
                <select
                  value={priority}
                  onChange={(e) => setPriority(e.target.value)}
                  className="w-full rounded-xl border border-gray-300 bg-white px-3 py-2 text-sm focus:border-indigo-500 focus:outline-none focus:ring-1 focus:ring-indigo-500"
                >
                  <option value="URGENT">Khẩn cấp (Urgent)</option>
                  <option value="HIGH">Cao (High)</option>
                  <option value="NORMAL">Bình thường (Normal)</option>
                </select>
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Danh mục sự cố</label>
                <select
                  value={category}
                  onChange={(e) => setCategory(e.target.value)}
                  className="w-full rounded-xl border border-gray-300 bg-white px-3 py-2 text-sm focus:border-indigo-500 focus:outline-none focus:ring-1 focus:ring-indigo-500"
                >
                  <option value="ELECTRIC">Điện (Electric)</option>
                  <option value="PLUMBING">Nước / Đường ống (Plumbing)</option>
                  <option value="AIR_CONDITIONER">Điều hòa / Máy lạnh (Air Conditioner)</option>
                  <option value="FURNITURE">Nội thất (Furniture)</option>
                  <option value="OTHER">Khác (Other)</option>
                </select>
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Thời gian cam kết (Giờ)</label>
                <Input
                  type="number"
                  min={1}
                  max={720}
                  value={maxHours}
                  onChange={(e) => setMaxHours(Number(e.target.value))}
                  className="rounded-xl"
                />
                <p className="text-xs text-gray-400 mt-1">Ví dụ: 2 (giờ), 6 (giờ), 24 (giờ)</p>
              </div>

              <Button
                onClick={() => saveMutation.mutate()}
                disabled={saveMutation.isPending || maxHours <= 0}
                className="w-full bg-indigo-600 hover:bg-indigo-700 text-white rounded-xl py-2.5 font-medium transition shadow-sm"
              >
                {saveMutation.isPending ? 'Đang lưu...' : 'Lưu cấu hình SLA'}
              </Button>
            </div>

            <div className="p-4 bg-indigo-50/60 rounded-xl border border-indigo-100 mt-4 text-xs text-indigo-900 space-y-2">
              <div className="font-semibold flex items-center gap-1.5">
                <ShieldCheck className="w-4 h-4 text-indigo-600" />
                SLA mặc định (Khi không có quy tắc):
              </div>
              <ul className="list-disc list-inside space-y-1 pl-1 text-gray-700">
                <li><span className="font-medium text-red-700">Khẩn cấp:</span> 2 giờ</li>
                <li><span className="font-medium text-amber-700">Cao:</span> 6 giờ</li>
                <li><span className="font-medium text-blue-700">Bình thường:</span> 24 giờ</li>
              </ul>
            </div>
          </Card>

          <Card className="p-6 lg:col-span-2 shadow-md bg-white rounded-2xl border-gray-200">
            <h2 className="text-lg font-semibold text-gray-900 mb-4">Danh sách quy tắc SLA hiện tại</h2>
            {isLoading ? (
              <TableSkeleton columns={4} rows={4} />
            ) : rules.length === 0 ? (
              <div className="text-center py-12 border-2 border-dashed border-gray-200 rounded-xl">
                <Clock className="w-12 h-12 text-gray-300 mx-auto mb-3" />
                <p className="text-gray-500 font-medium">Chưa có cấu hình SLA riêng nào.</p>
                <p className="text-xs text-gray-400 mt-1">Hệ thống đang áp dụng mốc thời gian mặc định theo độ ưu tiên.</p>
              </div>
            ) : (
              <div className="overflow-x-auto rounded-xl border border-gray-200">
                <table className="min-w-full divide-y divide-gray-200 text-sm">
                  <thead className="bg-gray-50 text-gray-600 font-medium">
                    <tr>
                      <th className="px-4 py-3 text-left">Độ ưu tiên</th>
                      <th className="px-4 py-3 text-left">Danh mục</th>
                      <th className="px-4 py-3 text-left">Thời gian giải quyết tối đa</th>
                      <th className="px-4 py-3 text-right">Thao tác</th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-gray-200 bg-white">
                    {rules.map((r) => {
                      const prioInfo = priorityLabels[r.priority ?? 'NORMAL'] ?? { label: r.priority, color: 'bg-gray-100 text-gray-800' }
                      const catLabel = categoryLabels[r.category ?? 'OTHER'] ?? r.category
                      return (
                        <tr key={r.id} className="hover:bg-gray-50/60 transition">
                          <td className="px-4 py-3">
                            <Badge className={`${prioInfo.color} font-medium border`}>{prioInfo.label}</Badge>
                          </td>
                          <td className="px-4 py-3 font-medium text-gray-800">{catLabel}</td>
                          <td className="px-4 py-3">
                            <span className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full bg-indigo-50 text-indigo-700 font-bold text-xs border border-indigo-200">
                              <Clock className="w-3.5 h-3.5" />
                              {r.maxHours} giờ
                            </span>
                          </td>
                          <td className="px-4 py-3 text-right">
                            <Button
                              variant="outline"
                              size="sm"
                              onClick={() => {
                                if (confirm('Bạn có chắc chắn muốn xóa quy tắc SLA này?')) {
                                  deleteMutation.mutate(r.id)
                                }
                              }}
                              disabled={deleteMutation.isPending}
                              className="text-red-600 hover:text-red-700 hover:bg-red-50 border-red-200 rounded-lg"
                            >
                              <Trash2 className="w-4 h-4" />
                            </Button>
                          </td>
                        </tr>
                      )
                    })}
                  </tbody>
                </table>
              </div>
            )}
          </Card>
        </div>
      </div>
    </Layout>
  )
}
