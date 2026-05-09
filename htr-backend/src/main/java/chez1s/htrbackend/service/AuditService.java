package chez1s.htrbackend.service;

import chez1s.htrbackend.domain.entity.AuditLog;
import chez1s.htrbackend.domain.enums.AuditAction;
import chez1s.htrbackend.domain.repository.AuditLogRepository;
import chez1s.htrbackend.dto.response.AuditLogResponse;
import chez1s.htrbackend.dto.response.PageResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class AuditService {

    private final AuditLogRepository auditLogRepository;

    public void log(AuditAction action, String entityType, UUID entityId,
                    UUID userId, String userEmail, String description,
                    String requestMethod, String requestPath, String ipAddress) {
        AuditLog log = AuditLog.builder()
            .action(action)
            .entityType(entityType)
            .entityId(entityId)
            .userId(userId)
            .userEmail(userEmail)
            .description(description)
            .requestMethod(requestMethod)
            .requestPath(requestPath)
            .ipAddress(ipAddress)
            .build();
        auditLogRepository.save(log);
    }

    public void logAction(AuditAction action, String entityType, UUID entityId,
                          UUID userId, String userEmail, String description) {
        log(action, entityType, entityId, userId, userEmail, description, null, null, null);
    }

    public PageResponse<AuditLogResponse> list(Pageable pageable) {
        return PageResponse.from(auditLogRepository.findAll(pageable).map(AuditLogResponse::from));
    }

    public PageResponse<AuditLogResponse> listByUser(UUID userId, Pageable pageable) {
        return PageResponse.from(auditLogRepository.findByUserIdOrderByCreatedAtDesc(userId, pageable).map(AuditLogResponse::from));
    }

    public PageResponse<AuditLogResponse> listByEntityType(String entityType, Pageable pageable) {
        return PageResponse.from(auditLogRepository.findByEntityTypeOrderByCreatedAtDesc(entityType, pageable).map(AuditLogResponse::from));
    }

    public PageResponse<AuditLogResponse> listByAction(AuditAction action, Pageable pageable) {
        return PageResponse.from(auditLogRepository.findByActionOrderByCreatedAtDesc(action, pageable).map(AuditLogResponse::from));
    }

    public PageResponse<AuditLogResponse> listByDateRange(LocalDateTime from, LocalDateTime to, Pageable pageable) {
        return PageResponse.from(auditLogRepository.findByDateRange(from, to, pageable).map(AuditLogResponse::from));
    }
}