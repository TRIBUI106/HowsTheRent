type RequestWithCompletionImages = {
  id?: string
  completionImages?: string[]
}

export function canSubmitCompletionReview(request: Pick<RequestWithCompletionImages, 'completionImages'> | null | undefined) {
  return Boolean(request?.completionImages?.length)
}

export function replaceMaintenanceRequest<T extends RequestWithCompletionImages>(
  requests: T[] | undefined,
  uploadedRequest: T,
) {
  if (!requests) return requests

  let replaced = false
  const nextRequests = requests.map((request) => {
    if (request.id !== uploadedRequest.id) return request
    replaced = true
    return uploadedRequest
  })

  return replaced ? nextRequests : requests
}

export function getImageSelectionError(files: File[]) {
  if (files.length === 0) {
    return 'Vui lòng chọn ít nhất một ảnh hoàn thành.'
  }

  if (files.some((file) => !file.type.startsWith('image/'))) {
    return 'Minh chứng hoàn thành chỉ chấp nhận tệp hình ảnh.'
  }

  return null
}
