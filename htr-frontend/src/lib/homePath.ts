import type { User } from '@/types'

export function homePathForRole(role: User['role']): string {
  switch (role) {
    case 'ADMIN':
    case 'PLATFORM_ADMIN':
    case 'LANDLORD_ADMIN':
      return '/admin'
    case 'TENANT':
      return '/tenant'
    case 'GUEST':
      return '/blog'
    default:
      return '/tech'
  }
}
