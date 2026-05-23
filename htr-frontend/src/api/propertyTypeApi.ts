import api from "@/lib/api";
import type { PropertyType } from "@/types";

export const propertyTypeApi = {
  list: () => api.get<PropertyType[]>("/property-types").then((r) => r.data),
  listActive: () =>
    api
      .get<PropertyType[]>("/property-types", { params: { activeOnly: true } })
      .then((r) => r.data),

  create: (data: { code: string; name: string; description?: string }) =>
    api.post<PropertyType>("/property-types", data).then((r) => r.data),

  update: (
    id: string,
    data: { code: string; name: string; description?: string },
  ) => api.put<PropertyType>(`/property-types/${id}`, data).then((r) => r.data),

  updateActive: (id: string, active: boolean) =>
    api
      .patch<PropertyType>(`/property-types/${id}/active`, { active })
      .then((r) => r.data),
      
  remove: (id: string) => api.delete(`/property-types/${id}`),
};
