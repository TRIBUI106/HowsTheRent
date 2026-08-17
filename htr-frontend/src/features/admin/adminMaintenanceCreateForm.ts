import { getErrorMessage } from '../../lib/apiError'

export interface AdminMaintenanceCreateForm {
  roomId: string
  title: string
  description: string
  priority: string
  category: string
}

/**
 * Validates the admin "create maintenance request on behalf of a tenant" form.
 * Mirrors the backend's own checks (room required for admin-created tickets,
 * description minimum length) so the user gets instant feedback before the
 * request round-trips to the server.
 */
export function getAdminMaintenanceFormError(form: AdminMaintenanceCreateForm): string | null {
  if (!form.roomId) {
    return 'Vui lòng chọn phòng để tạo yêu cầu bảo trì hộ khách thuê'
  }
  if (!form.title.trim()) {
    return 'Vui lòng nhập tiêu đề yêu cầu bảo trì'
  }
  if (form.description.trim().length < 10) {
    return 'Mô tả yêu cầu bảo trì tối thiểu 10 ký tự'
  }
  return null
}

export function buildAdminMaintenanceCreatePayload(form: AdminMaintenanceCreateForm) {
  return {
    roomId: form.roomId,
    title: form.title.trim(),
    description: form.description.trim(),
    priority: form.priority,
    category: form.category,
  }
}

export type AdminMaintenanceCreatePayload = ReturnType<typeof buildAdminMaintenanceCreatePayload>
export type AdminMaintenanceSubmitResult = { ok: true } | { ok: false; error: string }

/**
 * Validates then submits the admin creation form via the given create function
 * (typically `maintenanceApi.create`). Kept separate from the React component so
 * both the validation-only and the API-failure paths are unit-testable without
 * a DOM.
 */
export async function submitAdminMaintenanceRequest(
  form: AdminMaintenanceCreateForm,
  createFn: (payload: AdminMaintenanceCreatePayload) => Promise<unknown>,
): Promise<AdminMaintenanceSubmitResult> {
  const validationError = getAdminMaintenanceFormError(form)
  if (validationError) {
    return { ok: false, error: validationError }
  }

  try {
    await createFn(buildAdminMaintenanceCreatePayload(form))
    return { ok: true }
  } catch (error) {
    return { ok: false, error: getErrorMessage(error, 'Không thể tạo yêu cầu bảo trì hộ khách thuê') }
  }
}
