import api from "@/lib/api";
import type { Notification, Page } from "@/types";

export const notificationApi = {
  list: () =>
    api
      .get<Page<Notification>>("/notifications")
      .then((r) => r.data.content ?? []),
  markRead: (id: string) =>
    api.post(`/notifications/${id}/read`).then((r) => r.data),
  markAllRead: () => api.post("/notifications/read-all").then((r) => r.data),
};
