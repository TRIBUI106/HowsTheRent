package chez1s.htrbackend.service;

import chez1s.htrbackend.domain.entity.MaintenanceRequest;
import chez1s.htrbackend.domain.enums.MaintenanceStatus;
import chez1s.htrbackend.domain.repository.MaintenanceRequestRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;

@Slf4j
@Service
@RequiredArgsConstructor
public class MaintenanceCronService {

    private final MaintenanceRequestRepository maintenanceRepository;
    private final MaintenanceService maintenanceService;
    private final NotificationService notificationService;

    @Scheduled(fixedDelay = 1800000) // 30 minutes
    @Transactional
    public void checkOverdueSla() {
        LocalDateTime now = LocalDateTime.now();
        List<MaintenanceStatus> activeStatuses = List.of(MaintenanceStatus.OPEN, MaintenanceStatus.ASSIGNED, MaintenanceStatus.IN_PROGRESS);
        List<MaintenanceRequest> overdueRequests = maintenanceRepository.findByStatusInAndExpectedResolvedAtBeforeAndIsOverdueSlaFalse(activeStatuses, now);

        for (MaintenanceRequest mr : overdueRequests) {
            mr.setIsOverdueSla(true);
            maintenanceRepository.save(mr);
            maintenanceService.addNote(mr.getId(), null, "CẢNH BÁO: Phiếu bảo trì đã quá hạn SLA (" + mr.getExpectedResolvedAt() + ")");
            notificationService.create(
                    mr.getRoom().getProperty().getOwner().getId(),
                    "Cảnh báo quá hạn SLA: " + mr.getTicketCode(),
                    "Phiếu bảo trì " + mr.getTitle() + " đã quá hạn SLA.",
                    "MAINTENANCE",
                    mr.getId()
            );
            if (mr.getAssignedTo() != null) {
                notificationService.create(
                        mr.getAssignedTo().getId(),
                        "Khẩn cấp: Quá hạn SLA " + mr.getTicketCode(),
                        "Phiếu bảo trì " + mr.getTitle() + " đã vượt thời gian xử lý dự kiến.",
                        "MAINTENANCE",
                        mr.getId()
                );
            }
        }
    }

    @Scheduled(fixedDelay = 3600000) // 1 hour
    @Transactional
    public void autoAcceptPendingReview() {
        LocalDateTime threshold = LocalDateTime.now().minusHours(48);
        List<MaintenanceRequest> pendingRequests = maintenanceRepository.findByStatusAndUpdatedAtBefore(MaintenanceStatus.PENDING_REVIEW, threshold);

        for (MaintenanceRequest mr : pendingRequests) {
            log.info("Auto accepting PENDING_REVIEW maintenance request {} after 48h", mr.getTicketCode());
            mr.setStatus(MaintenanceStatus.DONE);
            mr.setResolvedAt(LocalDateTime.now());
            maintenanceRepository.save(mr);
            maintenanceService.addNote(mr.getId(), null, "Hệ thống tự động nghiệm thu sau 48h không có phản hồi từ cư dân");
            notificationService.create(
                    mr.getTenant().getId(),
                    "Tự động nghiệm thu " + mr.getTicketCode(),
                    "Phiếu bảo trì đã được tự động đóng do quá 48h sau sửa chữa không có phản hồi.",
                    "MAINTENANCE",
                    mr.getId()
            );
        }
    }
}
