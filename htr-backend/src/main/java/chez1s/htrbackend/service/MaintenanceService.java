package chez1s.htrbackend.service;

import chez1s.htrbackend.domain.entity.*;
import chez1s.htrbackend.domain.enums.*;
import chez1s.htrbackend.domain.repository.*;
import chez1s.htrbackend.dto.request.CreateMaintenanceMaterial;
import chez1s.htrbackend.dto.request.CreateMaintenanceRequest;
import chez1s.htrbackend.dto.response.MaintenanceMaterialResponse;
import chez1s.htrbackend.dto.response.MaintenanceNoteResponse;
import chez1s.htrbackend.dto.response.MaintenanceRequestResponse;
import chez1s.htrbackend.dto.response.PageResponse;
import chez1s.htrbackend.exception.BadRequestException;
import chez1s.htrbackend.exception.BusinessException;
import chez1s.htrbackend.exception.ResourceNotFoundException;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.List;
import java.util.UUID;
import java.util.concurrent.atomic.AtomicLong;

@Service
@RequiredArgsConstructor
public class MaintenanceService {

    private final MaintenanceRequestRepository maintenanceRepository;
    private final ContractRepository contractRepository;
    private final RoomService roomService;
    private final UserRepository userRepository;
    private final NotificationService notificationService;
    private final MaintenanceMaterialRepository materialRepository;
    private final MaintenanceNoteRepository noteRepository;
    private final MaintenanceStateTransitionValidator transitionValidator;

    private static final AtomicLong codeCounter = new AtomicLong(System.currentTimeMillis() % 1000);

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

    public PageResponse<MaintenanceRequestResponse> listFiltered(UUID ownerId, List<MaintenanceStatus> statuses, Pageable pageable) {
        boolean isAdmin = userRepository.findById(ownerId)
                .map(u -> u.getRole() == UserRole.ADMIN)
                .orElse(false);
        if (statuses == null || statuses.isEmpty()) {
            return listAllByOwner(ownerId, pageable);
        }
        if (isAdmin) {
            return PageResponse.from(maintenanceRepository.findByStatusIn(statuses, pageable).map(MaintenanceRequestResponse::from));
        }
        return PageResponse.from(maintenanceRepository.findByRoomPropertyOwnerIdAndStatusIn(ownerId, statuses, pageable).map(MaintenanceRequestResponse::from));
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

    private String generateTicketCode() {
        String datePart = LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyyMMdd"));
        long num = codeCounter.incrementAndGet() % 1000;
        return String.format("MNT-%s-%03d", datePart, num);
    }

    @Transactional
    public MaintenanceRequest create(UUID tenantId, CreateMaintenanceRequest req) {
        if (req.getDescription() != null && req.getDescription().trim().length() > 0 && req.getDescription().trim().length() < 10) {
            throw new BadRequestException("Mô tả yêu cầu bảo trì tối thiểu 10 ký tự.");
        }

        Room room;
        if (req.getRoomId() != null) {
            room = roomService.getById(req.getRoomId());
        } else {
            var activeContract = contractRepository.findFirstByTenantIdAndStatusOrderByCreatedAtDesc(tenantId, ContractStatus.ACTIVE)
                    .orElseThrow(() -> new BusinessException("Bạn chưa có hợp đồng đang hoạt động"));
            room = roomService.getById(activeContract.getRoom().getId());
        }

        User tenant = userRepository.findById(tenantId)
                .orElse(User.builder().id(tenantId).build());

        MaintenanceRequest mr = MaintenanceRequest.builder()
                .ticketCode(generateTicketCode())
                .room(room)
                .tenant(tenant)
                .title(req.getTitle())
                .description(req.getDescription())
                .images(req.getImages() != null ? req.getImages() : List.of())
                .attachmentVideo(req.getAttachmentVideo())
                .preferredTimeSlots(req.getPreferredTimeSlots() != null ? req.getPreferredTimeSlots() : List.of())
                .status(MaintenanceStatus.OPEN)
                .priority(req.getPriority() != null ? req.getPriority() : MaintenancePriority.NORMAL)
                .category(req.getCategory() != null ? req.getCategory() : MaintenanceCategory.OTHER)
                .expectedResolvedAt(req.getExpectedResolvedAt())
                .build();
        mr = maintenanceRepository.save(mr);

        addNote(mr.getId(), tenantId, "Tạo yêu cầu bảo trì mã " + mr.getTicketCode() + " (" + mr.getPriority() + ")");

        notificationService.create(
                room.getProperty().getOwner().getId(),
                "New Maintenance Request " + mr.getTicketCode(),
                req.getTitle() + " - " + mr.getPriority(),
                "MAINTENANCE",
                mr.getId()
        );
        return mr;
    }

    @Transactional
    public MaintenanceRequest assign(UUID id, UUID technicianId) {
        MaintenanceRequest mr = getById(id);
        transitionValidator.validateTransition(mr.getStatus(), MaintenanceStatus.ASSIGNED);

        User tech = userRepository.findById(technicianId)
                .orElseThrow(() -> new ResourceNotFoundException("User", technicianId));

        long activeCount = maintenanceRepository.countByAssignedToIdAndStatusNotIn(
                technicianId,
                List.of(MaintenanceStatus.DONE, MaintenanceStatus.COMPLETED, MaintenanceStatus.CANCELLED)
        );
        if (activeCount >= 5 && (mr.getAssignedTo() == null || !mr.getAssignedTo().getId().equals(technicianId))) {
            throw new BusinessException("Kỹ thuật viên " + tech.getFullName() + " đang có " + activeCount + " phiếu chưa hoàn thành (tối đa 5 phiếu cùng lúc).");
        }

        mr.setAssignedTo(tech);
        mr.setStatus(MaintenanceStatus.ASSIGNED);
        mr = maintenanceRepository.save(mr);

        addNote(mr.getId(), null, "Phân công kỹ thuật viên: " + tech.getFullName());

        notificationService.create(
                technicianId,
                "Phân công bảo trì: " + mr.getTitle(),
                "Mã phiếu: " + mr.getTicketCode() + " - Khách hàng: " + mr.getTenant().getFullName(),
                "MAINTENANCE",
                mr.getId()
        );
        return mr;
    }

    @Transactional
    public MaintenanceRequest startWork(UUID id) {
        MaintenanceRequest mr = getById(id);
        transitionValidator.validateTransition(mr.getStatus(), MaintenanceStatus.IN_PROGRESS);
        mr.setStatus(MaintenanceStatus.IN_PROGRESS);
        if (mr.getStartedAt() == null) {
            mr.setStartedAt(LocalDateTime.now());
        }
        mr = maintenanceRepository.save(mr);
        addNote(mr.getId(), mr.getAssignedTo() != null ? mr.getAssignedTo().getId() : null, "Kỹ thuật viên bắt đầu xử lý công việc");
        return mr;
    }

    @Transactional
    public MaintenanceRequest submitWork(UUID id, BigDecimal materialCost) {
        MaintenanceRequest mr = getById(id);
        transitionValidator.validateTransition(mr.getStatus(), MaintenanceStatus.PENDING_REVIEW);

        if (materialCost != null && materialCost.compareTo(BigDecimal.ZERO) > 0) {
            mr.setMaterialCost(materialCost);
            mr.setStatus(MaintenanceStatus.PENDING_PAYMENT);
            addNote(mr.getId(), mr.getAssignedTo() != null ? mr.getAssignedTo().getId() : null, "Báo giá vật tư: " + materialCost + " VNĐ, chuyển chờ thanh toán");
        } else {
            mr.setStatus(MaintenanceStatus.PENDING_REVIEW);
            addNote(mr.getId(), mr.getAssignedTo() != null ? mr.getAssignedTo().getId() : null, "Hoàn tất xử lý, gửi yêu cầu nghiệm thu cho cư dân/ban quản lý");
        }
        mr = maintenanceRepository.save(mr);

        notificationService.create(
                mr.getTenant().getId(),
                "Cập nhật bảo trì " + mr.getTicketCode(),
                mr.getStatus() == MaintenanceStatus.PENDING_PAYMENT ? "Vui lòng kiểm tra và xác nhận chi phí vật tư: " + materialCost + " VNĐ" : "Kỹ thuật viên đã xử lý xong, vui lòng nghiệm thu",
                "MAINTENANCE",
                mr.getId()
        );
        return mr;
    }

    @Transactional
    public MaintenanceRequest cancel(UUID id, String cancelReason) {
        if (cancelReason == null || cancelReason.trim().length() < 10) {
            throw new BadRequestException("Vui lòng nhập lý do hủy tối thiểu 10 ký tự.");
        }
        MaintenanceRequest mr = getById(id);
        transitionValidator.validateTransition(mr.getStatus(), MaintenanceStatus.CANCELLED);

        mr.setStatus(MaintenanceStatus.CANCELLED);
        mr.setCancelReason(cancelReason.trim());
        mr = maintenanceRepository.save(mr);

        addNote(mr.getId(), null, "Hủy phiếu bảo trì. Lý do: " + cancelReason.trim());

        if (mr.getAssignedTo() != null) {
            notificationService.create(
                    mr.getAssignedTo().getId(),
                    "Phiếu bảo trì bị hủy: " + mr.getTicketCode(),
                    "Lý do: " + cancelReason.trim(),
                    "MAINTENANCE",
                    mr.getId()
            );
        }
        return mr;
    }

    @Transactional
    public MaintenanceRequest resolve(UUID id) {
        MaintenanceRequest mr = getById(id);
        transitionValidator.validateTransition(mr.getStatus(), MaintenanceStatus.DONE);

        mr.setStatus(MaintenanceStatus.DONE);
        mr.setResolvedAt(LocalDateTime.now());
        mr = maintenanceRepository.save(mr);

        addNote(mr.getId(), null, "Xác nhận nghiệm thu hoàn thành phiếu bảo trì");

        notificationService.create(
                mr.getTenant().getId(),
                "Nghiệm thu thành công " + mr.getTicketCode(),
                "Phiếu bảo trì đã hoàn thành: " + mr.getTitle(),
                "MAINTENANCE",
                mr.getId()
        );
        return mr;
    }

    @Transactional
    public MaintenanceRequest updateStatus(UUID id, MaintenanceStatus newStatus) {
        MaintenanceRequest mr = getById(id);
        transitionValidator.validateTransition(mr.getStatus(), newStatus);
        mr.setStatus(newStatus);
        if (newStatus == MaintenanceStatus.DONE || newStatus == MaintenanceStatus.COMPLETED) {
            mr.setResolvedAt(LocalDateTime.now());
        }
        mr = maintenanceRepository.save(mr);
        addNote(mr.getId(), null, "Cập nhật trạng thái sang " + newStatus);
        return mr;
    }

    @Transactional
    public MaintenanceRequest addImage(UUID requestId, String imageUrl) {
        MaintenanceRequest req = getById(requestId);
        req.getImages().add(imageUrl);
        return maintenanceRepository.save(req);
    }

    @Transactional
    public MaintenanceRequest addCompletionImage(UUID requestId, String imageUrl) {
        MaintenanceRequest req = getById(requestId);
        req.getCompletionImages().add(imageUrl);
        return maintenanceRepository.save(req);
    }

    @Transactional
    public MaintenanceRequest confirmSlot(UUID id, String slot) {
        MaintenanceRequest mr = getById(id);
        mr.setConfirmedTimeSlot(slot);
        mr.setConfirmSlotByTenant(false);
        mr = maintenanceRepository.save(mr);
        addNote(mr.getId(), null, "Đề xuất/Xác nhận khung giờ làm việc: " + slot);
        notificationService.create(
                mr.getTenant().getId(),
                "Lịch bảo trì " + mr.getTicketCode(),
                "Kỹ thuật viên đề xuất khung giờ: " + slot + ". Vui lòng xác nhận.",
                "MAINTENANCE",
                mr.getId()
        );
        return mr;
    }

    @Transactional
    public MaintenanceRequest tenantConfirmSlot(UUID id, boolean confirm) {
        MaintenanceRequest mr = getById(id);
        mr.setConfirmSlotByTenant(confirm);
        mr = maintenanceRepository.save(mr);
        addNote(mr.getId(), mr.getTenant().getId(), confirm ? "Cư dân đã đồng ý khung giờ hẹn" : "Cư dân từ chối khung giờ hẹn");
        if (mr.getAssignedTo() != null) {
            notificationService.create(
                    mr.getAssignedTo().getId(),
                    "Phản hồi lịch hẹn " + mr.getTicketCode(),
                    confirm ? "Cư dân đã xác nhận lịch hẹn: " + mr.getConfirmedTimeSlot() : "Cư dân từ chối khung giờ: " + mr.getConfirmedTimeSlot(),
                    "MAINTENANCE",
                    mr.getId()
            );
        }
        return mr;
    }

    @Transactional
    public MaintenanceRequest complain(UUID id, String reason) {
        MaintenanceRequest mr = getById(id);
        mr.setIsComplained(true);
        mr.setComplainReason(reason);
        mr = maintenanceRepository.save(mr);
        addNote(mr.getId(), mr.getTenant().getId(), "Khiếu nại chi phí/từ chối nghiệm thu: " + reason);
        notificationService.create(
                mr.getRoom().getProperty().getOwner().getId(),
                "Khiếu nại bảo trì " + mr.getTicketCode(),
                "Cư dân " + mr.getTenant().getFullName() + " khiếu nại: " + reason,
                "MAINTENANCE",
                mr.getId()
        );
        return mr;
    }

    @Transactional
    public MaintenanceRequest updateSla(UUID id, LocalDateTime expectedResolvedAt) {
        MaintenanceRequest mr = getById(id);
        mr.setExpectedResolvedAt(expectedResolvedAt);
        mr = maintenanceRepository.save(mr);
        addNote(mr.getId(), null, "Cập nhật thời gian SLA dự kiến: " + expectedResolvedAt);
        return mr;
    }

    // Materials Management
    public List<MaintenanceMaterialResponse> listMaterials(UUID requestId) {
        return materialRepository.findByRequestIdOrderByCreatedAtAsc(requestId)
                .stream().map(MaintenanceMaterialResponse::from).toList();
    }

    @Transactional
    public MaintenanceMaterialResponse addMaterial(UUID requestId, CreateMaintenanceMaterial req) {
        MaintenanceRequest mr = getById(requestId);
        if (mr.getStatus() == MaintenanceStatus.COMPLETED || mr.getStatus() == MaintenanceStatus.DONE || mr.getStatus() == MaintenanceStatus.CANCELLED) {
            throw new BadRequestException("Không thể thêm vật tư vào phiếu đã kết thúc.");
        }
        BigDecimal total = req.getUnitPrice().multiply(BigDecimal.valueOf(req.getQuantity()));
        MaintenanceMaterial mat = MaintenanceMaterial.builder()
                .request(mr)
                .name(req.getName())
                .quantity(req.getQuantity())
                .unit(req.getUnit() != null ? req.getUnit() : "cái")
                .unitPrice(req.getUnitPrice())
                .totalPrice(total)
                .isFreeInContract(req.getIsFreeInContract() != null ? req.getIsFreeInContract() : false)
                .build();
        mat = materialRepository.save(mat);

        recalculateMaterialCost(mr);
        addNote(requestId, null, "Thêm vật tư: " + mat.getName() + " x" + mat.getQuantity() + " (" + total + " VNĐ)");
        return MaintenanceMaterialResponse.from(mat);
    }

    @Transactional
    public void deleteMaterial(UUID requestId, UUID materialId) {
        MaintenanceMaterial mat = materialRepository.findById(materialId)
                .orElseThrow(() -> new ResourceNotFoundException("MaintenanceMaterial", materialId));
        if (!mat.getRequest().getId().equals(requestId)) {
            throw new BadRequestException("Vật tư không thuộc phiếu bảo trì này.");
        }
        materialRepository.delete(mat);
        recalculateMaterialCost(mat.getRequest());
        addNote(requestId, null, "Xóa vật tư: " + mat.getName());
    }

    private void recalculateMaterialCost(MaintenanceRequest mr) {
        List<MaintenanceMaterial> list = materialRepository.findByRequestIdOrderByCreatedAtAsc(mr.getId());
        BigDecimal sum = list.stream()
                .filter(m -> !Boolean.TRUE.equals(m.getIsFreeInContract()))
                .map(MaintenanceMaterial::getTotalPrice)
                .reduce(BigDecimal.ZERO, BigDecimal::add);
        mr.setMaterialCost(sum);
        maintenanceRepository.save(mr);
    }

    // Notes / Timeline Logs
    public List<MaintenanceNoteResponse> listNotes(UUID requestId) {
        return noteRepository.findByRequestIdOrderByCreatedAtDesc(requestId)
                .stream().map(MaintenanceNoteResponse::from).toList();
    }

    @Transactional
    public MaintenanceNoteResponse addNote(UUID requestId, UUID actorId, String text) {
        MaintenanceRequest mr = getById(requestId);
        User actor = actorId != null ? userRepository.findById(actorId).orElse(null) : null;
        MaintenanceNote note = MaintenanceNote.builder()
                .request(mr)
                .actor(actor)
                .status(mr.getStatus())
                .note(text)
                .build();
        note = noteRepository.save(note);
        return MaintenanceNoteResponse.from(note);
    }
}
