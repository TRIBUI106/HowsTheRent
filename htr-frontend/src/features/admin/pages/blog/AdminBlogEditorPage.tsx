import { useEffect, useState } from 'react'
import { useNavigate, useParams } from 'react-router-dom'
import { useQuery, useQueryClient } from '@tanstack/react-query'
import { useEditor, EditorContent } from '@tiptap/react'
import StarterKit from '@tiptap/starter-kit'
import { adminBlogApi, roomApi } from '@/api'
import { useGuardedMutation } from '@/hooks/useGuardedMutation'
import { showToast } from '@/lib/toast'
import { getErrorMessage } from '@/lib/apiError'
import { Button } from '@/components/ui/button'
import { Dialog } from '@/components/ui/dialog'
import { Input } from '@/components/ui/input'
import { Select } from '@/components/ui/select'
import Layout from '@/components/Layout'

export default function AdminBlogEditorPage() {
  const { postId } = useParams<{ postId: string }>()
  const isCreating = !postId
  const navigate = useNavigate()
  const qc = useQueryClient()
  const [roomId, setRoomId] = useState('')
  const [title, setTitle] = useState('')
  const [slug, setSlug] = useState('')
  const [coverImageUrl, setCoverImageUrl] = useState<string | null>(null)
  const [deleteOpen, setDeleteOpen] = useState(false)

  const { data: post, isLoading } = useQuery({
    queryKey: ['admin-blog-post', postId],
    queryFn: () => adminBlogApi.get(postId!),
    enabled: !!postId,
    retry: false,
  })
  const { data: rooms } = useQuery({
    queryKey: ['rooms-all'],
    queryFn: roomApi.listAll,
    enabled: isCreating,
  })

  const editor = useEditor({ extensions: [StarterKit], content: '' })

  useEffect(() => {
    if (post) {
      // Synchronize the Tiptap instance and form with the loaded server record.
      // eslint-disable-next-line react-hooks/set-state-in-effect
      setTitle(post.title)
      setSlug(post.slug)
      setCoverImageUrl(post.coverImageUrl)
      editor?.commands.setContent(post.content ?? '')
    }
  }, [post, editor])

  const invalidate = () => {
    qc.invalidateQueries({ queryKey: ['admin-blog-posts'] })
    if (postId) qc.invalidateQueries({ queryKey: ['admin-blog-post', postId] })
  }

  const save = useGuardedMutation({
    mutationFn: () => {
      const payload = {
        title,
        slug: slug || undefined,
        content: editor?.getHTML() ?? '',
        coverImageUrl: coverImageUrl ?? undefined,
      }
      return isCreating
        ? adminBlogApi.create({ roomId, ...payload })
        : adminBlogApi.update(postId!, payload)
    },
    onSuccess: saved => {
      invalidate()
      showToast({ message: isCreating ? 'Đã tạo bản nháp' : 'Đã lưu bài viết', type: 'success' })
      if (isCreating) navigate(`/admin/blog/${saved.id}`, { replace: true })
    },
    onError: (err: unknown) => showToast({ message: getErrorMessage(err, 'Lưu bài viết thất bại'), type: 'error' }),
  })

  const generateDraft = useGuardedMutation({
    mutationFn: () => adminBlogApi.generateDraft(isCreating ? roomId : post!.roomId),
    onSuccess: draft => {
      setTitle(draft.title)
      editor?.commands.setContent(draft.content)
      if (draft.coverImageUrl) setCoverImageUrl(draft.coverImageUrl)
    },
    onError: (err: unknown) => showToast({ message: getErrorMessage(err, 'Tạo bản nháp thất bại'), type: 'error' }),
  })

  const togglePublish = useGuardedMutation({
    mutationFn: () => post!.published ? adminBlogApi.unpublish(postId!) : adminBlogApi.publish(postId!),
    onSuccess: invalidate,
    onError: (err: unknown) => showToast({ message: getErrorMessage(err, 'Cập nhật trạng thái thất bại'), type: 'error' }),
  })

  const uploadCoverImage = useGuardedMutation({
    mutationFn: (file: File) => adminBlogApi.uploadCoverImage(postId!, file),
    onSuccess: updated => {
      setCoverImageUrl(updated.coverImageUrl)
      invalidate()
    },
    onError: (err: unknown) => showToast({ message: getErrorMessage(err, 'Tải ảnh bìa thất bại'), type: 'error' }),
  })

  const deletePost = useGuardedMutation({
    mutationFn: () => adminBlogApi.delete(postId!),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ['admin-blog-posts'] })
      showToast({ message: 'Đã xóa bài viết', type: 'success' })
      navigate('/admin/blog')
    },
    onError: (err: unknown) => showToast({ message: getErrorMessage(err, 'Xóa bài viết thất bại'), type: 'error' }),
  })

  const roomsByProperty = rooms?.reduce<Record<string, typeof rooms>>((groups, room) => {
    ;(groups[room.propertyName] ??= []).push(room)
    return groups
  }, {})

  const canGenerateDraft = isCreating ? !!roomId : !!post
  const canSave = !!title.trim() && (!isCreating || !!roomId)

  return (
    <Layout title={isCreating ? 'Tạo bài viết mới' : 'Soạn bài viết'}>
      <div className="flex flex-wrap items-center justify-end gap-2">
        {post?.published && (
          <a href={`/blog/${post.slug}`} target="_blank" rel="noreferrer" className="text-sm font-medium text-accent hover:text-accent-hover">Xem trước</a>
        )}
        <Button type="button" variant="secondary" onClick={() => generateDraft.mutate(undefined)} disabled={!canGenerateDraft} loading={generateDraft.isPending}>
          Tạo bản nháp tự động
        </Button>
        {post && (
          <>
            <Button type="button" variant="secondary" onClick={() => togglePublish.mutate(undefined)} loading={togglePublish.isPending}>
              {post.published ? 'Gỡ xuất bản' : 'Xuất bản'}
            </Button>
            <Button type="button" variant="danger" onClick={() => setDeleteOpen(true)}>Xóa</Button>
          </>
        )}
      </div>

      {isCreating && (
        <div className="mt-6 max-w-xl">
          <Select label="Phòng đăng bài" value={roomId} onChange={e => setRoomId(e.target.value)} required>
            <option value="">Chọn phòng</option>
            {Object.entries(roomsByProperty ?? {}).map(([propertyName, propertyRooms]) => (
              <optgroup key={propertyName} label={propertyName}>
                {propertyRooms.map(room => <option key={room.id} value={room.id}>Phòng {room.roomNumber}</option>)}
              </optgroup>
            ))}
          </Select>
          <p className="mt-2 text-xs text-fg-muted">Mỗi phòng có thể có nhiều bài viết theo thời gian.</p>
        </div>
      )}

      {!isCreating && !post && !isLoading && <p className="mt-4 text-sm text-fg-muted">Không tìm thấy bài viết này.</p>}

      <div className="mt-6 space-y-5">
        <Input label="Tiêu đề" value={title} onChange={e => setTitle(e.target.value)} required />
        <Input label="Đường dẫn (slug)" value={slug} onChange={e => setSlug(e.target.value)} hint="Để trống để tự tạo từ tiêu đề" />

        <div>
          <p className="mb-2 text-sm font-medium text-fg">Ảnh bìa</p>
          {coverImageUrl && <img src={coverImageUrl} alt="" className="mb-2 h-40 w-full rounded-xl object-cover" />}
          {post ? (
            <input type="file" accept="image/*" onChange={e => {
              const file = e.target.files?.[0]
              if (file) uploadCoverImage.mutate(file)
            }} />
          ) : (
            <p className="text-xs text-fg-muted">Lưu bản nháp trước để tải ảnh bìa riêng, hoặc dùng ảnh mặc định của phòng.</p>
          )}
        </div>

        <div>
          <p className="mb-2 text-sm font-medium text-fg">Nội dung</p>
          <div className="min-h-40 rounded-xl border border-border bg-bg p-3"><EditorContent editor={editor} /></div>
        </div>

        <Button type="button" onClick={() => save.mutate(undefined)} disabled={!canSave} loading={save.isPending}>
          {isCreating ? 'Tạo bản nháp' : 'Lưu bài viết'}
        </Button>
      </div>

      <Dialog open={deleteOpen} onClose={() => setDeleteOpen(false)} title="Xóa bài viết?">
        <p className="text-sm leading-6 text-fg-muted">Bình luận và lượt thích của bài viết này cũng sẽ bị xóa. Thao tác này không thể hoàn tác.</p>
        <div className="mt-6 flex justify-end gap-3">
          <Button type="button" variant="secondary" onClick={() => setDeleteOpen(false)}>Hủy</Button>
          <Button type="button" variant="danger" loading={deletePost.isPending} onClick={() => deletePost.mutate(undefined)}>Xóa bài viết</Button>
        </div>
      </Dialog>
    </Layout>
  )
}
