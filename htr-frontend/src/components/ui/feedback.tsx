import { cn } from '@/lib/utils'

interface SpinnerProps {
  className?: string
}

export function Spinner({ className }: SpinnerProps) {
  return (
    <svg className={cn('animate-spin h-5 w-5 text-accent', className)} xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
      <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4" />
      <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4z" />
    </svg>
  )
}

export function LoadingScreen() {
  return (
    <div className="rounded-2xl border border-border/80 bg-surface px-5 py-6">
      <div className="flex items-center gap-3">
        <Spinner className="h-5 w-5" />
        <div>
          <p className="text-sm font-medium text-fg">Đang tải dữ liệu</p>
          <p className="text-xs text-fg-subtle">Vui lòng chờ trong giây lát.</p>
        </div>
      </div>
    </div>
  )
}

export function EmptyState({ message = 'Không có dữ liệu' }: { message?: string }) {
  return (
    <div className="rounded-2xl border border-dashed border-border-strong/70 bg-sidebar/45 px-5 py-8 text-center">
      <p className="text-sm font-medium text-fg">Chưa có nội dung</p>
      <p className="mt-1 text-sm text-fg-subtle">{message}</p>
    </div>
  )
}
