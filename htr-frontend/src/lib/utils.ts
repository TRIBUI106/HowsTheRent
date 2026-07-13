import { clsx, type ClassValue } from 'clsx'
import { twMerge } from 'tailwind-merge'

export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs))
}

export function formatCurrency(amount: number): string {
  return new Intl.NumberFormat('vi-VN', {
    style: 'currency',
    currency: 'VND',
    maximumFractionDigits: 0,
  }).format(amount)
}

export function formatCurrencyInput(value: string | number | null | undefined): string {
  const digits = String(value ?? '').replace(/\D/g, '')
  if (!digits) return ''
  return new Intl.NumberFormat('vi-VN', { maximumFractionDigits: 0 }).format(Number(digits))
}

export function parseCurrencyInput(value: string | number | null | undefined): number {
  const digits = String(value ?? '').replace(/\D/g, '')
  return digits ? Number(digits) : 0
}

export function formatDateInput(value: string | null | undefined): string {
  const digits = String(value ?? '').replace(/\D/g, '').slice(0, 8)
  if (digits.length <= 2) return digits
  if (digits.length <= 4) return `${digits.slice(0, 2)}/${digits.slice(2)}`
  return `${digits.slice(0, 2)}/${digits.slice(2, 4)}/${digits.slice(4)}`
}

export function parseDateInput(value: string | null | undefined): string {
  const match = /^(\d{2})\/(\d{2})\/(\d{4})$/.exec(String(value ?? ''))
  if (!match) return ''

  const [, day, month, year] = match
  const parsed = new Date(Number(year), Number(month) - 1, Number(day))
  if (
    parsed.getFullYear() !== Number(year) ||
    parsed.getMonth() !== Number(month) - 1 ||
    parsed.getDate() !== Number(day)
  ) {
    return ''
  }

  return `${year}-${month}-${day}`
}

export function formatDate(dateStr?: string | null): string {
  if (!dateStr) return '-'
  const datePart = dateStr.slice(0, 10)
  const match = /^(\d{4})-(\d{2})-(\d{2})$/.exec(datePart)
  if (match) {
    return `${match[3]}/${match[2]}/${match[1]}`
  }

  const date = new Date(dateStr)
  if (Number.isNaN(date.getTime())) return '-'
  return new Intl.DateTimeFormat('vi-VN', {
    day: '2-digit',
    month: '2-digit',
    year: 'numeric',
  }).format(date)
}

export function formatMonth(dateStr?: string | null): string {
  if (!dateStr) return '-'
  const datePart = dateStr.slice(0, 10)
  const match = /^(\d{4})-(\d{2})/.exec(datePart)
  if (match) {
    return `${match[2]}/${match[1]}`
  }

  const date = new Date(dateStr)
  if (Number.isNaN(date.getTime())) return '-'
  return new Intl.DateTimeFormat('vi-VN', {
    month: '2-digit',
    year: 'numeric',
  }).format(date)
}

export function statusColor(status: string): string {
  const map: Record<string, string> = {
    EMPTY: 'bg-badge-neutral text-badge-neutral-text',
    RENTED: 'bg-badge-green text-badge-green-text',
    MAINTENANCE: 'bg-badge-amber text-badge-amber-text',
    PENDING: 'bg-badge-blue text-badge-blue-text',
    PAID: 'bg-badge-green text-badge-green-text',
    OVERDUE: 'bg-badge-red text-badge-red-text',
    OPEN: 'bg-badge-orange text-badge-orange-text',
    ASSIGNED: 'bg-badge-blue text-badge-blue-text',
    IN_PROGRESS: 'bg-badge-blue text-badge-blue-text',
    PENDING_PAYMENT: 'bg-badge-amber text-badge-amber-text',
    PENDING_REVIEW: 'bg-badge-blue text-badge-blue-text',
    COMPLETED: 'bg-badge-green text-badge-green-text',
    DONE: 'bg-badge-green text-badge-green-text',
    CANCELLED: 'bg-badge-neutral text-badge-neutral-text',
    ACTIVE: 'bg-badge-green text-badge-green-text',
    INACTIVE: 'bg-badge-neutral text-badge-neutral-text',
    TERMINATED: 'bg-badge-neutral text-badge-neutral-text',
    EXPIRED: 'bg-badge-neutral text-badge-neutral-text',
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
    ASSIGNED: 'Đã phân công',
    IN_PROGRESS: 'Đang xử lý',
    PENDING_PAYMENT: 'Chờ thanh toán vật tư',
    PENDING_REVIEW: 'Chờ nghiệm thu',
    COMPLETED: 'Hoàn thành',
    DONE: 'Hoàn thành',
    CANCELLED: 'Đã hủy',
    ACTIVE: 'Hoạt động',
    INACTIVE: 'Không hoạt động',
    TERMINATED: 'Đã kết thúc',
    EXPIRED: 'Hết hạn',
  }
  return map[status] || status
}

export function priorityColor(priority?: string): string {
  const map: Record<string, string> = {
    NORMAL: 'bg-badge-neutral text-badge-neutral-text',
    HIGH: 'bg-badge-amber text-badge-amber-text',
    URGENT: 'bg-badge-red text-badge-red-text',
  }
  return map[priority ?? 'NORMAL'] || 'bg-badge-neutral text-badge-neutral-text'
}

export function priorityLabel(priority?: string): string {
  const map: Record<string, string> = {
    NORMAL: 'Bình thường',
    HIGH: 'Cao',
    URGENT: 'Khẩn cấp',
  }
  return map[priority ?? 'NORMAL'] || 'Bình thường'
}

export function categoryLabel(category?: string): string {
  const map: Record<string, string> = {
    ELECTRIC: 'Điện',
    PLUMBING: 'Nước / Đường ống',
    AIR_CONDITIONER: 'Điều hòa',
    FURNITURE: 'Nội thất',
    OTHER: 'Khác',
  }
  return map[category ?? 'OTHER'] || 'Khác'
}
