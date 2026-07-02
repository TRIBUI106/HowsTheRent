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
      .get<Page<MaintenanceRequest>>("/maintenance/my")
      .then((r) => extractPageContent(r.data).map(normalizeMaintenanceRequest)),
  listAssigned: () =>
    api
      .get<MaintenanceRequest[]>("/maintenance/assigned")
      .then((r) => (r.data ?? []).map(normalizeMaintenanceRequest)),
  getById: (id: string) =>
    api.get<MaintenanceRequest>(`/maintenance/${id}`).then((r) => normalizeMaintenanceRequest(r.data)),
  create: (data: { roomId: string; title: string; description?: string }) =>
    api.post<MaintenanceRequest>("/maintenance", data).then((r) => normalizeMaintenanceRequest(r.data)),
  assign: (id: string, technicianId: string) =>
    api
      .post<MaintenanceRequest>(`/maintenance/${id}/assign`, null, { params: { technicianId } })
      .then((r) => normalizeMaintenanceRequest(r.data)),
  resolve: (id: string) =>
    api
      .post<MaintenanceRequest>(`/maintenance/${id}/resolve`)
      .then((r) => normalizeMaintenanceRequest(r.data)),
};
