package chez1s.htrbackend.service;

import chez1s.htrbackend.domain.enums.MaintenanceStatus;
import chez1s.htrbackend.exception.BadRequestException;
import org.springframework.stereotype.Component;

import java.util.Set;

@Component
public class MaintenanceStateTransitionValidator {

    public void validateTransition(MaintenanceStatus current, MaintenanceStatus target) {
        if (current == target) return;

        if (current == MaintenanceStatus.COMPLETED || current == MaintenanceStatus.CANCELLED || current == MaintenanceStatus.DONE) {
            throw new BadRequestException("Phiếu bảo trì đã kết thúc (Hoàn thành hoặc Đã hủy), không thể chỉnh sửa hay thay đổi trạng thái.");
        }

        boolean allowed = switch (current) {
            case OPEN -> Set.of(MaintenanceStatus.ASSIGNED, MaintenanceStatus.CANCELLED).contains(target);
            case ASSIGNED -> Set.of(MaintenanceStatus.IN_PROGRESS, MaintenanceStatus.CANCELLED, MaintenanceStatus.OPEN).contains(target);
            case IN_PROGRESS -> Set.of(MaintenanceStatus.PENDING_PAYMENT, MaintenanceStatus.PENDING_REVIEW, MaintenanceStatus.COMPLETED, MaintenanceStatus.CANCELLED).contains(target);
            case PENDING_PAYMENT -> Set.of(MaintenanceStatus.PENDING_REVIEW, MaintenanceStatus.CANCELLED).contains(target);
            case PENDING_REVIEW -> Set.of(MaintenanceStatus.COMPLETED, MaintenanceStatus.IN_PROGRESS, MaintenanceStatus.CANCELLED).contains(target);
            default -> false;
        };

        if (!allowed) {
            throw new BadRequestException("Không thể chuyển trạng thái bảo trì từ " + current + " sang " + target + ".");
        }
    }
}
