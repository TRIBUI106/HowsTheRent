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
    EMPTY: 'bg-gray-100 text-gray-700',
    RENTED: 'bg-green-100 text-green-700',
    MAINTENANCE: 'bg-yellow-100 text-yellow-700',
    PENDING: 'bg-blue-100 text-blue-700',
    PAID: 'bg-green-100 text-green-700',
    OVERDUE: 'bg-red-100 text-red-700',
    OPEN: 'bg-orange-100 text-orange-700',
    IN_PROGRESS: 'bg-blue-100 text-blue-700',
    DONE: 'bg-green-100 text-green-700',
    ACTIVE: 'bg-green-100 text-green-700',
    TERMINATED: 'bg-gray-100 text-gray-700',
    EXPIRED: 'bg-gray-100 text-gray-700',
  }
  return map[status] || 'bg-gray-100 text-gray-700'
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
    TERMINATED: 'Đã kết thúc',
    EXPIRED: 'Hết hạn',
  }
  return map[status] || status
}