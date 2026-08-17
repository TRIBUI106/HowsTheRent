import { describe, expect, it, vi } from 'vitest'

import {
  buildAdminMaintenanceCreatePayload,
  getAdminMaintenanceFormError,
  submitAdminMaintenanceRequest,
  type AdminMaintenanceCreateForm,
} from './adminMaintenanceCreateForm'

function validForm(overrides: Partial<AdminMaintenanceCreateForm> = {}): AdminMaintenanceCreateForm {
  return {
    roomId: 'room-1',
    title: 'Điều hòa không lạnh',
    description: 'Điều hòa phòng 101 không lạnh từ sáng nay',
    priority: 'NORMAL',
    category: 'AIR_CONDITIONER',
    ...overrides,
  }
}

describe('admin maintenance create form', () => {
  it('requires a room to be selected', () => {
    expect(getAdminMaintenanceFormError(validForm({ roomId: '' }))).toBe(
      'Vui lòng chọn phòng để tạo yêu cầu bảo trì hộ khách thuê',
    )
  })

  it('requires a non-blank title', () => {
    expect(getAdminMaintenanceFormError(validForm({ title: '   ' }))).toBe(
      'Vui lòng nhập tiêu đề yêu cầu bảo trì',
    )
  })

  it('requires a description of at least 10 characters', () => {
    expect(getAdminMaintenanceFormError(validForm({ description: 'quá ngắn' }))).toBe(
      'Mô tả yêu cầu bảo trì tối thiểu 10 ký tự',
    )
  })

  it('passes validation when every field is filled in', () => {
    expect(getAdminMaintenanceFormError(validForm())).toBeNull()
  })

  it('builds the create payload with trimmed title/description', () => {
    const form = validForm({ title: '  Điều hòa hỏng  ', description: '  Không lạnh từ sáng nay, cần kiểm tra gấp  ' })

    expect(buildAdminMaintenanceCreatePayload(form)).toEqual({
      roomId: 'room-1',
      title: 'Điều hòa hỏng',
      description: 'Không lạnh từ sáng nay, cần kiểm tra gấp',
      priority: 'NORMAL',
      category: 'AIR_CONDITIONER',
    })
  })

  it('submits with a selected room by calling the create function with the expected payload', async () => {
    const createFn = vi.fn().mockResolvedValue({ id: 'ticket-1' })

    const result = await submitAdminMaintenanceRequest(validForm(), createFn)

    expect(result).toEqual({ ok: true })
    expect(createFn).toHaveBeenCalledTimes(1)
    expect(createFn).toHaveBeenCalledWith({
      roomId: 'room-1',
      title: 'Điều hòa không lạnh',
      description: 'Điều hòa phòng 101 không lạnh từ sáng nay',
      priority: 'NORMAL',
      category: 'AIR_CONDITIONER',
    })
  })

  it('returns validation feedback and never calls the API when room is not selected', async () => {
    const createFn = vi.fn()

    const result = await submitAdminMaintenanceRequest(validForm({ roomId: '' }), createFn)

    expect(result).toEqual({ ok: false, error: 'Vui lòng chọn phòng để tạo yêu cầu bảo trì hộ khách thuê' })
    expect(createFn).not.toHaveBeenCalled()
  })

  it('surfaces the server error message when the API call fails (e.g. room without active contract)', async () => {
    const createFn = vi.fn().mockRejectedValue({
      response: { data: { message: 'Phòng này chưa có hợp đồng đang hoạt động, không thể tạo yêu cầu bảo trì hộ khách thuê' } },
    })

    const result = await submitAdminMaintenanceRequest(validForm(), createFn)

    expect(result).toEqual({
      ok: false,
      error: 'Phòng này chưa có hợp đồng đang hoạt động, không thể tạo yêu cầu bảo trì hộ khách thuê',
    })
  })

  it('falls back to a generic error message when the API failure has no message', async () => {
    const createFn = vi.fn().mockRejectedValue(new Error('network down'))

    const result = await submitAdminMaintenanceRequest(validForm(), createFn)

    expect(result).toEqual({ ok: false, error: 'Không thể tạo yêu cầu bảo trì hộ khách thuê' })
  })
})
