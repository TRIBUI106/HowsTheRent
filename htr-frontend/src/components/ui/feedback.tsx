import { cn } from '@/lib/utils'

interface SpinnerProps {
  className?: string
}

interface SkeletonProps {
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

export function Skeleton({ className }: SkeletonProps) {
  return <div className={cn('animate-pulse rounded-xl bg-sidebar/80', className)} />
}

export function LoadingScreen() {
  return (
    <div className="rounded-2xl border border-border/80 bg-surface px-5 py-6 animate-fade-in">
      <div className="space-y-3">
        <Skeleton className="h-4 w-32" />
        <Skeleton className="h-3 w-48" />
      </div>
    </div>
  )
}

export function TableSkeleton({ rows = 5, columns = 6 }: { rows?: number; columns?: number }) {
  return (
    <div className="rounded-2xl border border-border/80 bg-surface animate-fade-in overflow-hidden">
      <div className="border-b border-border/60 bg-sidebar/40 px-4 py-3">
        <div className="grid gap-3" style={{ gridTemplateColumns: `repeat(${columns}, minmax(0, 1fr))` }}>
          {Array.from({ length: columns }).map((_, i) => <Skeleton key={i} className="h-3 w-3/4" />)}
        </div>
      </div>
      <div className="divide-y divide-border/60">
        {Array.from({ length: rows }).map((_, row) => (
          <div key={row} className="grid gap-3 px-4 py-4" style={{ gridTemplateColumns: `repeat(${columns}, minmax(0, 1fr))` }}>
            {Array.from({ length: columns }).map((__, col) => <Skeleton key={col} className="h-4 w-full" />)}
          </div>
        ))}
      </div>
    </div>
  )
}

export function CardsSkeleton({ count = 3 }: { count?: number }) {
  return (
    <div className="grid grid-cols-1 gap-4 md:grid-cols-2 xl:grid-cols-3 animate-fade-in">
      {Array.from({ length: count }).map((_, i) => (
        <div key={i} className="rounded-2xl border border-border/80 bg-surface p-5 space-y-3">
          <Skeleton className="h-5 w-24" />
          <Skeleton className="h-3 w-40" />
          <Skeleton className="h-10 w-full" />
          <Skeleton className="h-10 w-full" />
        </div>
      ))}
    </div>
  )
}

export function ListSkeleton({ items = 4 }: { items?: number }) {
  return (
    <div className="space-y-4 animate-fade-in">
      {Array.from({ length: items }).map((_, i) => (
        <div key={i} className="rounded-2xl border border-border/80 bg-surface p-4">
          <div className="flex items-start justify-between gap-4">
            <div className="flex-1 space-y-2">
              <Skeleton className="h-4 w-40" />
              <Skeleton className="h-3 w-20" />
              <Skeleton className="h-3 w-3/4" />
            </div>
            <Skeleton className="h-6 w-20" />
          </div>
        </div>
      ))}
    </div>
  )
}

export function DetailSkeleton() {
  return (
    <div className="rounded-2xl border border-border/80 bg-surface p-6 animate-fade-in space-y-6">
      <div className="flex items-center justify-between gap-4">
        <Skeleton className="h-6 w-40" />
        <Skeleton className="h-6 w-20" />
      </div>
      <div className="grid grid-cols-2 gap-4">
        {Array.from({ length: 6 }).map((_, i) => (
          <div key={i} className="space-y-2">
            <Skeleton className="h-3 w-16" />
            <Skeleton className="h-4 w-28" />
          </div>
        ))}
      </div>
    </div>
  )
}

export function EmptyState({ message = 'Không có dữ liệu' }: { message?: string }) {
  return (
    <div className="rounded-2xl border border-dashed border-border-strong/70 bg-sidebar/45 px-5 py-8 text-center animate-fade-in">
      <p className="text-sm font-medium text-fg">Chưa có nội dung</p>
      <p className="mt-1 text-sm text-fg-subtle">{message}</p>
    </div>
  )
}
