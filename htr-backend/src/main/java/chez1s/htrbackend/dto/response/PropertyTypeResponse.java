package chez1s.htrbackend.dto.response;

import chez1s.htrbackend.domain.entity.PropertyType;

import java.util.UUID;

public record PropertyTypeResponse(
        UUID id,
        String code,
        String name,
        String description,
        boolean active
) {
    public static PropertyTypeResponse from(PropertyType type) {
        return new PropertyTypeResponse(
                type.getId(),
                type.getCode(),
                type.getName(),
                type.getDescription(),
                type.isActive()
        );
    }
}
