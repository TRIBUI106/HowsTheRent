package chez1s.htrbackend.dto.response;

import chez1s.htrbackend.domain.entity.MaintenanceMaterial;
import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.UUID;

public record MaintenanceMaterialResponse(
        UUID id,
        UUID requestId,
        String name,
        Integer quantity,
        String unit,
        BigDecimal unitPrice,
        BigDecimal totalPrice,
        Boolean isFreeInContract,
        LocalDateTime createdAt
) {
    public static MaintenanceMaterialResponse from(MaintenanceMaterial m) {
        return new MaintenanceMaterialResponse(
                m.getId(),
                m.getRequest().getId(),
                m.getName(),
                m.getQuantity(),
                m.getUnit(),
                m.getUnitPrice(),
                m.getTotalPrice(),
                m.getIsFreeInContract(),
                m.getCreatedAt()
        );
    }
}
