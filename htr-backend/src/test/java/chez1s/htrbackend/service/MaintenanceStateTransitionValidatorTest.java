package chez1s.htrbackend.service;

import chez1s.htrbackend.domain.enums.MaintenanceStatus;
import chez1s.htrbackend.exception.BadRequestException;
import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.*;

class MaintenanceStateTransitionValidatorTest {

    private final MaintenanceStateTransitionValidator validator = new MaintenanceStateTransitionValidator();

    @Test
    void validateTransition_AllowedTransitions_NoExceptionThrown() {
        assertDoesNotThrow(() -> validator.validateTransition(MaintenanceStatus.OPEN, MaintenanceStatus.ASSIGNED));
        assertDoesNotThrow(() -> validator.validateTransition(MaintenanceStatus.OPEN, MaintenanceStatus.CANCELLED));
        assertDoesNotThrow(() -> validator.validateTransition(MaintenanceStatus.ASSIGNED, MaintenanceStatus.IN_PROGRESS));
        assertDoesNotThrow(() -> validator.validateTransition(MaintenanceStatus.IN_PROGRESS, MaintenanceStatus.PENDING_REVIEW));
        assertDoesNotThrow(() -> validator.validateTransition(MaintenanceStatus.IN_PROGRESS, MaintenanceStatus.PENDING_PAYMENT));
        assertDoesNotThrow(() -> validator.validateTransition(MaintenanceStatus.PENDING_PAYMENT, MaintenanceStatus.PENDING_REVIEW));
        assertDoesNotThrow(() -> validator.validateTransition(MaintenanceStatus.PENDING_REVIEW, MaintenanceStatus.COMPLETED));
        assertDoesNotThrow(() -> validator.validateTransition(MaintenanceStatus.PENDING_REVIEW, MaintenanceStatus.IN_PROGRESS));
    }

    @Test
    void validateTransition_IllegalTransitions_ThrowsBadRequestException() {
        assertThrows(BadRequestException.class, () -> validator.validateTransition(MaintenanceStatus.OPEN, MaintenanceStatus.COMPLETED));
        assertThrows(BadRequestException.class, () -> validator.validateTransition(MaintenanceStatus.OPEN, MaintenanceStatus.PENDING_REVIEW));
        assertThrows(BadRequestException.class, () -> validator.validateTransition(MaintenanceStatus.COMPLETED, MaintenanceStatus.IN_PROGRESS));
        assertThrows(BadRequestException.class, () -> validator.validateTransition(MaintenanceStatus.CANCELLED, MaintenanceStatus.OPEN));
    }
}
