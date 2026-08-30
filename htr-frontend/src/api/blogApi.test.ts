import { describe, it, expect, vi, beforeEach } from 'vitest'
import api from '@/lib/api'
import { blogApi } from './blogApi'

vi.mock('@/lib/api', () => ({
  default: { get: vi.fn(), post: vi.fn(), delete: vi.fn() },
}))

describe('blogApi', () => {
  beforeEach(() => {
    vi.mocked(api.get).mockReset()
    vi.mocked(api.post).mockReset()
    vi.mocked(api.delete).mockReset()
  })

  it('list() calls GET /public/blog/posts', async () => {
    vi.mocked(api.get).mockResolvedValue({ data: [] })
    await blogApi.list()
    expect(api.get).toHaveBeenCalledWith('/public/blog/posts')
  })

  it('getBySlug() calls GET /public/blog/posts/:slug', async () => {
    vi.mocked(api.get).mockResolvedValue({ data: {} })
    await blogApi.getBySlug('phong-tro-dep')
    expect(api.get).toHaveBeenCalledWith('/public/blog/posts/phong-tro-dep')
  })

  it('addComment() posts content to the comments endpoint', async () => {
    vi.mocked(api.post).mockResolvedValue({ data: {} })
    await blogApi.addComment('phong-tro-dep', 'Rất đẹp')
    expect(api.post).toHaveBeenCalledWith('/public/blog/posts/phong-tro-dep/comments', { content: 'Rất đẹp' })
  })

  it('like() posts to the like endpoint', async () => {
    vi.mocked(api.post).mockResolvedValue({ data: {} })
    await blogApi.like('phong-tro-dep')
    expect(api.post).toHaveBeenCalledWith('/public/blog/posts/phong-tro-dep/like')
  })

  it('unlike() deletes the like endpoint', async () => {
    vi.mocked(api.delete).mockResolvedValue({ data: {} })
    await blogApi.unlike('phong-tro-dep')
    expect(api.delete).toHaveBeenCalledWith('/public/blog/posts/phong-tro-dep/like')
  })

  it('getVacancy() calls GET /public/properties/:id/vacancy', async () => {
    vi.mocked(api.get).mockResolvedValue({ data: {} })
    await blogApi.getVacancy('prop-1')
    expect(api.get).toHaveBeenCalledWith('/public/properties/prop-1/vacancy')
  })

  it('registerGuest() posts registration fields', async () => {
    vi.mocked(api.post).mockResolvedValue({ data: {} })
    await blogApi.registerGuest({ fullName: 'Khách A', email: 'a@example.com', password: 'Password1!' })
    expect(api.post).toHaveBeenCalledWith('/auth/register-guest', { fullName: 'Khách A', email: 'a@example.com', password: 'Password1!' })
  })
})
