package chez1s.htrbackend.dto.response;

import chez1s.htrbackend.domain.entity.MaintenanceRequest;

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
        UUID assignedToId,
        String assignedToName,
        LocalDateTime resolvedAt,
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
                m.getAssignedTo() != null ? m.getAssignedTo().getId() : null,
                m.getAssignedTo() != null ? m.getAssignedTo().getFullName() : null,
                m.getResolvedAt(),
                m.getCreatedAt(),
                m.getUpdatedAt()
        );
    }
}
