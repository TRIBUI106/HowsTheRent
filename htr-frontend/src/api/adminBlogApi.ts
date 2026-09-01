import api from '@/lib/api'

export interface AdminPostSummary {
  postId: string
  roomId: string
  roomNumber: string
  propertyId: string
  propertyName: string
  title: string
  slug: string
  published: boolean
  likeCount: number
  updatedAt: string | null
  publishAt?: string | null
}

export interface AdminPostDetail {
  id: string
  roomId: string
  roomNumber: string
  propertyId: string
  propertyName: string
  title: string
  slug: string
  content: string | null
  coverImageUrl: string | null
  published: boolean
  publishedAt: string | null
  publishAt?: string | null
  authorId: string | null
  authorName: string | null
  createdAt: string
  updatedAt: string
}

export interface GeneratedDraft {
  title: string
  content: string
  coverImageUrl: string | null
}

export interface AdminPostComment {
  id: string
  content: string
  userId: string
  userName: string
  postId: string
  postTitle: string
  postSlug: string
  createdAt: string
}

export interface CreatePostPayload {
  roomId: string
  title: string
  slug?: string
  content?: string
  coverImageUrl?: string
  publishAt?: string | null
}

export interface UpdatePostPayload {
  title: string
  slug?: string
  content?: string
  coverImageUrl?: string
  publishAt?: string | null
}

export const adminBlogApi = {
  listAll: () => api.get<AdminPostSummary[]>('/admin/blog/posts').then(r => r.data),
  get: (postId: string) => api.get<AdminPostDetail>(`/admin/blog/posts/${postId}`).then(r => r.data),
  create: (payload: CreatePostPayload) =>
    api.post<AdminPostDetail>('/admin/blog/posts', payload).then(r => r.data),
  update: (postId: string, payload: UpdatePostPayload) =>
    api.put<AdminPostDetail>(`/admin/blog/posts/${postId}`, payload).then(r => r.data),
  delete: (postId: string) => api.delete(`/admin/blog/posts/${postId}`).then(r => r.data),
  generateDraft: (roomId: string) =>
    api.post<GeneratedDraft>(`/admin/blog/rooms/${roomId}/draft`).then(r => r.data),
  uploadCoverImage: (postId: string, file: File) => {
    const formData = new FormData()
    formData.append('file', file)
    return api.post<AdminPostDetail>(`/admin/blog/posts/${postId}/cover-image`, formData).then(r => r.data)
  },
  publish: (postId: string) => api.post<AdminPostDetail>(`/admin/blog/posts/${postId}/publish`).then(r => r.data),
  unpublish: (postId: string) => api.post<AdminPostDetail>(`/admin/blog/posts/${postId}/unpublish`).then(r => r.data),
  listComments: () => api.get<AdminPostComment[]>('/admin/blog/comments').then(r => r.data),
  deleteComment: (id: string) => api.delete(`/admin/blog/comments/${id}`).then(r => r.data),
}
