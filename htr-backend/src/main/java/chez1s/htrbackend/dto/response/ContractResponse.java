package chez1s.htrbackend.dto.response;

import chez1s.htrbackend.domain.entity.Contract;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.UUID;

public record ContractResponse(
        UUID id,
        UUID roomId,
        String roomNumber,
        UUID propertyId,
        String propertyName,
        UUID tenantId,
        String tenantName,
        String tenantEmail,
        LocalDate moveInDate,
        LocalDate moveOutDate,
        String status,
        BigDecimal depositAmount,
        String notes,
        String fileUrl,
        LocalDateTime createdAt,
        LocalDateTime updatedAt
) {
    public static ContractResponse from(Contract c) {
        return new ContractResponse(
                c.getId(),
                c.getRoom().getId(),
                c.getRoom().getRoomNumber(),
                c.getRoom().getProperty().getId(),
                c.getRoom().getProperty().getName(),
                c.getTenant().getId(),
                c.getTenant().getFullName(),
                c.getTenant().getEmail(),
                c.getMoveInDate(),
                c.getMoveOutDate(),
                c.getStatus().name(),
                c.getDepositAmount(),
                c.getNotes(),
                c.getFileUrl(),
                c.getCreatedAt(),
                c.getUpdatedAt()
        );
    }
}
