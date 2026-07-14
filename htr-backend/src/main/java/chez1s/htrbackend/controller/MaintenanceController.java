package chez1s.htrbackend.controller;

import chez1s.htrbackend.domain.entity.MaintenanceRequest;
import chez1s.htrbackend.domain.enums.MaintenanceStatus;
import chez1s.htrbackend.dto.request.CreateMaintenanceMaterial;
import chez1s.htrbackend.dto.request.CreateMaintenanceRequest;
import chez1s.htrbackend.dto.response.MaintenanceMaterialResponse;
import chez1s.htrbackend.dto.response.MaintenanceNoteResponse;
import chez1s.htrbackend.dto.response.MaintenanceRequestResponse;
import chez1s.htrbackend.dto.response.PageResponse;
import chez1s.htrbackend.service.MaintenanceService;
import chez1s.htrbackend.service.StorageService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
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
@RequiredArgsConstructor
public class MaintenanceController {

    private final MaintenanceService maintenanceService;
    private final StorageService storageService;

    @GetMapping
    @PreAuthorize("hasRole('ADMIN')")
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
        return ResponseEntity.ok(maintenanceService.listByTechnician(techId).stream().map(MaintenanceRequestResponse::from).toList());
    }

    @GetMapping("/{id}")
    public ResponseEntity<MaintenanceRequestResponse> getById(@PathVariable UUID id) {
        return ResponseEntity.ok(MaintenanceRequestResponse.from(maintenanceService.getById(id)));
    }

    @PostMapping
    @PreAuthorize("hasAnyRole('TENANT','ADMIN')")
    public ResponseEntity<MaintenanceRequestResponse> create(Authentication auth,
                                                             @Valid @RequestBody CreateMaintenanceRequest req) {
        UUID tenantId = (UUID) auth.getPrincipal();
        return ResponseEntity.status(HttpStatus.CREATED).body(MaintenanceRequestResponse.from(maintenanceService.create(tenantId, req)));
    }

    @PostMapping("/{id}/assign")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<MaintenanceRequestResponse> assign(@PathVariable UUID id, @RequestParam UUID technicianId) {
        return ResponseEntity.ok(MaintenanceRequestResponse.from(maintenanceService.assign(id, technicianId)));
    }

    @RequestMapping(value = "/{id}/start", method = {RequestMethod.POST, RequestMethod.PUT})
    @PreAuthorize("hasAnyRole('ADMIN','TECHNICIAN')")
    public ResponseEntity<MaintenanceRequestResponse> startWork(@PathVariable UUID id) {
        return ResponseEntity.ok(MaintenanceRequestResponse.from(maintenanceService.startWork(id)));
    }

    @PostMapping("/{id}/submit-review")
    @PreAuthorize("hasAnyRole('ADMIN','TECHNICIAN')")
    public ResponseEntity<MaintenanceRequestResponse> submitWork(@PathVariable UUID id,
                                                                 @RequestParam(required = false) BigDecimal materialCost) {
        return ResponseEntity.ok(MaintenanceRequestResponse.from(maintenanceService.submitWork(id, materialCost)));
    }

    @PostMapping("/{id}/cancel")
    @PreAuthorize("hasAnyRole('ADMIN','TENANT')")
    public ResponseEntity<MaintenanceRequestResponse> cancel(@PathVariable UUID id,
                                                             @RequestParam("reason") String reason) {
        return ResponseEntity.ok(MaintenanceRequestResponse.from(maintenanceService.cancel(id, reason)));
    }

    @PostMapping("/{id}/update-status")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<MaintenanceRequestResponse> updateStatus(@PathVariable UUID id,
                                                                   @RequestParam("status") MaintenanceStatus status) {
        return ResponseEntity.ok(MaintenanceRequestResponse.from(maintenanceService.updateStatus(id, status)));
    }

    @PostMapping("/{id}/resolve")
    @PreAuthorize("hasAnyRole('ADMIN','TENANT')")
    public ResponseEntity<MaintenanceRequestResponse> resolve(@PathVariable UUID id) {
        return ResponseEntity.ok(MaintenanceRequestResponse.from(maintenanceService.resolve(id)));
    }

    @PatchMapping("/{id}/sla")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<MaintenanceRequestResponse> updateSla(@PathVariable UUID id,
                                                                @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime expectedResolvedAt) {
        return ResponseEntity.ok(MaintenanceRequestResponse.from(maintenanceService.updateSla(id, expectedResolvedAt)));
    }

    @PostMapping("/{id}/confirm-slot")
    @PreAuthorize("hasAnyRole('ADMIN','TECHNICIAN')")
    public ResponseEntity<MaintenanceRequestResponse> confirmSlot(@PathVariable UUID id,
                                                                  @RequestParam("slot") String slot) {
        return ResponseEntity.ok(MaintenanceRequestResponse.from(maintenanceService.confirmSlot(id, slot)));
    }

    @PostMapping("/{id}/tenant-confirm-slot")
    @PreAuthorize("hasRole('TENANT')")
    public ResponseEntity<MaintenanceRequestResponse> tenantConfirmSlot(@PathVariable UUID id,
                                                                        @RequestParam("confirm") boolean confirm) {
        return ResponseEntity.ok(MaintenanceRequestResponse.from(maintenanceService.tenantConfirmSlot(id, confirm)));
    }

    @PostMapping("/{id}/complain")
    @PreAuthorize("hasRole('TENANT')")
    public ResponseEntity<MaintenanceRequestResponse> complain(@PathVariable UUID id,
                                                               @RequestParam("reason") String reason) {
        return ResponseEntity.ok(MaintenanceRequestResponse.from(maintenanceService.complain(id, reason)));
    }

    @PostMapping("/{id}/pay-material")
    @PreAuthorize("hasAnyRole('TENANT','ADMIN')")
    public ResponseEntity<MaintenanceRequestResponse> payMaterial(Authentication auth, @PathVariable UUID id) {
        return ResponseEntity.ok(MaintenanceRequestResponse.from(maintenanceService.payMaterial(id, (UUID) auth.getPrincipal())));
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

    @PostMapping(value = "/{id}/completion-images", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    @PreAuthorize("hasAnyRole('ADMIN','TECHNICIAN')")
    public ResponseEntity<MaintenanceRequestResponse> addCompletionImages(
            @PathVariable UUID id, @RequestParam("images") List<MultipartFile> images) {
        if (images == null || images.isEmpty()) {
            throw new chez1s.htrbackend.exception.BadRequestException("Vui lòng chọn ít nhất một ảnh hoàn thành.");
        }
        for (MultipartFile image : images) {
            if (image.getContentType() == null || !image.getContentType().startsWith("image/")) {
                throw new chez1s.htrbackend.exception.BadRequestException("Minh chứng hoàn thành chỉ chấp nhận tệp hình ảnh.");
            }
            String url = storageService.upload("maintenance/" + id + "/completion", image);
            maintenanceService.addCompletionImage(id, url);
        }
        return ResponseEntity.ok(MaintenanceRequestResponse.from(maintenanceService.getById(id)));
    }

    @PostMapping(value = "/with-images", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    @PreAuthorize("hasAnyRole('TENANT','ADMIN')")
    public ResponseEntity<MaintenanceRequestResponse> createWithImages(
            Authentication auth,
            @RequestParam("title") String title,
            @RequestParam(value = "description", required = false) String description,
            @RequestParam(value = "priority", required = false) chez1s.htrbackend.domain.enums.MaintenancePriority priority,
            @RequestParam(value = "category", required = false) chez1s.htrbackend.domain.enums.MaintenanceCategory category,
            @RequestParam(value = "preferredTimeSlots", required = false) List<String> preferredTimeSlots,
            @RequestParam(value = "images", required = false) List<MultipartFile> images,
            @RequestParam(value = "video", required = false) MultipartFile video) {
        UUID tenantId = (UUID) auth.getPrincipal();
        CreateMaintenanceRequest req = new CreateMaintenanceRequest();
        req.setTitle(title);
        req.setDescription(description);
        if (priority != null) req.setPriority(priority);
        if (category != null) req.setCategory(category);
        if (preferredTimeSlots != null) req.setPreferredTimeSlots(preferredTimeSlots);
        MaintenanceRequest created = maintenanceService.create(tenantId, req);
        if (images != null && !images.isEmpty()) {
            for (MultipartFile img : images) {
                if (img.getContentType() == null || !img.getContentType().startsWith("image/")) {
                    throw new chez1s.htrbackend.exception.BadRequestException("Tệp trong danh sách hình ảnh không đúng định dạng.");
                }
                String url = storageService.upload("maintenance/" + created.getId(), img);
                maintenanceService.addImage(created.getId(), url);
            }
        }
        if (video != null && !video.isEmpty()) {
            if (video.getContentType() == null || !video.getContentType().startsWith("video/")) {
                throw new chez1s.htrbackend.exception.BadRequestException("Tệp video không đúng định dạng.");
            }
            String url = storageService.upload("maintenance/" + created.getId() + "/video", video);
            maintenanceService.setAttachmentVideo(created.getId(), url);
        }
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(MaintenanceRequestResponse.from(maintenanceService.getById(created.getId())));
    }
}
