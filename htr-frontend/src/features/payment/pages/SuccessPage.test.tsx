import { describe, it, expect, vi, beforeEach } from 'vitest'
import { render, screen, waitFor } from '@testing-library/react'
import { MemoryRouter, Route, Routes } from 'react-router-dom'
import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import { invoiceApi } from '@/api/invoiceApi'
import { useAuthStore } from '@/stores/authStore'
import type { Invoice } from '@/types'
import PaymentSuccessPage from './SuccessPage'

vi.mock('@/api/invoiceApi', () => ({
  invoiceApi: { downloadReceiptPdf: vi.fn(), reconcilePayment: vi.fn() },
}))

function renderAt(search: string) {
  const client = new QueryClient({ defaultOptions: { queries: { retry: false } } })
  const invalidateSpy = vi.spyOn(client, 'invalidateQueries')
  const result = render(
    <QueryClientProvider client={client}>
      <MemoryRouter initialEntries={[`/payment/success${search}`]}>
        <Routes>
          <Route path="/payment/success" element={<PaymentSuccessPage />} />
        </Routes>
      </MemoryRouter>
    </QueryClientProvider>
  )
  return { ...result, invalidateSpy }
}

describe('PaymentSuccessPage', () => {
  beforeEach(() => {
    vi.mocked(invoiceApi.downloadReceiptPdf).mockReset()
    // Default to a silent rejection so tests focused on reconciliation don't also need to stub
    // URL.createObjectURL for the unrelated download effect — SuccessPage catches this silently.
    vi.mocked(invoiceApi.downloadReceiptPdf).mockRejectedValue(new Error('not stubbed in this test'))
    vi.mocked(invoiceApi.reconcilePayment).mockReset()
    vi.mocked(invoiceApi.reconcilePayment).mockResolvedValue({ status: 'PAID' } as Invoice)
    useAuthStore.setState({ user: { id: 'u1', fullName: 'Khách A', email: 'a@example.com', role: 'TENANT', active: true } })
  })

  // Regression coverage for the "biên lai PDF" auto-download: PayOSService.createPaymentLink
  // now carries invoiceId through the return URL specifically so this page can trigger it
  // without a separate orderCode → invoice lookup.
  it('auto-downloads the receipt when invoiceId is present in the URL', async () => {
    const pdfBlob = new Blob(['%PDF-fake'], { type: 'application/pdf' })
    vi.mocked(invoiceApi.downloadReceiptPdf).mockResolvedValue(pdfBlob)
    const createObjectURL = vi.fn(() => 'blob:fake-url')
    const revokeObjectURL = vi.fn()
    vi.stubGlobal('URL', { ...URL, createObjectURL, revokeObjectURL })

    renderAt('?orderCode=123&amount=250000000&invoiceId=inv-42')

    await waitFor(() => expect(invoiceApi.downloadReceiptPdf).toHaveBeenCalledWith('inv-42'))
    expect(createObjectURL).toHaveBeenCalledWith(pdfBlob)

    vi.unstubAllGlobals()
  })

  it('does not attempt a download when invoiceId is absent from the URL', async () => {
    renderAt('?orderCode=123&amount=250000000')

    await screen.findByText('Thanh toán thành công!')
    expect(invoiceApi.downloadReceiptPdf).not.toHaveBeenCalled()
  })

  it('does not throw or interrupt the success page if the download fails', async () => {
    vi.mocked(invoiceApi.downloadReceiptPdf).mockRejectedValue(new Error('network error'))

    renderAt('?orderCode=123&amount=250000000&invoiceId=inv-42')

    expect(await screen.findByText('Thanh toán thành công!')).toBeInTheDocument()
    await waitFor(() => expect(invoiceApi.downloadReceiptPdf).toHaveBeenCalled())
  })

  // Regression coverage for the "vẫn hiện chưa thanh toán" bug: PayOS confirms payment to our
  // backend only via its async webhook, so the browser redirect back to this page carries no
  // guarantee that webhook already landed. This page must actively reconcile so the tenant
  // invoices list doesn't show stale PENDING/OVERDUE right after a successful payment.
  it('reconciles the payment and invalidates the invoices caches when invoiceId is present', async () => {
    const { invalidateSpy } = renderAt('?orderCode=123&amount=250000000&invoiceId=inv-42')

    await waitFor(() => expect(invoiceApi.reconcilePayment).toHaveBeenCalledWith('inv-42'))
    await waitFor(() => expect(invalidateSpy).toHaveBeenCalledWith({ queryKey: ['tenant-invoices'] }))
    expect(invalidateSpy).toHaveBeenCalledWith({ queryKey: ['invoices'] })
    expect(invalidateSpy).toHaveBeenCalledWith({ queryKey: ['dashboard'] })
  })

  it('does not attempt to reconcile when invoiceId is absent from the URL', async () => {
    renderAt('?orderCode=123&amount=250000000')

    await screen.findByText('Thanh toán thành công!')
    expect(invoiceApi.reconcilePayment).not.toHaveBeenCalled()
  })

  it('does not throw or interrupt the success page if reconciliation fails', async () => {
    vi.mocked(invoiceApi.reconcilePayment).mockRejectedValue(new Error('network error'))

    renderAt('?orderCode=123&amount=250000000&invoiceId=inv-42')

    expect(await screen.findByText('Thanh toán thành công!')).toBeInTheDocument()
    await waitFor(() => expect(invoiceApi.reconcilePayment).toHaveBeenCalled())
  })
})
