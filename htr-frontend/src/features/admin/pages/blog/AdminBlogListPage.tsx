import { useQuery } from '@tanstack/react-query'
import { Link } from 'react-router-dom'
import { adminBlogApi } from '@/api'
import { postStatusLabel } from '@/lib/utils'

export default function AdminBlogListPage() {
  const { data: rows, isLoading } = useQuery({
    queryKey: ['admin-blog-posts'],
    queryFn: adminBlogApi.listAll,
  })

  return (
    <div className="p-8">
      <h1 className="text-xl font-semibold text-fg">Blog bất động sản</h1>
      <p className="mt-1 text-sm text-fg-muted">Quản lý bài viết cho từng nhà trọ.</p>

      {isLoading && <p className="mt-6 text-sm text-fg-muted">Đang tải…</p>}

      <div className="mt-6 overflow-x-auto rounded-2xl border border-border">
        <table className="w-full text-sm">
          <thead className="bg-surface text-left text-fg-muted">
            <tr>
              <th className="px-4 py-3">Nhà trọ</th>
              <th className="px-4 py-3">Trạng thái</th>
              <th className="px-4 py-3" />
            </tr>
          </thead>
          <tbody>
            {rows?.map(row => {
              const status = !row.postId ? 'NONE' : row.published ? 'PUBLISHED' : 'DRAFT'
              return (
                <tr key={row.propertyId} className="border-t border-border">
                  <td className="px-4 py-3 text-fg">{row.propertyName}</td>
                  <td className="px-4 py-3 text-fg-muted">{postStatusLabel(status)}</td>
                  <td className="px-4 py-3 text-right">
                    <Link to={`/admin/blog/${row.propertyId}`} className="font-medium text-accent hover:text-accent-hover">
                      {row.postId ? 'Chỉnh sửa' : 'Tạo bài viết'}
                    </Link>
                  </td>
                </tr>
              )
            })}
          </tbody>
        </table>
      </div>
    </div>
  )
}
