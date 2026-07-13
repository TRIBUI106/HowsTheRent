import React from 'react'
import { cn, statusColor, statusLabel } from '@/lib/utils'

interface BadgeProps {
  status?: string
  variant?: string
  className?: string
  children?: React.ReactNode
}

export function Badge({ status, className, children }: BadgeProps) {
  if (children !== undefined && children !== null) {
    return (
      <span className={cn('inline-flex items-center rounded-full px-2.5 py-0.5 text-xs font-medium', className)}>
        {children}
      </span>
    )
  }
  return (
    <span className={cn('inline-flex items-center rounded-full px-2.5 py-0.5 text-xs font-medium', status && statusColor(status), className)}>
      {status ? statusLabel(status) : ''}
    </span>
  )
}