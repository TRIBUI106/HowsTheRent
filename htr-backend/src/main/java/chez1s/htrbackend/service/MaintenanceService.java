package chez1s.htrbackend.service;

import chez1s.htrbackend.domain.entity.MaintenanceRequest;
import chez1s.htrbackend.domain.entity.Room;
import chez1s.htrbackend.domain.entity.User;
import chez1s.htrbackend.domain.enums.*;
import chez1s.htrbackend.domain.repository.ContractRepository;
import chez1s.htrbackend.domain.repository.MaintenanceRequestRepository;
import chez1s.htrbackend.domain.repository.UserRepository;
import chez1s.htrbackend.dto.request.CreateMaintenanceRequest;
import chez1s.htrbackend.dto.response.MaintenanceRequestResponse;
import chez1s.htrbackend.dto.response.PageResponse;
import chez1s.htrbackend.exception.BusinessException;
import chez1s.htrbackend.exception.ResourceNotFoundException;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class MaintenanceService {

    private final MaintenanceRequestRepository maintenanceRepository;
    private final ContractRepository contractRepository;
    private final RoomService roomService;
    private final UserRepository userRepository;
    private final NotificationService notificationService;

    public List<MaintenanceRequest> listAll() {
        return maintenanceRepository.findAll();
    }

    public PageResponse<MaintenanceRequestResponse> listAllByOwner(UUID ownerId, Pageable pageable) {
        boolean isAdmin = userRepository.findById(ownerId)
                .map(u -> u.getRole() == UserRole.ADMIN)
                .orElse(false);
        if (isAdmin) {
            return PageResponse.from(maintenanceRepository.findAll(pageable).map(MaintenanceRequestResponse::from));
        }
        return PageResponse.from(maintenanceRepository.findByRoomPropertyOwnerId(ownerId, pageable).map(MaintenanceRequestResponse::from));
    }

    public List<MaintenanceRequest> listByTenant(UUID tenantId) {
        return maintenanceRepository.findByTenantIdOrderByCreatedAtDesc(tenantId);
    }

    public PageResponse<MaintenanceRequestResponse> listByTenant(UUID tenantId, Pageable pageable) {
        return PageResponse.from(maintenanceRepository.findByTenantId(tenantId, pageable).map(MaintenanceRequestResponse::from));
    }

    public List<MaintenanceRequest> listByTechnician(UUID techId) {
        return maintenanceRepository.findByAssignedToIdOrderByCreatedAtDesc(techId);
    }

    public MaintenanceRequest getById(UUID id) {
        return maintenanceRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("MaintenanceRequest", id));
    }

    @Transactional
    public MaintenanceRequest create(UUID tenantId, CreateMaintenanceRequest req) {
        Room room;
        if (req.getRoomId() != null) {
            room = roomService.getById(req.getRoomId());
        } else {
            var activeContract = contractRepository.findFirstByTenantIdAndStatusOrderByCreatedAtDesc(tenantId, ContractStatus.ACTIVE)
                    .orElseThrow(() -> new BusinessException("Bạn chưa có hợp đồng đang hoạt động"));
            room = roomService.getById(activeContract.getRoom().getId());
        }

        MaintenanceRequest mr = MaintenanceRequest.builder()
                .room(room)
                .tenant(User.builder().id(tenantId).build())
                .title(req.getTitle())
                .description(req.getDescription())
                .images(req.getImages() != null ? req.getImages() : List.of())
                .status(MaintenanceStatus.OPEN)
                .priority(req.getPriority() != null ? req.getPriority() : MaintenancePriority.NORMAL)
                .category(req.getCategory() != null ? req.getCategory() : MaintenanceCategory.OTHER)
                .expectedResolvedAt(req.getExpectedResolvedAt())
                .build();
        mr = maintenanceRepository.save(mr);
        notificationService.create(
                room.getProperty().getOwner().getId(),
                "New Maintenance Request",
                req.getTitle(),
                "MAINTENANCE",
                mr.getId()
        );
        return mr;
    }

    @Transactional
    public MaintenanceRequest assign(UUID id, UUID technicianId) {
        MaintenanceRequest mr = getById(id);
        User tech = userRepository.findById(technicianId)
                .orElseThrow(() -> new ResourceNotFoundException("User", technicianId));

        long activeCount = maintenanceRepository.countByAssignedToIdAndStatusNotIn(
                technicianId,
                List.of(MaintenanceStatus.DONE, MaintenanceStatus.COMPLETED, MaintenanceStatus.CANCELLED)
        );
        if (activeCount >= 5 && mr.getAssignedTo() == null) {
            throw new BusinessException("Kỹ thuật viên này đang có " + activeCount + " phiếu chưa hoàn thành (tối đa 5 phiếu cùng lúc).");
        }

        mr.setAssignedTo(tech);
        mr.setStatus(MaintenanceStatus.ASSIGNED);
        mr = maintenanceRepository.save(mr);
        notificationService.create(
                technicianId,
                "Maintenance Assigned",
                mr.getTitle(),
                "MAINTENANCE",
                mr.getId()
        );
        return mr;
    }

    @Transactional
    public MaintenanceRequest startWork(UUID id) {
        MaintenanceRequest mr = getById(id);
        mr.setStatus(MaintenanceStatus.IN_PROGRESS);
        return maintenanceRepository.save(mr);
    }

    @Transactional
    public MaintenanceRequest submitWork(UUID id, BigDecimal materialCost) {
        MaintenanceRequest mr = getById(id);
        if (materialCost != null && materialCost.compareTo(BigDecimal.ZERO) > 0) {
            mr.setMaterialCost(materialCost);
            mr.setStatus(MaintenanceStatus.PENDING_PAYMENT);
        } else {
            mr.setStatus(MaintenanceStatus.PENDING_REVIEW);
        }
        return maintenanceRepository.save(mr);
    }

    @Transactional
    public MaintenanceRequest cancel(UUID id, String cancelReason) {
        if (cancelReason == null || cancelReason.trim().isEmpty()) {
            throw new BusinessException("Vui lòng nhập lý do hủy phiếu bảo trì.");
        }
        MaintenanceRequest mr = getById(id);
        mr.setStatus(MaintenanceStatus.CANCELLED);
        mr.setCancelReason(cancelReason.trim());
        return maintenanceRepository.save(mr);
    }

    @Transactional
    public MaintenanceRequest resolve(UUID id) {
        MaintenanceRequest mr = getById(id);
        if (mr.getStatus() == MaintenanceStatus.DONE || mr.getStatus() == MaintenanceStatus.COMPLETED) {
            throw new BusinessException("Phiếu bảo trì đã hoàn thành trước đó.");
        }
        mr.setStatus(MaintenanceStatus.DONE);
        mr.setResolvedAt(LocalDateTime.now());
        mr = maintenanceRepository.save(mr);
        notificationService.create(
                mr.getTenant().getId(),
                "Maintenance Resolved",
                mr.getTitle(),
                "MAINTENANCE",
                mr.getId()
        );
        return mr;
    }

    @Transactional
    public MaintenanceRequest updateStatus(UUID id, MaintenanceStatus newStatus) {
        MaintenanceRequest mr = getById(id);
        mr.setStatus(newStatus);
        if (newStatus == MaintenanceStatus.DONE || newStatus == MaintenanceStatus.COMPLETED) {
            mr.setResolvedAt(LocalDateTime.now());
        }
        return maintenanceRepository.save(mr);
    }

    @Transactional
    public MaintenanceRequest addImage(UUID requestId, String imageUrl) {
        MaintenanceRequest req = getById(requestId);
        req.getImages().add(imageUrl);
        return maintenanceRepository.save(req);
    }
}
