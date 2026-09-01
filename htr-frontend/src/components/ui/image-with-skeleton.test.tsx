import { describe, it, expect } from 'vitest'
import { render, screen, fireEvent } from '@testing-library/react'
import { ImageWithSkeleton } from './image-with-skeleton'

describe('ImageWithSkeleton', () => {
  it('shows a skeleton before the image loads, then hides it on load', () => {
    render(<ImageWithSkeleton src="https://cdn.example.com/a.jpg" alt="" />)

    expect(screen.getByTestId('image-skeleton')).toBeInTheDocument()
    const img = screen.getByAltText('')
    expect(img).toHaveClass('opacity-0')

    fireEvent.load(img)

    expect(screen.queryByTestId('image-skeleton')).not.toBeInTheDocument()
    expect(img).toHaveClass('opacity-100')
  })

  it('hides the skeleton on image error too, so it does not spin forever', () => {
    render(<ImageWithSkeleton src="https://cdn.example.com/broken.jpg" alt="" />)

    fireEvent.error(screen.getByAltText(''))

    expect(screen.queryByTestId('image-skeleton')).not.toBeInTheDocument()
  })

  it('re-shows the skeleton when the src changes', () => {
    const { rerender } = render(<ImageWithSkeleton src="https://cdn.example.com/a.jpg" alt="" />)
    fireEvent.load(screen.getByAltText(''))
    expect(screen.queryByTestId('image-skeleton')).not.toBeInTheDocument()

    rerender(<ImageWithSkeleton src="https://cdn.example.com/b.jpg" alt="" />)

    expect(screen.getByTestId('image-skeleton')).toBeInTheDocument()
  })
})
