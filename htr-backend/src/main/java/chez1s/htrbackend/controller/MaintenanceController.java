package chez1s.htrbackend.controller;

import chez1s.htrbackend.domain.entity.Contract;
import chez1s.htrbackend.domain.entity.MaintenanceRequest;
import chez1s.htrbackend.domain.enums.ContractStatus;
import chez1s.htrbackend.domain.enums.MaintenanceStatus;
import chez1s.htrbackend.domain.enums.UserRole;
import chez1s.htrbackend.domain.repository.ContractRepository;
import chez1s.htrbackend.dto.request.CreateMaintenanceMaterial;
import chez1s.htrbackend.dto.request.CreateMaintenanceRequest;
import chez1s.htrbackend.dto.response.MaintenanceMaterialResponse;
import chez1s.htrbackend.dto.response.MaintenanceNoteResponse;
import chez1s.htrbackend.dto.response.MaintenanceRequestResponse;
import chez1s.htrbackend.dto.response.PageResponse;
import chez1s.htrbackend.exception.BadRequestException;
import chez1s.htrbackend.exception.BusinessException;
import chez1s.htrbackend.security.ActorContext;
import chez1s.htrbackend.security.OwnerScopeResolver;
import chez1s.htrbackend.service.MaintenanceService;
import chez1s.htrbackend.service.RoomService;
import chez1s.htrbackend.service.StorageService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.data.web.PageableDefault;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/maintenance")
public class MaintenanceController {

    private final MaintenanceService maintenanceService;
    private final StorageService storageService;
    private final chez1s.htrbackend.service.UploadBatchService uploadBatchService;
    private final RoomService roomService;
    private final OwnerScopeResolver ownerScopeResolver;
    private final ContractRepository contractRepository;

    @Autowired
    public MaintenanceController(MaintenanceService maintenanceService, StorageService storageService,
                                 chez1s.htrbackend.service.UploadBatchService uploadBatchService,
                                 RoomService roomService, OwnerScopeResolver ownerScopeResolver,
                                 ContractRepository contractRepository) {
        this.maintenanceService = maintenanceService;
        this.storageService = storageService;
        this.uploadBatchService = uploadBatchService;
        this.roomService = roomService;
        this.ownerScopeResolver = ownerScopeResolver;
        this.contractRepository = contractRepository;
    }

    public MaintenanceController(MaintenanceService maintenanceService, StorageService storageService) {
        this(maintenanceService, storageService, null, null, null, null);
    }

    public MaintenanceController(MaintenanceService maintenanceService, StorageService storageService,
                                 RoomService roomService, OwnerScopeResolver ownerScopeResolver,
                                 ContractRepository contractRepository) {
        this(maintenanceService, storageService, null, roomService, ownerScopeResolver, contractRepository);
    }

    @GetMapping
    @PreAuthorize("hasAnyRole('ADMIN','PLATFORM_ADMIN','LANDLORD_ADMIN')")
    public ResponseEntity<PageResponse<MaintenanceRequestResponse>> listAll(
            Authentication auth,
            @RequestParam(required = false) List<MaintenanceStatus> statuses,
            @PageableDefault(size = 20, sort = "createdAt", direction = Sort.Direction.DESC) Pageable pageable) {
        UUID ownerId = (UUID) auth.getPrincipal();
        if (statuses != null && !statuses.isEmpty()) {
            return ResponseEntity.ok(maintenanceService.listFiltered(ownerId, statuses, pageable));
        }
        return ResponseEntity.ok(maintenanceService.listAllByOwner(ownerId, pageable));
    }

    @GetMapping("/mine")
    @PreAuthorize("hasRole('TENANT')")
    public ResponseEntity<PageResponse<MaintenanceRequestResponse>> listMine(
            Authentication auth,
            @PageableDefault(size = 20, sort = "createdAt", direction = Sort.Direction.DESC) Pageable pageable) {
        UUID tenantId = (UUID) auth.getPrincipal();
        return ResponseEntity.ok(maintenanceService.listByTenant(tenantId, pageable));
    }

    @GetMapping("/assigned")
    @PreAuthorize("hasRole('TECHNICIAN')")
    public ResponseEntity<List<MaintenanceRequestResponse>> listAssigned(Authentication auth) {
        UUID techId = (UUID) auth.getPrincipal();
        return ResponseEntity.ok(maintenanceService.listByTechnician(techId));
    }

    @GetMapping("/{id}")
    @PreAuthorize("hasAnyRole('TENANT','TECHNICIAN','ADMIN','PLATFORM_ADMIN','LANDLORD_ADMIN')")
    public ResponseEntity<MaintenanceRequestResponse> getById(@PathVariable UUID id) {
        return ResponseEntity.ok(maintenanceService.getResponseById(id));
    }

    @PostMapping
    @PreAuthorize("hasAnyRole('TENANT','ADMIN','PLATFORM_ADMIN','LANDLORD_ADMIN')")
    public ResponseEntity<MaintenanceRequestResponse> create(Authentication auth,
                                                             @Valid @RequestBody CreateMaintenanceRequest req) {
        UUID tenantId = resolveTenantId(auth, req.getRoomId());
        return ResponseEntity.status(HttpStatus.CREATED).body(responseOf(maintenanceService.create(tenantId, req)));
    }

    /**
     * Resolves which tenant a maintenance ticket should belong to.
     * Tenants always create tickets for themselves (unchanged behavior).
     * Admin/platform-admin/landlord-admin must pick a room in their owner scope; the tenant is
     * derived from that room's current active contract, never from the caller's own id.
     */
    private UUID resolveTenantId(Authentication auth, UUID roomId) {
        ActorContext actor = ActorContext.require(auth);
        if (actor.role() == UserRole.TENANT) {
            if (roomId != null) {
                requireTenantRoomAccess(actor.userId(), roomId);
            }
            return actor.userId();
        }
        if (roomId == null) {
            throw new BadRequestException("Vui lòng chọn phòng để tạo yêu cầu bảo trì hộ khách thuê");
        }
        requireRoomAccess(actor, roomId);
        Contract activeContract = contractRepository.findFirstByRoomIdAndStatusOrderByCreatedAtDesc(roomId, ContractStatus.ACTIVE)
                .orElseThrow(() -> new BadRequestException("Phòng này chưa có hợp đồng đang hoạt động, không thể tạo yêu cầu bảo trì hộ khách thuê"));
        return activeContract.getTenant().getId();
    }

    private void requireTenantRoomAccess(UUID tenantId, UUID roomId) {
        Contract activeContract = contractRepository.findFirstByTenantIdAndStatusOrderByCreatedAtDesc(tenantId, ContractStatus.ACTIVE)
                .orElseThrow(() -> new BusinessException("Bạn chưa có hợp đồng đang hoạt động"));
        if (activeContract.getRoom() == null || !roomId.equals(activeContract.getRoom().getId())) {
            throw new BusinessException("Room is outside the tenant active contract");
        }
    }

    private void requireRoomAccess(ActorContext actor, UUID roomId) {
        if (actor.isPlatformAdmin()) return;
        var room = roomService.getById(roomId);
        if (!room.getProperty().getOwner().getId().equals(ownerScopeResolver.requireOwnerId(actor))) {
            throw new BusinessException("Room is outside the actor owner scope");
        }
    }

    @PostMapping("/{id}/assign")
    @PreAuthorize("hasAnyRole('ADMIN','PLATFORM_ADMIN','LANDLORD_ADMIN')")
    public ResponseEntity<MaintenanceRequestResponse> assign(@PathVariable UUID id, @RequestParam UUID technicianId) {
        return ResponseEntity.ok(responseOf(maintenanceService.assign(id, technicianId)));
    }

    @RequestMapping(value = "/{id}/start", method = {RequestMethod.POST, RequestMethod.PUT})
    @PreAuthorize("hasAnyRole('ADMIN','TECHNICIAN')")
    public ResponseEntity<MaintenanceRequestResponse> startWork(@PathVariable UUID id) {
        return ResponseEntity.ok(responseOf(maintenanceService.startWork(id)));
    }

    @PostMapping("/{id}/submit-review")
    @PreAuthorize("hasAnyRole('ADMIN','TECHNICIAN')")
    public ResponseEntity<MaintenanceRequestResponse> submitWork(@PathVariable UUID id,
                                                                 @RequestParam(required = false) BigDecimal materialCost) {
        return ResponseEntity.ok(responseOf(maintenanceService.submitWork(id, materialCost)));
    }

    @PostMapping("/{id}/cancel")
    @PreAuthorize("hasAnyRole('ADMIN','TENANT')")
    public ResponseEntity<MaintenanceRequestResponse> cancel(@PathVariable UUID id,
                                                             @RequestParam("reason") String reason) {
        return ResponseEntity.ok(responseOf(maintenanceService.cancel(id, reason)));
    }

    @PostMapping("/{id}/update-status")
    @PreAuthorize("hasAnyRole('ADMIN','PLATFORM_ADMIN','LANDLORD_ADMIN')")
    public ResponseEntity<MaintenanceRequestResponse> updateStatus(@PathVariable UUID id,
                                                                   @RequestParam("status") MaintenanceStatus status) {
        return ResponseEntity.ok(responseOf(maintenanceService.updateStatus(id, status)));
    }

    @PostMapping("/{id}/resolve")
    @PreAuthorize("hasAnyRole('ADMIN','TENANT')")
    public ResponseEntity<MaintenanceRequestResponse> resolve(@PathVariable UUID id) {
        return ResponseEntity.ok(responseOf(maintenanceService.resolve(id)));
    }

    @PatchMapping("/{id}/sla")
    @PreAuthorize("hasAnyRole('ADMIN','PLATFORM_ADMIN','LANDLORD_ADMIN')")
    public ResponseEntity<MaintenanceRequestResponse> updateSla(@PathVariable UUID id,
                                                                @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime expectedResolvedAt) {
        return ResponseEntity.ok(responseOf(maintenanceService.updateSla(id, expectedResolvedAt)));
    }

    @PostMapping("/{id}/confirm-slot")
    @PreAuthorize("hasAnyRole('ADMIN','TECHNICIAN')")
    public ResponseEntity<MaintenanceRequestResponse> confirmSlot(@PathVariable UUID id,
                                                                  @RequestParam("slot") String slot) {
        return ResponseEntity.ok(responseOf(maintenanceService.confirmSlot(id, slot)));
    }

    @PostMapping("/{id}/tenant-confirm-slot")
    @PreAuthorize("hasRole('TENANT')")
    public ResponseEntity<MaintenanceRequestResponse> tenantConfirmSlot(@PathVariable UUID id,
                                                                        @RequestParam("confirm") boolean confirm) {
        return ResponseEntity.ok(responseOf(maintenanceService.tenantConfirmSlot(id, confirm)));
    }

    @PostMapping("/{id}/complain")
    @PreAuthorize("hasRole('TENANT')")
    public ResponseEntity<MaintenanceRequestResponse> complain(@PathVariable UUID id,
                                                               @RequestParam("reason") String reason) {
        return ResponseEntity.ok(responseOf(maintenanceService.complain(id, reason)));
    }

    @PostMapping("/{id}/pay-material")
    @PreAuthorize("hasAnyRole('TENANT','ADMIN','PLATFORM_ADMIN','LANDLORD_ADMIN')")
    public ResponseEntity<MaintenanceRequestResponse> payMaterial(Authentication auth, @PathVariable UUID id) {
        return ResponseEntity.ok(responseOf(maintenanceService.payMaterial(id, (UUID) auth.getPrincipal())));
    }

    // Materials endpoints
    @GetMapping("/{id}/materials")
    public ResponseEntity<List<MaintenanceMaterialResponse>> listMaterials(@PathVariable UUID id) {
        return ResponseEntity.ok(maintenanceService.listMaterials(id));
    }

    @PostMapping("/{id}/materials")
    @PreAuthorize("hasAnyRole('ADMIN','TECHNICIAN')")
    public ResponseEntity<MaintenanceMaterialResponse> addMaterial(@PathVariable UUID id,
                                                                   @Valid @RequestBody CreateMaintenanceMaterial req) {
        return ResponseEntity.status(HttpStatus.CREATED).body(maintenanceService.addMaterial(id, req));
    }

    @DeleteMapping("/{id}/materials/{materialId}")
    @PreAuthorize("hasAnyRole('ADMIN','TECHNICIAN')")
    public ResponseEntity<Void> deleteMaterial(@PathVariable UUID id, @PathVariable UUID materialId) {
        maintenanceService.deleteMaterial(id, materialId);
        return ResponseEntity.noContent().build();
    }

    // Notes endpoints
    @GetMapping("/{id}/notes")
    public ResponseEntity<List<MaintenanceNoteResponse>> listNotes(@PathVariable UUID id) {
        return ResponseEntity.ok(maintenanceService.listNotes(id));
    }

    @PostMapping("/{id}/notes")
    public ResponseEntity<MaintenanceNoteResponse> addNote(Authentication auth,
                                                           @PathVariable UUID id,
                                                           @RequestParam("note") String note) {
        UUID actorId = (auth != null && auth.getPrincipal() instanceof UUID) ? (UUID) auth.getPrincipal() : null;
        return ResponseEntity.ok(maintenanceService.addNote(id, actorId, note));
    }

    public ResponseEntity<MaintenanceRequestResponse> addCompletionImages(UUID id, List<? extends MultipartFile> images) {
        return addCompletionImages(id, null, new java.util.ArrayList<>(images), null);
    }

    public ResponseEntity<MaintenanceRequestResponse> addCompletionImages(UUID id, List<? extends MultipartFile> images, MultipartFile video) {
        return addCompletionImages(id, null, new java.util.ArrayList<>(images), video);
    }

    @PostMapping(value = "/{id}/completion-images", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    @PreAuthorize("hasAnyRole('ADMIN','TECHNICIAN')")
    public ResponseEntity<MaintenanceRequestResponse> addCompletionImages(
            @PathVariable UUID id,
            @RequestHeader(value = "Idempotency-Key", required = false) String idempotencyKey,
            @RequestParam("images") List<MultipartFile> images,
            @RequestParam(value = "video", required = false) MultipartFile video) {
        if (images == null || images.isEmpty()) {
            throw new chez1s.htrbackend.exception.BadRequestException("Vui lòng chọn ít nhất một ảnh hoàn thành.");
        }
        for (MultipartFile image : images) {
            if (!isImageFile(image)) {
                throw new chez1s.htrbackend.exception.BadRequestException("Minh chứng hoàn thành chỉ chấp nhận tệp hình ảnh.");
            }
        }
        if (video != null && !video.isEmpty() && !isVideoFile(video)) {
            throw new chez1s.htrbackend.exception.BadRequestException("Tệp video không đúng định dạng.");
        }
        // Upload all files before persisting anything, so a mid-batch failure
        // leaves no orphaned completion-image record.
        var batch = uploadBatchService == null ? null : uploadBatchService.begin(idempotencyKey != null ? idempotencyKey : UUID.randomUUID().toString(), "MAINTENANCE_COMPLETION", id);
        List<String> urls = new java.util.ArrayList<>();
        String videoUrl = null;
        try {
            for (MultipartFile image : images) {
                String url = storageService.upload("maintenance/" + id + "/completion", image);
                urls.add(url);
                if (uploadBatchService != null) uploadBatchService.record(batch, url, image.getContentType(), image.getSize());
            }
            if (video != null && !video.isEmpty()) {
                videoUrl = storageService.upload("maintenance/" + id + "/completion/video", video);
                if (uploadBatchService != null) uploadBatchService.record(batch, videoUrl, video.getContentType(), video.getSize());
            }
            maintenanceService.addCompletionImages(id, urls);
            if (videoUrl != null) maintenanceService.setCompletionVideo(id, videoUrl);
            if (uploadBatchService != null) uploadBatchService.complete(batch);
            return ResponseEntity.ok(responseOf(maintenanceService.getById(id)));
        } catch (RuntimeException exception) {
            urls.forEach(storageService::delete);
            if (videoUrl != null) storageService.delete(videoUrl);
            if (uploadBatchService != null) uploadBatchService.requireCleanup(batch);
            throw exception;
        }
    }

    public ResponseEntity<MaintenanceRequestResponse> createWithImages(
            Authentication auth, String title, String description,
            chez1s.htrbackend.domain.enums.MaintenancePriority priority,
            chez1s.htrbackend.domain.enums.MaintenanceCategory category,
            List<String> preferredTimeSlots, List<MultipartFile> images, MultipartFile video) {
        return createWithImages(auth, null, null, title, description, priority, category, preferredTimeSlots, images, video);
    }

    @PostMapping(value = "/with-images", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    @PreAuthorize("hasAnyRole('TENANT','ADMIN','PLATFORM_ADMIN','LANDLORD_ADMIN')")
    public ResponseEntity<MaintenanceRequestResponse> createWithImages(
            Authentication auth,
            @RequestHeader(value = "Idempotency-Key", required = false) String idempotencyKey,
            @RequestParam(value = "roomId", required = false) UUID roomId,
            @RequestParam("title") String title,
            @RequestParam(value = "description", required = false) String description,
            @RequestParam(value = "priority", required = false) chez1s.htrbackend.domain.enums.MaintenancePriority priority,
            @RequestParam(value = "category", required = false) chez1s.htrbackend.domain.enums.MaintenanceCategory category,
            @RequestParam(value = "preferredTimeSlots", required = false) List<String> preferredTimeSlots,
            @RequestParam(value = "images", required = false) List<MultipartFile> images,
            @RequestParam(value = "video", required = false) MultipartFile video) {
        UUID tenantId = resolveTenantId(auth, roomId);

        if (images != null) {
            for (MultipartFile img : images) {
                if (!isImageFile(img)) {
                    throw new chez1s.htrbackend.exception.BadRequestException("Tệp trong danh sách hình ảnh không đúng định dạng.");
                }
            }
        }
        if (video != null && !video.isEmpty() && !isVideoFile(video)) {
            throw new chez1s.htrbackend.exception.BadRequestException("Tệp video không đúng định dạng.");
        }

        // Upload everything first — the ticket is only created once all
        // attachments have been stored successfully, so a failed upload
        // never leaves behind a ticket with missing attachments.
        String tempFolder = "maintenance/pending-" + UUID.randomUUID();
        var batch = uploadBatchService == null ? null : uploadBatchService.begin(idempotencyKey != null ? idempotencyKey : UUID.randomUUID().toString(), "MAINTENANCE_REQUEST", null);
        List<String> imageUrls = new java.util.ArrayList<>();
        String videoUrl = null;
        try {
            if (images != null) {
                for (MultipartFile img : images) {
                    String url = storageService.upload(tempFolder, img);
                    imageUrls.add(url);
                    if (uploadBatchService != null) uploadBatchService.record(batch, url, img.getContentType(), img.getSize());
                }
            }
            if (video != null && !video.isEmpty()) {
                videoUrl = storageService.upload(tempFolder + "/video", video);
                if (uploadBatchService != null) uploadBatchService.record(batch, videoUrl, video.getContentType(), video.getSize());
            }

            CreateMaintenanceRequest req = new CreateMaintenanceRequest();
            req.setRoomId(roomId);
            req.setTitle(title);
            req.setDescription(description);
            if (priority != null) req.setPriority(priority);
            if (category != null) req.setCategory(category);
            if (preferredTimeSlots != null) req.setPreferredTimeSlots(preferredTimeSlots);
            req.setImages(imageUrls);
            req.setAttachmentVideo(videoUrl);

            MaintenanceRequest created = maintenanceService.create(tenantId, req);
            if (batch != null) {
                batch.setDomainId(created.getId());
                uploadBatchService.complete(batch);
            }
            return ResponseEntity.status(HttpStatus.CREATED)
                    .body(responseOf(maintenanceService.getById(created.getId())));
        } catch (RuntimeException exception) {
            imageUrls.forEach(storageService::delete);
            if (videoUrl != null) storageService.delete(videoUrl);
            if (uploadBatchService != null) uploadBatchService.requireCleanup(batch);
            throw exception;
        }
    }

    private static final List<String> IMAGE_EXTENSIONS = List.of(".jpg", ".jpeg", ".png", ".webp", ".heic", ".heif", ".gif", ".bmp");
    private static final List<String> VIDEO_EXTENSIONS = List.of(".mp4", ".mov", ".webm", ".avi", ".mkv", ".3gp");

    private boolean isImageFile(MultipartFile file) {
        String contentType = file.getContentType();
        if (contentType != null && contentType.startsWith("image/")) {
            return true;
        }
        return hasExtension(file.getOriginalFilename(), IMAGE_EXTENSIONS);
    }

    private boolean isVideoFile(MultipartFile file) {
        String contentType = file.getContentType();
        if (contentType != null && contentType.startsWith("video/")) {
            return true;
        }
        return hasExtension(file.getOriginalFilename(), VIDEO_EXTENSIONS);
    }

    private boolean hasExtension(String filename, List<String> extensions) {
        if (filename == null) return false;
        String lower = filename.toLowerCase();
        return extensions.stream().anyMatch(lower::endsWith);
    }

    private MaintenanceRequestResponse responseOf(MaintenanceRequest request) {
        return maintenanceService.getResponseById(request.getId());
    }
}
