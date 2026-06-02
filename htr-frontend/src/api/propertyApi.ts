import api from "@/lib/api";
import type { Property, FeeConfig } from "@/types";

export const propertyApi = {
  list: () => api.get<Property[]>("/properties").then((r) => r.data),
  listMine: () => api.get<Property[]>("/properties/mine").then((r) => r.data),
  getById: (id: string) =>
    api.get<Property>(`/properties/${id}`).then((r) => r.data),
  create: (data: {
    name: string;
    address: string;
    propertyTypeId: string;
    description?: string;
  }) => api.post<Property>("/properties", data).then((r) => r.data),
  update: (
    id: string,
    data: {
      name: string;
      address: string;
      propertyTypeId: string;
      description?: string;
    },
  ) => api.put<Property>(`/properties/${id}`, data).then((r) => r.data),
  getFeeConfig: (id: string) =>
    api.get<FeeConfig>(`/properties/${id}/fee-config`).then((r) => r.data),
  updateFeeConfig: (id: string, data: Partial<FeeConfig>) =>
    api
      .put<FeeConfig>(`/properties/${id}/fee-config`, data)
      .then((r) => r.data),
};
