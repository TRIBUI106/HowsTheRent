import api from "@/lib/api";
import type { User, Page } from "@/types";

export const userApi = {
  listAll: () =>
    api.get<Page<User>>("/users", { params: { size: 200 } }).then((r) => r.data.content ?? []),
  me: () => api.get<User>("/users/me").then((r) => r.data),
  getById: (id: string) => api.get<User>(`/users/${id}`).then((r) => r.data),
  create: (data: {
    fullName: string;
    email: string;
    phone?: string;
    password: string;
    role: 'ADMIN' | 'TENANT' | 'TECHNICIAN';
  }) => api.post<User>("/users", data).then((r) => r.data),
  update: (
    id: string,
    data: Partial<{
      fullName: string;
      phone: string;
      role: 'ADMIN' | 'TENANT' | 'TECHNICIAN';
    }>,
  ) => api.put<User>(`/users/${id}`, data).then((r) => r.data),
  toggleActive: (id: string) =>
    api.patch<User>(`/users/${id}/toggle-active`).then((r) => r.data),
};
