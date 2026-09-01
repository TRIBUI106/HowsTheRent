import api from '@/lib/api'
import type { User } from '@/types'

export interface BlogPostSummary {
  id: string
  slug: string
  title: string
  coverImageUrl: string | null
  roomId: string
  roomNumber: string
  roomStatus: 'EMPTY' | 'RENTED' | 'MAINTENANCE'
  propertyId: string
  propertyName: string
  propertyAddress: string
  publishedAt: string | null
  tags: string[]
}

export interface BlogPostDetail {
  id: string
  slug: string
  title: string
  content: string
  coverImageUrl: string | null
  roomId: string
  roomNumber: string
  roomStatus: 'EMPTY' | 'RENTED' | 'MAINTENANCE'
  roomDirection: import('@/types').RoomDirection | null
  roomAreaM2: number | null
  roomMaxPeople: number | null
  roomImages: string[]
  propertyId: string
  propertyName: string
  propertyAddress: string
  publishedAt: string | null
  likeCount: number
  liked: boolean
  tags: string[]
}

export interface Vacancy {
  emptyCount: number
  rentedCount: number
  totalCount: number
}

export interface PostComment {
  id: string
  content: string
  userId: string
  userName: string
  createdAt: string
}

export interface LikeStatus {
  liked: boolean
  likeCount: number
}

export interface RegisterGuestPayload {
  fullName: string
  email: string
  password: string
  phone?: string
}

export interface AuthResult {
  accessToken: string
  refreshToken: string
  user: User
}

export const blogApi = {
  list: () => api.get<BlogPostSummary[]>('/public/blog/posts').then(r => r.data),
  getBySlug: (slug: string) => api.get<BlogPostDetail>(`/public/blog/posts/${slug}`).then(r => r.data),
  listComments: (slug: string) => api.get<PostComment[]>(`/public/blog/posts/${slug}/comments`).then(r => r.data),
  addComment: (slug: string, content: string) =>
    api.post<PostComment>(`/public/blog/posts/${slug}/comments`, { content }).then(r => r.data),
  like: (slug: string) => api.post<LikeStatus>(`/public/blog/posts/${slug}/like`).then(r => r.data),
  unlike: (slug: string) => api.delete<LikeStatus>(`/public/blog/posts/${slug}/like`).then(r => r.data),
  getVacancy: (propertyId: string) => api.get<Vacancy>(`/public/properties/${propertyId}/vacancy`).then(r => r.data),
  registerGuest: (payload: RegisterGuestPayload) =>
    api.post<AuthResult>('/auth/register-guest', payload).then(r => r.data),
}
