import api from "@/lib/api";
import type { MeterReading, VehicleRecord } from "@/types";

export const meterReadingApi = {
  listByRoom: (roomId: string) =>
    api
      .get<MeterReading[]>(`/rooms/${roomId}/meter-readings`)
      .then((r) => r.data),
  create: (
    roomId: string,
    data: {
      readingMonth: string;
      elecOld: number;
      elecNew: number;
      waterOld?: number;
      waterNew?: number;
    },
  ) =>
    api
      .post<MeterReading>(`/rooms/${roomId}/meter-readings`, data)
      .then((r) => r.data),
  getVehicleRecord: (roomId: string) =>
    api
      .get<VehicleRecord>(`/rooms/${roomId}/vehicle-records`)
      .then((r) => r.data),
  updateVehicleRecord: (
    roomId: string,
    data: {
      recordMonth: string;
      motorbikeCount: number;
      carCount: number;
      bicycleCount: number;
    },
  ) =>
    api
      .put<VehicleRecord>(`/rooms/${roomId}/vehicle-records`, data)
      .then((r) => r.data),
};
