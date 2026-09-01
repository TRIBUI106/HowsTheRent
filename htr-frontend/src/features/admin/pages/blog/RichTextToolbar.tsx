import type { Editor } from '@tiptap/react'
import { Bold, Heading2, Heading3, Italic, List, ListOrdered, Quote, Redo2, Strikethrough, Undo2 } from 'lucide-react'
import { cn } from '@/lib/utils'

type ToolbarButton = {
  label: string
  icon: typeof Bold
  onClick: (editor: Editor) => void
  isActive?: (editor: Editor) => boolean
  isDisabled?: (editor: Editor) => boolean
}

const buttonGroups: ToolbarButton[][] = [
  [
    { label: 'Đậm', icon: Bold, onClick: editor => editor.chain().focus().toggleBold().run(), isActive: editor => editor.isActive('bold') },
    { label: 'Nghiêng', icon: Italic, onClick: editor => editor.chain().focus().toggleItalic().run(), isActive: editor => editor.isActive('italic') },
    { label: 'Gạch ngang', icon: Strikethrough, onClick: editor => editor.chain().focus().toggleStrike().run(), isActive: editor => editor.isActive('strike') },
  ],
  [
    { label: 'Đề mục cấp 2', icon: Heading2, onClick: editor => editor.chain().focus().toggleHeading({ level: 2 }).run(), isActive: editor => editor.isActive('heading', { level: 2 }) },
    { label: 'Đề mục cấp 3', icon: Heading3, onClick: editor => editor.chain().focus().toggleHeading({ level: 3 }).run(), isActive: editor => editor.isActive('heading', { level: 3 }) },
  ],
  [
    { label: 'Danh sách gạch đầu dòng', icon: List, onClick: editor => editor.chain().focus().toggleBulletList().run(), isActive: editor => editor.isActive('bulletList') },
    { label: 'Danh sách đánh số', icon: ListOrdered, onClick: editor => editor.chain().focus().toggleOrderedList().run(), isActive: editor => editor.isActive('orderedList') },
    { label: 'Trích dẫn', icon: Quote, onClick: editor => editor.chain().focus().toggleBlockquote().run(), isActive: editor => editor.isActive('blockquote') },
  ],
  [
    { label: 'Hoàn tác', icon: Undo2, onClick: editor => editor.chain().focus().undo().run(), isDisabled: editor => !editor.can().undo() },
    { label: 'Làm lại', icon: Redo2, onClick: editor => editor.chain().focus().redo().run(), isDisabled: editor => !editor.can().redo() },
  ],
]

export default function RichTextToolbar({ editor }: { editor: Editor | null }) {
  return (
    <div className="flex flex-wrap items-center gap-1 border-b border-border p-2">
      {buttonGroups.map((group, groupIndex) => (
        <div key={groupIndex} className="flex items-center gap-1">
          {groupIndex > 0 && <span className="mx-1 h-5 w-px bg-border" aria-hidden="true" />}
          {group.map(({ label, icon: Icon, onClick, isActive, isDisabled }) => {
            const active = !!editor && isActive?.(editor)
            const disabled = !editor || !!isDisabled?.(editor)
            return (
              <button
                key={label}
                type="button"
                title={label}
                aria-label={label}
                disabled={disabled}
                onClick={() => editor && onClick(editor)}
                className={cn(
                  'rounded-md p-1.5 text-fg-muted transition-colors hover:bg-sidebar/60 disabled:cursor-not-allowed disabled:opacity-40 disabled:hover:bg-transparent',
                  active && 'bg-accent/10 text-accent hover:bg-accent/10'
                )}
              >
                <Icon size={16} />
              </button>
            )
          })}
        </div>
      ))}
    </div>
  )
}
