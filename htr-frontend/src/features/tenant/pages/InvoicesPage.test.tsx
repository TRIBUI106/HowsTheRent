import type { ReactNode } from 'react'
import { describe, it, expect, vi, beforeEach } from 'vitest'
import { render, screen, fireEvent, waitFor } from '@testing-library/react'
import { MemoryRouter } from 'react-router-dom'
import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import api from '@/lib/api'
import { invoiceApi } from '@/api/invoiceApi'
import TenantInvoicesPage from './InvoicesPage'

vi.mock('@/lib/api', () => ({
  default: { get: vi.fn(), post: vi.fn() },
}))

vi.mock('@/api/invoiceApi', () => ({
  invoiceApi: { createPaymentLink: vi.fn(), requestCashPayment: vi.fn(), downloadReceiptPdf: vi.fn() },
}))

vi.mock('@/components/Layout', () => ({
  default: ({ children }: { children: ReactNode }) => children,
}))

function renderPage() {
  const client = new QueryClient()
  return render(
    <QueryClientProvider client={client}>
      <MemoryRouter><TenantInvoicesPage /></MemoryRouter>
    </QueryClientProvider>
  )
}

const baseInvoice = {
  id: 'inv-1',
  invoiceMonth: '2026-09-01',
  totalAmount: 2_500_000,
  dueDate: '2026-09-05',
  roomNumber: 'A101',
}

describe('TenantInvoicesPage', () => {
  beforeEach(() => {
    vi.mocked(api.get).mockReset()
  })

  it('shows a pay button for a PENDING invoice', async () => {
    vi.mocked(api.get).mockResolvedValue({ data: { content: [{ ...baseInvoice, status: 'PENDING' }] } })
    renderPage()

    expect(await screen.findByRole('button', { name: 'Thanh toán' })).toBeInTheDocument()
  })

  // Regression test: the action column used to check `status === 'PENDING'` only, so an
  // OVERDUE invoice (a real, distinct status — confirmed payable by the backend, which only
  // ever rejects an already-PAID invoice) silently rendered no action at all.
  it('shows an urgent pay button for an OVERDUE invoice, not a blank cell', async () => {
    vi.mocked(api.get).mockResolvedValue({ data: { content: [{ ...baseInvoice, status: 'OVERDUE' }] } })
    renderPage()

    const button = await screen.findByRole('button', { name: 'Thanh toán ngay' })
    expect(button).toBeInTheDocument()
  })

  it('shows "Đã thanh toán" with no button for a PAID invoice', async () => {
    vi.mocked(api.get).mockResolvedValue({ data: { content: [{ ...baseInvoice, status: 'PAID' }] } })
    renderPage()

    // Matches twice: the status Badge and the action-column indicator both read "Đã thanh toán".
    expect(await screen.findAllByText('Đã thanh toán')).toHaveLength(2)
    expect(screen.queryByRole('button', { name: /thanh toán/i })).not.toBeInTheDocument()
  })

  it('downloads the receipt PDF for a PAID invoice (available for any status, not just PENDING)', async () => {
    vi.mocked(api.get).mockResolvedValue({ data: { content: [{ ...baseInvoice, status: 'PAID' }] } })
    const pdfBlob = new Blob(['%PDF-fake'], { type: 'application/pdf' })
    vi.mocked(invoiceApi.downloadReceiptPdf).mockResolvedValue(pdfBlob)
    const createObjectURL = vi.fn(() => 'blob:fake-url')
    const revokeObjectURL = vi.fn()
    vi.stubGlobal('URL', { ...URL, createObjectURL, revokeObjectURL })

    renderPage()

    const downloadButton = await screen.findByRole('button', { name: 'Tải hóa đơn PDF' })
    fireEvent.click(downloadButton)

    await waitFor(() => expect(invoiceApi.downloadReceiptPdf).toHaveBeenCalledWith('inv-1'))
    expect(createObjectURL).toHaveBeenCalledWith(pdfBlob)

    vi.unstubAllGlobals()
  })
})
