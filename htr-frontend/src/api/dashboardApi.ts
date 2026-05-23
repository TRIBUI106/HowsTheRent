import api from "@/lib/api";
import type { Dashboard } from "@/types";

export const dashboardApi = {
  getAdmin: () => api.get<Dashboard>("/dashboard").then((r) => r.data),
  getTenant: () => api.get<any>("/dashboard/tenant").then((r) => r.data),
};
