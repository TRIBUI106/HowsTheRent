package chez1s.htrbackend.controller;

import chez1s.htrbackend.domain.enums.AuditAction;
import chez1s.htrbackend.dto.response.AuditLogResponse;
import chez1s.htrbackend.dto.response.PageResponse;
import chez1s.htrbackend.service.AuditService;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.data.web.PageableDefault;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDateTime;
import java.util.UUID;

@RestController
@RequestMapping("/api/audit")
@RequiredArgsConstructor
public class AuditController {

    private final AuditService auditService;

    @GetMapping
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<PageResponse<AuditLogResponse>> list(
            @RequestParam(required = false) String action,
            @RequestParam(required = false) String entityType,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime from,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime to,
            @PageableDefault(size = 20, sort = "createdAt", direction = Sort.Direction.DESC) Pageable pageable) {

        if (action != null) {
            return ResponseEntity.ok(auditService.listByAction(AuditAction.valueOf(action.toUpperCase()), pageable));
        }
        if (entityType != null) {
            return ResponseEntity.ok(auditService.listByEntityType(entityType, pageable));
        }
        if (from != null && to != null) {
            return ResponseEntity.ok(auditService.listByDateRange(from, to, pageable));
        }
        return ResponseEntity.ok(auditService.list(pageable));
    }
}