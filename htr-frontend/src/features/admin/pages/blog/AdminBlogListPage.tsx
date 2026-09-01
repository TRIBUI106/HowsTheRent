import { useState } from 'react'
import { useQuery, useQueryClient } from '@tanstack/react-query'
import { Link } from 'react-router-dom'
import { Eye, EyeOff, Heart, Pencil, Trash2 } from 'lucide-react'
import { adminBlogApi } from '@/api'
import { formatDate, postStatusLabel } from '@/lib/utils'
import { useGuardedMutation } from '@/hooks/useGuardedMutation'
import { showToast } from '@/lib/toast'
import { getErrorMessage } from '@/lib/apiError'
import { Button } from '@/components/ui/button'
import { Dialog } from '@/components/ui/dialog'
import Layout from '@/components/Layout'
import AdminBlogTabs from './AdminBlogTabs'

export default function AdminBlogListPage() {
  const qc = useQueryClient()
  const [deletingPostId, setDeletingPostId] = useState<string | null>(null)
  const { data: posts, isLoading } = useQuery({
    queryKey: ['admin-blog-posts'],
    queryFn: adminBlogApi.listAll,
  })

  const invalidatePosts = () => qc.invalidateQueries({ queryKey: ['admin-blog-posts'] })

  const togglePublish = useGuardedMutation({
    mutationFn: (post: { postId: string; published: boolean }) =>
      post.published ? adminBlogApi.unpublish(post.postId) : adminBlogApi.publish(post.postId),
    onSuccess: invalidatePosts,
    onError: (err: unknown) => showToast({ message: getErrorMessage(err, 'Cập nhật trạng thái thất bại'), type: 'error' }),
  })

  const deletePost = useGuardedMutation({
    mutationFn: (postId: string) => adminBlogApi.delete(postId),
    onSuccess: () => {
      setDeletingPostId(null)
      invalidatePosts()
      showToast({ message: 'Đã xóa bài viết', type: 'success' })
    },
    onError: (err: unknown) => showToast({ message: getErrorMessage(err, 'Xóa bài viết thất bại'), type: 'error' }),
  })

  return (
    <Layout title="Blog bất động sản">
      <div className="flex flex-wrap items-center justify-between gap-3">
        <p className="text-sm text-fg-muted">Quản lý nhiều bài viết theo từng phòng.</p>
        <Link to="/admin/blog/new">
          <Button type="button">+ Tạo bài mới</Button>
        </Link>
      </div>

      <div className="mt-4">
        <AdminBlogTabs />
      </div>

      {isLoading && <p className="mt-6 text-sm text-fg-muted">Đang tải…</p>}

      {!isLoading && posts?.length === 0 && (
        <p className="mt-6 rounded-xl border border-dashed border-border px-4 py-8 text-center text-sm text-fg-muted">
          Chưa có bài viết nào. Hãy tạo bài viết đầu tiên cho một phòng.
        </p>
      )}

      {!!posts?.length && (
        <div className="mt-6 overflow-x-auto rounded-2xl border border-border">
          <table className="w-full text-sm">
            <thead className="bg-surface text-left text-fg-muted">
              <tr>
                <th className="px-4 py-3">Phòng</th>
                <th className="px-4 py-3">Nhà trọ</th>
                <th className="px-4 py-3">Tiêu đề</th>
                <th className="px-4 py-3">Trạng thái</th>
                <th className="px-4 py-3">Lượt thích</th>
                <th className="px-4 py-3">Cập nhật</th>
                <th className="px-4 py-3" />
              </tr>
            </thead>
            <tbody>
              {posts.map(post => (
                <tr key={post.postId} className="border-t border-border">
                  <td className="px-4 py-3 font-medium text-fg">{post.roomNumber}</td>
                  <td className="px-4 py-3 text-fg-muted">{post.propertyName}</td>
                  <td className="px-4 py-3 text-fg">
                    <Link to={`/admin/blog/${post.postId}`} className="font-medium hover:text-accent">
                      {post.title}
                    </Link>
                  </td>
                  <td className="px-4 py-3 text-fg-muted">{postStatusLabel(post.published ? 'PUBLISHED' : 'DRAFT')}</td>
                  <td className="px-4 py-3 text-fg-muted">
                    <span className="inline-flex items-center gap-1">
                      <Heart size={14} />
                      {post.likeCount}
                    </span>
                  </td>
                  <td className="px-4 py-3 text-fg-muted">{formatDate(post.updatedAt)}</td>
                  <td className="px-4 py-3">
                    <div className="flex justify-end gap-3 whitespace-nowrap">
                      <button
                        type="button"
                        onClick={() => togglePublish.mutate(post)}
                        disabled={togglePublish.isPending}
                        aria-label={post.published ? 'Gỡ xuất bản' : 'Xuất bản'}
                        title={post.published ? 'Gỡ xuất bản' : 'Xuất bản'}
                        className="text-accent hover:text-accent-hover disabled:opacity-50"
                      >
                        {post.published ? <EyeOff size={16} /> : <Eye size={16} />}
                      </button>
                      <Link
                        to={`/admin/blog/${post.postId}`}
                        aria-label="Sửa"
                        title="Sửa"
                        className="text-accent hover:text-accent-hover"
                      >
                        <Pencil size={16} />
                      </Link>
                      <button
                        type="button"
                        onClick={() => setDeletingPostId(post.postId)}
                        aria-label="Xóa"
                        title="Xóa"
                        className="text-error hover:text-error-hover"
                      >
                        <Trash2 size={16} />
                      </button>
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}

      <Dialog open={deletingPostId !== null} onClose={() => setDeletingPostId(null)} title="Xóa bài viết?">
        <p className="text-sm leading-6 text-fg-muted">Bình luận và lượt thích của bài viết này cũng sẽ bị xóa. Thao tác này không thể hoàn tác.</p>
        <div className="mt-6 flex justify-end gap-3">
          <Button type="button" variant="secondary" onClick={() => setDeletingPostId(null)}>Hủy</Button>
          <Button type="button" variant="danger" loading={deletePost.isPending} onClick={() => deletingPostId && deletePost.mutate(deletingPostId)}>Xóa bài viết</Button>
        </div>
      </Dialog>
    </Layout>
  )
}
