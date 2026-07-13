package chez1s.htrbackend.domain.enums;

public enum MaintenanceStatus {
    OPEN,
    ASSIGNED,
    IN_PROGRESS,
    PENDING_PAYMENT,
    PENDING_REVIEW,
    COMPLETED,
    CANCELLED,
    DONE // Backward compatibility alias for COMPLETED
}
