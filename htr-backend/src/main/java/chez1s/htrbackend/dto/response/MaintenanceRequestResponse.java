package chez1s.htrbackend.dto.response;

import chez1s.htrbackend.domain.entity.MaintenanceRequest;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

public record MaintenanceRequestResponse(
        UUID id,
        UUID roomId,
        String roomNumber,
        UUID propertyId,
        UUID tenantId,
        String tenantName,
        String title,
        String description,
        List<String> images,
        String status,
        String priority,
        String category,
        UUID assignedToId,
        String assignedToName,
        LocalDateTime resolvedAt,
        LocalDateTime expectedResolvedAt,
        String cancelReason,
        BigDecimal materialCost,
        LocalDateTime createdAt,
        LocalDateTime updatedAt
) {
    public static MaintenanceRequestResponse from(MaintenanceRequest m) {
        return new MaintenanceRequestResponse(
                m.getId(),
                m.getRoom().getId(),
                m.getRoom().getRoomNumber(),
                m.getRoom().getProperty().getId(),
                m.getTenant().getId(),
                m.getTenant().getFullName(),
                m.getTitle(),
                m.getDescription(),
                m.getImages(),
                m.getStatus().name(),
                m.getPriority() != null ? m.getPriority().name() : "NORMAL",
                m.getCategory() != null ? m.getCategory().name() : "OTHER",
                m.getAssignedTo() != null ? m.getAssignedTo().getId() : null,
                m.getAssignedTo() != null ? m.getAssignedTo().getFullName() : null,
                m.getResolvedAt(),
                m.getExpectedResolvedAt(),
                m.getCancelReason(),
                m.getMaterialCost() != null ? m.getMaterialCost() : BigDecimal.ZERO,
                m.getCreatedAt(),
                m.getUpdatedAt()
        );
    }
}
