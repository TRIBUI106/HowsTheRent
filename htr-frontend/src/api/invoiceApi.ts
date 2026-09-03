import api from "@/lib/api";
import type { Invoice } from "@/types";

export const invoiceApi = {
  listAll: () => api.get<Invoice[]>("/invoices").then((r) => r.data),
  listMine: () => api.get<Invoice[]>("/invoices/mine").then((r) => r.data),
  getById: (id: string) =>
    api.get<Invoice>(`/invoices/${id}`).then((r) => r.data),
  generateAll: (year: number, month: number) =>
    api
      .post<{
        message: string;
      }>("/invoices/generate", null, { params: { year, month } })
      .then((r) => r.data),
  markPaidCash: (id: string) =>
    api.post<Invoice>(`/invoices/${id}/pay-cash`).then((r) => r.data),
  requestCashPayment: (id: string) =>
    api.post<Invoice>(`/invoices/${id}/request-cash`).then((r) => r.data),
  createPaymentLink: (id: string) =>
    api
      .post<{ checkoutUrl: string }>(`/invoices/${id}/pay-online`)
      .then((r) => r.data),
  // Available for any invoice status, not just PAID — a plain bill before paying, a receipt after.
  downloadReceiptPdf: (id: string) =>
    api
      .get(`/invoices/${id}/pdf`, { responseType: "blob" })
      .then((r) => r.data as Blob),
};
