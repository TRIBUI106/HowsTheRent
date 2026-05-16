package chez1s.htrbackend.dto.response;

import chez1s.htrbackend.domain.entity.VehicleConfig;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.UUID;

public record VehicleConfigResponse(
        UUID id,
        UUID propertyId,
        BigDecimal motorbikePrice,
        BigDecimal carPrice,
        BigDecimal bicyclePrice,
        LocalDateTime createdAt,
        LocalDateTime updatedAt
) {
    public static VehicleConfigResponse from(VehicleConfig v) {
        return new VehicleConfigResponse(
                v.getId(),
                v.getProperty().getId(),
                v.getMotorbikePrice(),
                v.getCarPrice(),
                v.getBicyclePrice(),
                v.getCreatedAt(),
                v.getUpdatedAt()
        );
    }
}
