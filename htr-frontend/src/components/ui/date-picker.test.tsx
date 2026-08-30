import { describe, it, expect, vi } from 'vitest'
import { render, screen, fireEvent, within } from '@testing-library/react'
import { DatePicker } from './date-picker'

describe('DatePicker', () => {
  it('displays an ISO value as dd/mm/yyyy', () => {
    render(<DatePicker value="2026-08-15" onChange={() => {}} />)
    expect(screen.getByRole('textbox')).toHaveValue('15/08/2026')
  })

  it('renders empty when value is empty', () => {
    render(<DatePicker value="" onChange={() => {}} />)
    expect(screen.getByRole('textbox')).toHaveValue('')
  })

  it('masks typed digits and emits ISO once a full valid date is typed', () => {
    const onChange = vi.fn()
    render(<DatePicker value="" onChange={onChange} />)
    const input = screen.getByRole('textbox')

    fireEvent.change(input, { target: { value: '15082026' } })

    expect(input).toHaveValue('15/08/2026')
    expect(onChange).toHaveBeenCalledWith('2026-08-15')
  })

  it('does not emit onChange while the typed date is still incomplete', () => {
    const onChange = vi.fn()
    render(<DatePicker value="" onChange={onChange} />)

    fireEvent.change(screen.getByRole('textbox'), { target: { value: '1508' } })

    expect(input_display()).toBe('15/08')
    expect(onChange).not.toHaveBeenCalled()

    function input_display() {
      return screen.getByRole('textbox').getAttribute('value')
    }
  })

  it('does not emit onChange for an impossible calendar date', () => {
    const onChange = vi.fn()
    render(<DatePicker value="" onChange={onChange} />)

    fireEvent.change(screen.getByRole('textbox'), { target: { value: '31022026' } })

    expect(onChange).not.toHaveBeenCalled()
  })

  it('emits an empty string when the text is cleared', () => {
    const onChange = vi.fn()
    render(<DatePicker value="2026-08-15" onChange={onChange} />)

    fireEvent.change(screen.getByRole('textbox'), { target: { value: '' } })

    expect(onChange).toHaveBeenCalledWith('')
  })

  it('opens a calendar popover from the icon button and picking a day emits an ISO date', () => {
    const onChange = vi.fn()
    render(<DatePicker value="2026-08-15" onChange={onChange} />)

    fireEvent.click(screen.getByLabelText('Mở lịch chọn ngày'))
    const grid = screen.getByRole('grid')
    const dayButtons = within(grid)
      .getAllByRole('button')
      .filter(button => /^\d+$/.test(button.textContent ?? ''))
    expect(dayButtons.length).toBeGreaterThan(0)

    fireEvent.click(dayButtons[0])

    expect(onChange).toHaveBeenCalledTimes(1)
    expect(onChange.mock.calls[0][0]).toMatch(/^\d{4}-\d{2}-\d{2}$/)
    expect(screen.queryByRole('grid')).not.toBeInTheDocument()
  })

  it('closes the popover when clicking outside of it', () => {
    render(<DatePicker value="2026-08-15" onChange={() => {}} />)

    fireEvent.click(screen.getByLabelText('Mở lịch chọn ngày'))
    expect(screen.getByRole('grid')).toBeInTheDocument()

    fireEvent.mouseDown(document.body)

    expect(screen.queryByRole('grid')).not.toBeInTheDocument()
  })
})
