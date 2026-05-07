import { cn, statusColor, statusLabel } from '@/lib/utils'

interface BadgeProps {
  status: string
  className?: string
}

export function Badge({ status, className }: BadgeProps) {
  return (
    <span className={cn('inline-flex items-center rounded-full px-2.5 py-0.5 text-xs font-medium', statusColor(status), className)}>
      {statusLabel(status)}
    </span>
  )
}