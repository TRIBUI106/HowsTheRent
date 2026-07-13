import api from "@/lib/api";
import type {
  MaintenanceReportSummary,
  TechnicianPerformance,
  SlaRule,
  MaintenanceReview,
} from "@/types";

export const reportApi = {
  getSummary: () =>
    api.get<MaintenanceReportSummary>("/maintenance/reports/summary").then((r) => r.data),
  getTechnicianPerformance: () =>
    api.get<TechnicianPerformance[]>("/maintenance/reports/technician-performance").then((r) => r.data ?? []),
  exportCsv: async () => {
    const response = await api.get("/maintenance/reports/export", { responseType: "blob" });
    const url = window.URL.createObjectURL(new Blob([response.data]));
    const link = document.createElement("a");
    link.href = url;
    link.setAttribute("download", `maintenance_report_${new Date().toISOString().slice(0, 10)}.csv`);
    document.body.appendChild(link);
    link.click();
    link.remove();
  },
  createReview: (requestId: string, ratingStars: number, comment?: string) =>
    api.post<MaintenanceReview>(`/maintenance/${requestId}/reviews`, { ratingStars, comment }).then((r) => r.data),
  listTechnicianReviews: (techId: string) =>
    api.get<MaintenanceReview[]>(`/maintenance/reviews/technician/${techId}`).then((r) => r.data ?? []),
  listAllReviews: () =>
    api.get<MaintenanceReview[]>("/maintenance/reviews").then((r) => r.data ?? []),
};

export const slaApi = {
  listRules: () =>
    api.get<SlaRule[]>("/maintenance/sla-rules").then((r) => r.data ?? []),
  createOrUpdateRule: (priority: string, category: string, maxHours: number) =>
    api.post<SlaRule>("/maintenance/sla-rules", { priority, category, maxHours }).then((r) => r.data),
  deleteRule: (id: string) =>
    api.delete(`/maintenance/sla-rules/${id}`),
};
