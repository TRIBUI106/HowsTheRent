import { clsx, type ClassValue } from 'clsx'
import { twMerge } from 'tailwind-merge'

export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs))
}

export function formatCurrency(amount: number): string {
  return new Intl.NumberFormat('vi-VN', { style: 'currency', currency: 'VND' }).format(amount)
}

export function formatDate(dateStr: string): string {
  return new Date(dateStr).toLocaleDateString('vi-VN')
}

export function statusColor(status: string): string {
  const map: Record<string, string> = {
    EMPTY:       'bg-badge-neutral    text-badge-neutral-text',
    RENTED:      'bg-badge-green      text-badge-green-text',
    MAINTENANCE: 'bg-badge-amber      text-badge-amber-text',
    PENDING:     'bg-badge-blue       text-badge-blue-text',
    PAID:        'bg-badge-green      text-badge-green-text',
    OVERDUE:     'bg-badge-red        text-badge-red-text',
    OPEN:        'bg-badge-orange     text-badge-orange-text',
    IN_PROGRESS: 'bg-badge-blue       text-badge-blue-text',
    DONE:        'bg-badge-green      text-badge-green-text',
    ACTIVE:      'bg-badge-green      text-badge-green-text',
    INACTIVE:    'bg-badge-neutral    text-badge-neutral-text',
    TERMINATED:  'bg-badge-neutral    text-badge-neutral-text',
    EXPIRED:     'bg-badge-neutral    text-badge-neutral-text',
  }
  return map[status] || 'bg-badge-neutral text-badge-neutral-text'
}

export function statusLabel(status: string): string {
  const map: Record<string, string> = {
    EMPTY: 'Trống',
    RENTED: 'Đã thuê',
    MAINTENANCE: 'Bảo trì',
    PENDING: 'Chờ thanh toán',
    PAID: 'Đã thanh toán',
    OVERDUE: 'Quá hạn',
    OPEN: 'Mới',
    IN_PROGRESS: 'Đang xử lý',
    DONE: 'Hoàn thành',
    ACTIVE: 'Hoạt động',
    INACTIVE: 'Không hoạt động',
    TERMINATED: 'Đã kết thúc',
    EXPIRED: 'Hết hạn',
  }
  return map[status] || status
}