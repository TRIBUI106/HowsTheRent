package chez1s.htrbackend.dto.response;

import chez1s.htrbackend.domain.entity.FeeConfig;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.UUID;

public record FeeConfigResponse(
        UUID id,
        UUID propertyId,
        BigDecimal rentDefault,
        BigDecimal elecPrice,
        String waterMode,
        BigDecimal waterPrice,
        BigDecimal serviceFee,
        boolean vehicleProRata,
        boolean serviceProRata,
        LocalDateTime createdAt,
        LocalDateTime updatedAt
) {
    public static FeeConfigResponse from(FeeConfig f) {
        return new FeeConfigResponse(
                f.getId(),
                f.getProperty().getId(),
                f.getRentDefault(),
                f.getElecPrice(),
                f.getWaterMode().name(),
                f.getWaterPrice(),
                f.getServiceFee(),
                f.isVehicleProRata(),
                f.isServiceProRata(),
                f.getCreatedAt(),
                f.getUpdatedAt()
        );
    }
}
