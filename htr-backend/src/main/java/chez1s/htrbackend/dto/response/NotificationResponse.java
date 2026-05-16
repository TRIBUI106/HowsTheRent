package chez1s.htrbackend.dto.response;

import chez1s.htrbackend.domain.entity.Notification;

import java.time.LocalDateTime;
import java.util.UUID;

public record NotificationResponse(
        UUID id,
        UUID userId,
        String title,
        String body,
        boolean read,
        String type,
        UUID refId,
        LocalDateTime createdAt
) {
    public static NotificationResponse from(Notification n) {
        return new NotificationResponse(
                n.getId(),
                n.getUser().getId(),
                n.getTitle(),
                n.getBody(),
                n.isRead(),
                n.getType(),
                n.getRefId(),
                n.getCreatedAt()
        );
    }
}
