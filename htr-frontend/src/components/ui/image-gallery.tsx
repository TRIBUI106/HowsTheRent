import { useRef, useState } from 'react'
import { ImagePlus, Trash2, X } from 'lucide-react'
import { cn } from '@/lib/utils'
import { Button } from '@/components/ui/button'
import { Dialog } from '@/components/ui/dialog'

interface ImageGalleryProps {
  images: string[]
  onUpload: (files: File[]) => void
  onDelete: (imageUrl: string) => void
  uploading?: boolean
  /** URL of the image currently being deleted, if any — shows a per-item spinner. */
  deletingUrl?: string | null
  emptyLabel?: string
  className?: string
}

export function ImageGallery({
  images,
  onUpload,
  onDelete,
  uploading,
  deletingUrl,
  emptyLabel = 'Chưa có hình ảnh nào.',
  className,
}: ImageGalleryProps) {
  const [pendingDeleteUrl, setPendingDeleteUrl] = useState<string | null>(null)
  const fileInputRef = useRef<HTMLInputElement>(null)

  function handleFilesSelected(e: React.ChangeEvent<HTMLInputElement>) {
    const files = Array.from(e.target.files ?? [])
    if (files.length > 0) onUpload(files)
    e.target.value = ''
  }

  function confirmDelete() {
    if (!pendingDeleteUrl) return
    onDelete(pendingDeleteUrl)
    setPendingDeleteUrl(null)
  }

  return (
    <div className={cn('space-y-3', className)}>
      <input
        ref={fileInputRef}
        type="file"
        accept="image/*"
        multiple
        className="hidden"
        onChange={handleFilesSelected}
      />

      {images.length === 0 ? (
        <p className="text-sm text-fg-subtle text-center py-6">{emptyLabel}</p>
      ) : (
        <div className="grid grid-cols-3 gap-3 sm:grid-cols-4 md:grid-cols-6">
          {images.map(url => (
            <div key={url} className="group relative aspect-square overflow-hidden rounded-xl border border-border bg-sidebar/50">
              <a href={url} target="_blank" rel="noreferrer">
                <img src={url} alt="Hình phòng" className="h-full w-full object-cover" />
              </a>
              <button
                type="button"
                onClick={() => setPendingDeleteUrl(url)}
                disabled={deletingUrl === url}
                aria-label="Xóa ảnh"
                className="absolute right-1.5 top-1.5 flex h-6 w-6 items-center justify-center rounded-full bg-fg/60 text-white opacity-0 transition-opacity group-hover:opacity-100 hover:bg-error disabled:opacity-100"
              >
                {deletingUrl === url ? (
                  <span className="h-3 w-3 animate-spin rounded-full border-2 border-white border-t-transparent" />
                ) : (
                  <X size={13} />
                )}
              </button>
            </div>
          ))}
        </div>
      )}

      <Button
        type="button"
        variant="secondary"
        size="sm"
        loading={uploading}
        onClick={() => fileInputRef.current?.click()}
      >
        {!uploading && <ImagePlus size={14} className="mr-1.5" />}
        {uploading ? 'Đang tải lên...' : 'Thêm ảnh'}
      </Button>

      <Dialog open={!!pendingDeleteUrl} onClose={() => setPendingDeleteUrl(null)} title="Xóa ảnh này?">
        <div className="space-y-5">
          <p className="text-sm leading-6 text-fg-muted">
            Ảnh sẽ bị xóa khỏi phòng và không thể khôi phục.
          </p>
          <div className="flex justify-end gap-2">
            <Button type="button" variant="secondary" onClick={() => setPendingDeleteUrl(null)}>Hủy</Button>
            <Button type="button" variant="danger" onClick={confirmDelete}>
              <Trash2 size={14} className="mr-1.5" />
              Xác nhận xóa
            </Button>
          </div>
        </div>
      </Dialog>
    </div>
  )
}
