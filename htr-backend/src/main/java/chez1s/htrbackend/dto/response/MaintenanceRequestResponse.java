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
        String ticketCode,
        List<String> preferredTimeSlots,
        String confirmedTimeSlot,
        Boolean confirmSlotByTenant,
        List<String> completionImages,
        String attachmentVideo,
        LocalDateTime startedAt,
        Boolean isOverdueSla,
        Boolean isComplained,
        String complainReason,
        String cancelReason,
        BigDecimal materialCost,
        LocalDateTime materialPaidAt,
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
                m.getImages() != null ? m.getImages() : List.of(),
                m.getStatus().name(),
                m.getPriority() != null ? m.getPriority().name() : "NORMAL",
                m.getCategory() != null ? m.getCategory().name() : "OTHER",
                m.getAssignedTo() != null ? m.getAssignedTo().getId() : null,
                m.getAssignedTo() != null ? m.getAssignedTo().getFullName() : null,
                m.getResolvedAt(),
                m.getExpectedResolvedAt(),
                m.getTicketCode(),
                m.getPreferredTimeSlots() != null ? m.getPreferredTimeSlots() : List.of(),
                m.getConfirmedTimeSlot(),
                m.getConfirmSlotByTenant() != null ? m.getConfirmSlotByTenant() : false,
                m.getCompletionImages() != null ? m.getCompletionImages() : List.of(),
                m.getAttachmentVideo(),
                m.getStartedAt(),
                m.getIsOverdueSla() != null ? m.getIsOverdueSla() : false,
                m.getIsComplained() != null ? m.getIsComplained() : false,
                m.getComplainReason(),
                m.getCancelReason(),
                m.getMaterialCost() != null ? m.getMaterialCost() : BigDecimal.ZERO,
                m.getMaterialPaidAt(),
                m.getCreatedAt(),
                m.getUpdatedAt()
        );
    }
}
