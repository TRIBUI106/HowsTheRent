package chez1s.htrbackend.dto.response;

import chez1s.htrbackend.domain.entity.Room;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

public record RoomResponse(
        UUID id,
        UUID propertyId,
        String propertyName,
        String roomNumber,
        Integer floor,
        BigDecimal areaM2,
        Integer maxPeople,
        BigDecimal rentOverride,
        String status,
        List<String> images,
        LocalDateTime createdAt,
        LocalDateTime updatedAt
) {
    public static RoomResponse from(Room r) {
        return new RoomResponse(
                r.getId(),
                r.getProperty().getId(),
                r.getProperty().getName(),
                r.getRoomNumber(),
                r.getFloor(),
                r.getAreaM2(),
                r.getMaxPeople(),
                r.getRentOverride(),
                r.getStatus().name(),
                r.getImages(),
                r.getCreatedAt(),
                r.getUpdatedAt()
        );
    }
}
