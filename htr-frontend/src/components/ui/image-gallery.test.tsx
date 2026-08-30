import { describe, it, expect, vi } from 'vitest'
import { render, screen, fireEvent } from '@testing-library/react'
import { ImageGallery } from './image-gallery'

describe('ImageGallery', () => {
  it('shows the empty label when there are no images', () => {
    render(<ImageGallery images={[]} onUpload={() => {}} onDelete={() => {}} />)
    expect(screen.getByText('Chưa có hình ảnh nào.')).toBeInTheDocument()
  })

  it('renders one thumbnail per image', () => {
    render(
      <ImageGallery
        images={['https://cdn.example.com/a.jpg', 'https://cdn.example.com/b.jpg']}
        onUpload={() => {}}
        onDelete={() => {}}
      />
    )
    expect(screen.getAllByAltText('Hình phòng')).toHaveLength(2)
  })

  it('calls onUpload with the selected files', () => {
    const onUpload = vi.fn()
    render(<ImageGallery images={[]} onUpload={onUpload} onDelete={() => {}} />)

    const file = new File(['data'], 'room.jpg', { type: 'image/jpeg' })
    const input = document.querySelector('input[type="file"]') as HTMLInputElement
    fireEvent.change(input, { target: { files: [file] } })

    expect(onUpload).toHaveBeenCalledWith([file])
  })

  it('asks for confirmation before deleting, then calls onDelete with the image url', () => {
    const onDelete = vi.fn()
    render(
      <ImageGallery images={['https://cdn.example.com/a.jpg']} onUpload={() => {}} onDelete={onDelete} />
    )

    fireEvent.click(screen.getByLabelText('Xóa ảnh'))
    expect(screen.getByText('Xóa ảnh này?')).toBeInTheDocument()
    expect(onDelete).not.toHaveBeenCalled()

    fireEvent.click(screen.getByText('Xác nhận xóa'))
    expect(onDelete).toHaveBeenCalledWith('https://cdn.example.com/a.jpg')
    expect(screen.queryByText('Xóa ảnh này?')).not.toBeInTheDocument()
  })

  it('cancels deletion without calling onDelete', () => {
    const onDelete = vi.fn()
    render(
      <ImageGallery images={['https://cdn.example.com/a.jpg']} onUpload={() => {}} onDelete={onDelete} />
    )

    fireEvent.click(screen.getByLabelText('Xóa ảnh'))
    fireEvent.click(screen.getByText('Hủy'))

    expect(onDelete).not.toHaveBeenCalled()
    expect(screen.queryByText('Xóa ảnh này?')).not.toBeInTheDocument()
  })

  it('disables the delete button for the image currently being deleted', () => {
    render(
      <ImageGallery
        images={['https://cdn.example.com/a.jpg']}
        onUpload={() => {}}
        onDelete={() => {}}
        deletingUrl="https://cdn.example.com/a.jpg"
      />
    )
    expect(screen.getByLabelText('Xóa ảnh')).toBeDisabled()
  })
})
