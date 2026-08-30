import { useEffect, useRef, useState } from 'react'
import { createPortal } from 'react-dom'
import { DayPicker } from 'react-day-picker'
import { vi } from 'react-day-picker/locale'
import { CalendarDays } from 'lucide-react'
import { cn, formatDateInput, parseDateInput } from '@/lib/utils'
import 'react-day-picker/style.css'

interface DatePickerProps {
  label?: string
  error?: string
  hint?: string
  placeholder?: string
  required?: boolean
  /** ISO yyyy-mm-dd, or '' when empty */
  value: string
  /** Receives ISO yyyy-mm-dd, or '' when cleared/invalid */
  onChange: (isoValue: string) => void
  className?: string
  id?: string
}

function isoToDisplay(iso: string): string {
  const match = /^(\d{4})-(\d{2})-(\d{2})$/.exec(iso)
  if (!match) return ''
  const [, year, month, day] = match
  return `${day}/${month}/${year}`
}

function isoToDate(iso: string): Date | undefined {
  const match = /^(\d{4})-(\d{2})-(\d{2})$/.exec(iso)
  if (!match) return undefined
  const [, year, month, day] = match
  return new Date(Number(year), Number(month) - 1, Number(day))
}

function dateToIso(date: Date): string {
  const year = date.getFullYear()
  const month = String(date.getMonth() + 1).padStart(2, '0')
  const day = String(date.getDate()).padStart(2, '0')
  return `${year}-${month}-${day}`
}

export function DatePicker({
  label,
  error,
  hint,
  placeholder = 'dd/mm/yyyy',
  required,
  value,
  onChange,
  className,
  id,
}: DatePickerProps) {
  const [text, setText] = useState(() => isoToDisplay(value))
  const [open, setOpen] = useState(false)
  const [popoverStyle, setPopoverStyle] = useState<{ top: number; left: number }>({ top: 0, left: 0 })
  const wrapperRef = useRef<HTMLDivElement>(null)
  const popoverRef = useRef<HTMLDivElement>(null)
  const inputId = id ?? label?.toLowerCase().replace(/\s+/g, '-')

  // Keep the typed text in sync when the value changes from outside (e.g. form reset).
  useEffect(() => {
    setText(isoToDisplay(value))
  }, [value])

  useEffect(() => {
    if (!open) return

    function handlePointerDown(e: MouseEvent) {
      const target = e.target as Node
      if (wrapperRef.current?.contains(target) || popoverRef.current?.contains(target)) return
      setOpen(false)
    }
    function handleKeyDown(e: KeyboardEvent) {
      if (e.key === 'Escape') setOpen(false)
    }

    document.addEventListener('mousedown', handlePointerDown)
    document.addEventListener('keydown', handleKeyDown)
    return () => {
      document.removeEventListener('mousedown', handlePointerDown)
      document.removeEventListener('keydown', handleKeyDown)
    }
  }, [open])

  function openPopover() {
    const rect = wrapperRef.current?.getBoundingClientRect()
    if (rect) {
      setPopoverStyle({ top: rect.bottom + window.scrollY + 4, left: rect.left + window.scrollX })
    }
    setOpen(true)
  }

  function handleTextChange(raw: string) {
    const masked = formatDateInput(raw)
    setText(masked)
    const iso = parseDateInput(masked)
    if (iso) onChange(iso)
    else if (masked === '') onChange('')
  }

  function handleSelect(date: Date | undefined) {
    if (!date) return
    const iso = dateToIso(date)
    setText(isoToDisplay(iso))
    onChange(iso)
    setOpen(false)
  }

  return (
    <div className="space-y-1" ref={wrapperRef}>
      {label && (
        <label htmlFor={inputId} className="block text-sm font-medium text-fg">
          {label}
          {required && <span className="text-error ml-1" aria-hidden="true">*</span>}
        </label>
      )}
      <div className="relative">
        <input
          id={inputId}
          type="text"
          inputMode="numeric"
          placeholder={placeholder}
          required={required}
          value={text}
          onChange={e => handleTextChange(e.target.value)}
          onFocus={openPopover}
          className={cn(
            'w-full rounded-lg border px-3 py-2 pr-10 text-sm bg-surface text-fg',
            'placeholder:text-fg-subtle transition-colors duration-100',
            'focus:outline-none focus:ring-2 focus:ring-accent/20 focus:border-accent',
            error ? 'border-error-border focus:ring-error/20 focus:border-error' : 'border-border',
            className
          )}
        />
        <button
          type="button"
          tabIndex={-1}
          onClick={() => (open ? setOpen(false) : openPopover())}
          aria-label="Mở lịch chọn ngày"
          className="absolute right-3 top-1/2 -translate-y-1/2 text-fg-subtle hover:text-fg-muted transition-colors"
        >
          <CalendarDays size={16} />
        </button>
      </div>
      {error && <p className="text-xs text-error" role="alert">{error}</p>}
      {hint && !error && <p className="text-xs text-fg-subtle">{hint}</p>}

      {open &&
        createPortal(
          <div
            ref={popoverRef}
            style={{ position: 'absolute', top: popoverStyle.top, left: popoverStyle.left }}
            className="z-50 rounded-xl border border-border bg-surface p-2 shadow-xl"
          >
            <DayPicker
              mode="single"
              locale={vi}
              weekStartsOn={1}
              selected={isoToDate(value)}
              defaultMonth={isoToDate(value) ?? new Date()}
              onSelect={handleSelect}
            />
          </div>,
          document.body,
        )}
    </div>
  )
}
