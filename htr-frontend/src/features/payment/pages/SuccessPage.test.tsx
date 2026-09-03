import { describe, it, expect, vi, beforeEach } from 'vitest'
import { render, screen, waitFor } from '@testing-library/react'
import { MemoryRouter, Route, Routes } from 'react-router-dom'
import { invoiceApi } from '@/api/invoiceApi'
import { useAuthStore } from '@/stores/authStore'
import PaymentSuccessPage from './SuccessPage'

vi.mock('@/api/invoiceApi', () => ({
  invoiceApi: { downloadReceiptPdf: vi.fn() },
}))

function renderAt(search: string) {
  return render(
    <MemoryRouter initialEntries={[`/payment/success${search}`]}>
      <Routes>
        <Route path="/payment/success" element={<PaymentSuccessPage />} />
      </Routes>
    </MemoryRouter>
  )
}

describe('PaymentSuccessPage', () => {
  beforeEach(() => {
    vi.mocked(invoiceApi.downloadReceiptPdf).mockReset()
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
})
