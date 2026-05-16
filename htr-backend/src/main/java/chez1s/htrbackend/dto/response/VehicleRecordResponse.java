package chez1s.htrbackend.dto.response;

import chez1s.htrbackend.domain.entity.VehicleRecord;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.UUID;

public record VehicleRecordResponse(
        UUID id,
        UUID roomId,
        String roomNumber,
        LocalDate recordMonth,
        int motorbikeCount,
        int carCount,
        int bicycleCount,
        LocalDateTime createdAt,
        LocalDateTime updatedAt
) {
    public static VehicleRecordResponse from(VehicleRecord v) {
        return new VehicleRecordResponse(
                v.getId(),
                v.getRoom().getId(),
                v.getRoom().getRoomNumber(),
                v.getRecordMonth(),
                v.getMotorbikeCount(),
                v.getCarCount(),
                v.getBicycleCount(),
                v.getCreatedAt(),
                v.getUpdatedAt()
        );
    }
}
