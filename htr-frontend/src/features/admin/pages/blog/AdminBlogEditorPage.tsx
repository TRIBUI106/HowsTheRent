import { useState, useEffect } from 'react'
import { useParams } from 'react-router-dom'
import { useQuery, useQueryClient } from '@tanstack/react-query'
import { useEditor, EditorContent } from '@tiptap/react'
import StarterKit from '@tiptap/starter-kit'
import { adminBlogApi } from '@/api'
import { useGuardedMutation } from '@/hooks/useGuardedMutation'
import { showToast } from '@/lib/toast'
import { getErrorMessage } from '@/lib/apiError'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'

export default function AdminBlogEditorPage() {
  const { propertyId = '' } = useParams<{ propertyId: string }>()
  const qc = useQueryClient()
  const [title, setTitle] = useState('')
  const [slug, setSlug] = useState('')
  const [coverImageUrl, setCoverImageUrl] = useState<string | null>(null)

  const { data: post, isError } = useQuery({
    queryKey: ['admin-blog-post', propertyId],
    queryFn: () => adminBlogApi.get(propertyId),
    enabled: !!propertyId,
    retry: false,
  })

  const editor = useEditor({ extensions: [StarterKit], content: '' })

  useEffect(() => {
    if (post) {
      // This synchronizes form fields with the server-loaded post.
      // eslint-disable-next-line react-hooks/set-state-in-effect
      setTitle(post.title)
      setSlug(post.slug)
      setCoverImageUrl(post.coverImageUrl)
      editor?.commands.setContent(post.content ?? '')
    }
  }, [post, editor])

  const save = useGuardedMutation({
    mutationFn: () => adminBlogApi.update(propertyId, {
      title,
      slug: slug || undefined,
      content: editor?.getHTML() ?? '',
      coverImageUrl: coverImageUrl ?? undefined,
    }),
    onSuccess: () => {
      showToast({ message: 'Đã lưu bài viết', type: 'success' })
      qc.invalidateQueries({ queryKey: ['admin-blog-post', propertyId] })
      qc.invalidateQueries({ queryKey: ['admin-blog-posts'] })
    },
    onError: (err: unknown) => showToast({ message: getErrorMessage(err, 'Lưu bài viết thất bại'), type: 'error' }),
  })

  const generateDraft = useGuardedMutation({
    mutationFn: () => adminBlogApi.generateDraft(propertyId),
    onSuccess: draft => {
      setTitle(draft.title)
      editor?.commands.setContent(draft.content)
      if (draft.coverImageUrl) setCoverImageUrl(draft.coverImageUrl)
    },
    onError: (err: unknown) => showToast({ message: getErrorMessage(err, 'Tạo bản nháp thất bại'), type: 'error' }),
  })

  const togglePublish = useGuardedMutation({
    mutationFn: () => (post?.published ? adminBlogApi.unpublish(propertyId) : adminBlogApi.publish(propertyId)),
    onSuccess: () => qc.invalidateQueries({ queryKey: ['admin-blog-post', propertyId] }),
    onError: (err: unknown) => showToast({ message: getErrorMessage(err, 'Cập nhật trạng thái thất bại'), type: 'error' }),
  })

  const uploadCoverImage = useGuardedMutation({
    mutationFn: (file: File) => adminBlogApi.uploadCoverImage(propertyId, file),
    onSuccess: updated => setCoverImageUrl(updated.coverImageUrl),
    onError: (err: unknown) => showToast({ message: getErrorMessage(err, 'Tải ảnh bìa thất bại'), type: 'error' }),
  })

  return (
    <div className="p-8">
      <div className="flex items-center justify-between">
        <h1 className="text-xl font-semibold text-fg">Soạn bài viết</h1>
        <div className="flex items-center gap-2">
          {post?.published && (
            <a href={`/blog/${post.slug}`} target="_blank" rel="noreferrer" className="text-sm font-medium text-accent hover:text-accent-hover">
              Xem trước
            </a>
          )}
          <Button type="button" variant="secondary" onClick={() => generateDraft.mutate(undefined)} loading={generateDraft.isPending}>
            Tạo bản nháp tự động
          </Button>
          {post && (
            <Button type="button" variant="secondary" onClick={() => togglePublish.mutate(undefined)} loading={togglePublish.isPending}>
              {post.published ? 'Gỡ xuất bản' : 'Xuất bản'}
            </Button>
          )}
        </div>
      </div>

      {isError && !post && (
        <p className="mt-4 text-sm text-fg-muted">
          Chưa có bài viết cho nhà trọ này — điền thông tin và lưu để tạo mới, hoặc bấm &quot;Tạo bản nháp tự động&quot;.
        </p>
      )}

      <div className="mt-6 space-y-5">
        <Input label="Tiêu đề" value={title} onChange={e => setTitle(e.target.value)} required />
        <Input label="Đường dẫn (slug)" value={slug} onChange={e => setSlug(e.target.value)} hint="Để trống để tự tạo từ tiêu đề" />

        <div>
          <p className="mb-2 text-sm font-medium text-fg">Ảnh bìa</p>
          {coverImageUrl && <img src={coverImageUrl} alt="" className="mb-2 h-40 w-full rounded-xl object-cover" />}
          <input
            type="file"
            accept="image/*"
            onChange={e => {
              const file = e.target.files?.[0]
              if (file) uploadCoverImage.mutate(file)
            }}
          />
        </div>

        <div>
          <p className="mb-2 text-sm font-medium text-fg">Nội dung</p>
          <div className="rounded-xl border border-border bg-bg p-3">
            <EditorContent editor={editor} />
          </div>
        </div>

        <Button type="button" onClick={() => save.mutate(undefined)} loading={save.isPending}>
          Lưu bài viết
        </Button>
      </div>
    </div>
  )
}
