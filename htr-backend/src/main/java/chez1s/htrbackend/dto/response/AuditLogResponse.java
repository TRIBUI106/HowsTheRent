package chez1s.htrbackend.dto.response;

import chez1s.htrbackend.domain.entity.AuditLog;
import chez1s.htrbackend.domain.enums.AuditAction;
import lombok.Builder;

import java.time.LocalDateTime;
import java.util.UUID;

@Builder
public record AuditLogResponse(
    UUID id,
    AuditAction action,
    String entityType,
    UUID entityId,
    UUID userId,
    String userEmail,
    String description,
    String requestMethod,
    String requestPath,
    String ipAddress,
    LocalDateTime createdAt
) {
    public static AuditLogResponse from(AuditLog log) {
        return AuditLogResponse.builder()
            .id(log.getId())
            .action(log.getAction())
            .entityType(log.getEntityType())
            .entityId(log.getEntityId())
            .userId(log.getUserId())
            .userEmail(log.getUserEmail())
            .description(log.getDescription())
            .requestMethod(log.getRequestMethod())
            .requestPath(log.getRequestPath())
            .ipAddress(log.getIpAddress())
            .createdAt(log.getCreatedAt())
            .build();
    }
}