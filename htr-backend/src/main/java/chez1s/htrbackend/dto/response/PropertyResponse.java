package chez1s.htrbackend.dto.response;

import chez1s.htrbackend.domain.entity.Property;

import java.time.LocalDateTime;
import java.util.UUID;

public record PropertyResponse(
        UUID id,
        UUID ownerId,
        String ownerName,
        String name,
        String address,
        UUID propertyTypeId,
        String propertyTypeCode,
        String propertyTypeName,
        String description,
        LocalDateTime createdAt,
        LocalDateTime updatedAt
) {
    public static PropertyResponse from(Property p) {
        return new PropertyResponse(
                p.getId(),
                p.getOwner().getId(),
                p.getOwner().getFullName(),
                p.getName(),
                p.getAddress(),
                p.getType().getId(),
                p.getType().getCode(),
                p.getType().getName(),
                p.getDescription(),
                p.getCreatedAt(),
                p.getUpdatedAt()
        );
    }
}
