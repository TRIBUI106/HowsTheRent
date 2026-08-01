import { describe, expect, test } from 'bun:test'

import {
  canSubmitCompletionReview,
  getImageSelectionError,
  replaceMaintenanceRequest,
} from '../src/features/tech/completionImageFlow'

describe('technician completion image flow', () => {
  test('requires server-confirmed completion images before submit review is allowed', () => {
    expect(canSubmitCompletionReview({ completionImages: [] })).toBe(false)
    expect(canSubmitCompletionReview({ completionImages: ['https://cdn.example/completed.jpg'] })).toBe(true)
  })

  test('replaces the uploaded maintenance request in the cached list', () => {
    const existing = [
      { id: 'first', title: 'First task', completionImages: [] },
      { id: 'second', title: 'Second task', completionImages: [] },
    ]
    const uploaded = {
      id: 'second',
      title: 'Second task after upload',
      completionImages: ['https://cdn.example/completed.jpg'],
    }

    expect(replaceMaintenanceRequest(existing, uploaded)).toEqual([
      existing[0],
      uploaded,
    ])
  })

  test('leaves cache unchanged when the uploaded request is not in the current list', () => {
    const existing = [{ id: 'first', completionImages: [] }]
    const uploaded = { id: 'missing', completionImages: ['https://cdn.example/completed.jpg'] }

    expect(replaceMaintenanceRequest(existing, uploaded)).toEqual(existing)
  })

  test('validates selected files are images before upload', () => {
    expect(getImageSelectionError([])).toBe('Vui lòng chọn ít nhất một ảnh hoàn thành.')
    expect(getImageSelectionError([new File(['text'], 'note.txt', { type: 'text/plain' })])).toBe(
      'Minh chứng hoàn thành chỉ chấp nhận tệp hình ảnh.',
    )
    expect(getImageSelectionError([new File(['image'], 'completion.png', { type: 'image/png' })])).toBeNull()
  })
})
