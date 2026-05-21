import { Button } from '@/components/ui/button'
import { ChevronLeft, ChevronRight } from 'lucide-react'

interface PaginationProps {
  page: number
  totalPages: number
  onPageChange: (page: number) => void
  className?: string
}

export function Pagination({ page, totalPages, onPageChange, className }: PaginationProps) {
  if (totalPages <= 1) return null

  return (
    <div className={`flex items-center justify-between py-3 ${className ?? ''}`}>
      <p className="text-sm text-fg-muted">
        Trang {page + 1} / {totalPages}
      </p>
      <div className="flex items-center gap-2">
        <Button
          size="sm"
          variant="outline"
          onClick={() => onPageChange(page - 1)}
          disabled={page === 0}
        >
          <ChevronLeft size={15} />
          Trước
        </Button>
        <div className="flex items-center gap-1">
          {Array.from({ length: Math.min(totalPages, 5) }, (_, i) => {
            const p = totalPages <= 5 ? i : Math.max(0, Math.min(page - 2, totalPages - 5)) + i
            return (
              <button
                key={p}
                onClick={() => onPageChange(p)}
                className={`w-8 h-8 text-sm rounded-lg transition-colors duration-100 font-medium ${
                  p === page
                    ? 'bg-accent text-accent-fg'
                    : 'text-fg-muted hover:bg-sidebar hover:text-fg'
                }`}
              >
                {p + 1}
              </button>
            )
          })}
        </div>
        <Button
          size="sm"
          variant="outline"
          onClick={() => onPageChange(page + 1)}
          disabled={page >= totalPages - 1}
        >
          Sau
          <ChevronRight size={15} />
        </Button>
      </div>
    </div>
  )
}
