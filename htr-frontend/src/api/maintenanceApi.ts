import api from "@/lib/api";
import { extractPageContent, normalizeMaintenanceRequest } from "@/lib/apiMappers";
import type { MaintenanceRequest, Page } from "@/types";

export const maintenanceApi = {
  listAll: () =>
    api
      .get<Page<MaintenanceRequest>>("/maintenance")
      .then((r) => extractPageContent(r.data).map(normalizeMaintenanceRequest)),
  listMine: () =>
    api
      .get<Page<MaintenanceRequest>>("/maintenance/mine")
      .then((r) => extractPageContent(r.data).map(normalizeMaintenanceRequest)),
  listAssigned: () =>
    api
      .get<MaintenanceRequest[]>("/maintenance/assigned")
      .then((r) => (r.data ?? []).map(normalizeMaintenanceRequest)),
  getById: (id: string) =>
    api.get<MaintenanceRequest>(`/maintenance/${id}`).then((r) => normalizeMaintenanceRequest(r.data)),
  create: (data: {
    roomId: string;
    title: string;
    description?: string;
    priority?: string;
    category?: string;
    expectedResolvedAt?: string;
    preferredTimeSlots?: string[];
  }) =>
    api.post<MaintenanceRequest>("/maintenance", data).then((r) => normalizeMaintenanceRequest(r.data)),
  assign: (id: string, technicianId: string) =>
    api
      .post<MaintenanceRequest>(`/maintenance/${id}/assign`, null, { params: { technicianId } })
      .then((r) => normalizeMaintenanceRequest(r.data)),
  startWork: (id: string) =>
    api
      .post<MaintenanceRequest>(`/maintenance/${id}/start`)
      .then((r) => normalizeMaintenanceRequest(r.data)),
  start: (id: string) =>
    api
      .post<MaintenanceRequest>(`/maintenance/${id}/start`)
      .then((r) => normalizeMaintenanceRequest(r.data)),
  submitReview: (id: string, materialCost?: number) =>
    api
      .post<MaintenanceRequest>(`/maintenance/${id}/submit-review`, null, { params: { materialCost } })
      .then((r) => normalizeMaintenanceRequest(r.data)),
  cancel: (id: string, reason: string) =>
    api
      .post<MaintenanceRequest>(`/maintenance/${id}/cancel`, null, { params: { reason } })
      .then((r) => normalizeMaintenanceRequest(r.data)),
  updateStatus: (id: string, status: string) =>
    api
      .post<MaintenanceRequest>(`/maintenance/${id}/update-status`, null, { params: { status } })
      .then((r) => normalizeMaintenanceRequest(r.data)),
  resolve: (id: string) =>
    api
      .post<MaintenanceRequest>(`/maintenance/${id}/resolve`)
      .then((r) => normalizeMaintenanceRequest(r.data)),
  updateSla: (id: string, expectedResolvedAt: string) =>
    api
      .patch<MaintenanceRequest>(`/maintenance/${id}/sla`, null, { params: { expectedResolvedAt } })
      .then((r) => normalizeMaintenanceRequest(r.data)),
  confirmSlot: (id: string, slot: string) =>
    api
      .post<MaintenanceRequest>(`/maintenance/${id}/confirm-slot`, null, { params: { slot } })
      .then((r) => normalizeMaintenanceRequest(r.data)),
  tenantConfirmSlot: (id: string, confirm: boolean) =>
    api
      .post<MaintenanceRequest>(`/maintenance/${id}/tenant-confirm-slot`, null, { params: { confirm } })
      .then((r) => normalizeMaintenanceRequest(r.data)),
  complain: (id: string, reason: string) =>
    api
      .post<MaintenanceRequest>(`/maintenance/${id}/complain`, null, { params: { reason } })
      .then((r) => normalizeMaintenanceRequest(r.data)),
  payMaterial: (id: string) =>
    api
      .post<MaintenanceRequest>(`/maintenance/${id}/pay-material`)
      .then((r) => normalizeMaintenanceRequest(r.data)),
  listMaterials: (id: string) =>
    api.get<any[]>(`/maintenance/${id}/materials`).then((r) => r.data ?? []),
  addMaterial: (id: string, data: { name: string; quantity?: number; unit?: string; unitPrice: number; isFreeInContract?: boolean }) =>
    api.post<any>(`/maintenance/${id}/materials`, data).then((r) => r.data),
  deleteMaterial: (id: string, materialId: string) =>
    api.delete(`/maintenance/${id}/materials/${materialId}`),
  listNotes: (id: string) =>
    api.get<any[]>(`/maintenance/${id}/notes`).then((r) => r.data ?? []),
  addNote: (id: string, note: string) =>
    api.post<any>(`/maintenance/${id}/notes`, null, { params: { note } }).then((r) => r.data),
};
