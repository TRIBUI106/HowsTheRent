import api from '@/lib/api'

export interface AdminPostSummary {
  propertyId: string
  propertyName: string
  postId: string | null
  title: string | null
  slug: string | null
  published: boolean
  updatedAt: string | null
}

export interface AdminPostDetail {
  id: string
  propertyId: string
  propertyName: string
  title: string
  slug: string
  content: string | null
  coverImageUrl: string | null
  published: boolean
  publishedAt: string | null
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

export interface UpdatePostPayload {
  title: string
  slug?: string
  content?: string
  coverImageUrl?: string
}

export const adminBlogApi = {
  listAll: () => api.get<AdminPostSummary[]>('/admin/blog/posts').then(r => r.data),
  get: (propertyId: string) => api.get<AdminPostDetail>(`/admin/blog/posts/${propertyId}`).then(r => r.data),
  update: (propertyId: string, payload: UpdatePostPayload) =>
    api.put<AdminPostDetail>(`/admin/blog/posts/${propertyId}`, payload).then(r => r.data),
  generateDraft: (propertyId: string) =>
    api.post<GeneratedDraft>(`/admin/blog/posts/${propertyId}/draft`).then(r => r.data),
  uploadCoverImage: (propertyId: string, file: File) => {
    const formData = new FormData()
    formData.append('file', file)
    return api.post<AdminPostDetail>(`/admin/blog/posts/${propertyId}/cover-image`, formData).then(r => r.data)
  },
  publish: (propertyId: string) => api.post<AdminPostDetail>(`/admin/blog/posts/${propertyId}/publish`).then(r => r.data),
  unpublish: (propertyId: string) => api.post<AdminPostDetail>(`/admin/blog/posts/${propertyId}/unpublish`).then(r => r.data),
  listComments: () => api.get<AdminPostComment[]>('/admin/blog/comments').then(r => r.data),
  deleteComment: (id: string) => api.delete(`/admin/blog/comments/${id}`).then(r => r.data),
}
