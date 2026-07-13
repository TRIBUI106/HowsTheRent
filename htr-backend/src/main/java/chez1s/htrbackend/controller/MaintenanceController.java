package chez1s.htrbackend.controller;

import chez1s.htrbackend.domain.entity.MaintenanceRequest;
import chez1s.htrbackend.domain.enums.MaintenanceStatus;
import chez1s.htrbackend.dto.request.CreateMaintenanceRequest;
import chez1s.htrbackend.dto.response.MaintenanceRequestResponse;
import chez1s.htrbackend.dto.response.PageResponse;
import chez1s.htrbackend.service.MaintenanceService;
import chez1s.htrbackend.service.StorageService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.data.web.PageableDefault;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.math.BigDecimal;
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
            @PageableDefault(size = 20, sort = "createdAt", direction = Sort.Direction.DESC) Pageable pageable) {
        UUID ownerId = (UUID) auth.getPrincipal();
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

    @PostMapping("/{id}/start")
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
    @PreAuthorize("hasAnyRole('ADMIN','TECHNICIAN')")
    public ResponseEntity<MaintenanceRequestResponse> resolve(@PathVariable UUID id) {
        return ResponseEntity.ok(MaintenanceRequestResponse.from(maintenanceService.resolve(id)));
    }

    @PostMapping(value = "/with-images", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    @PreAuthorize("hasAnyRole('TENANT','ADMIN')")
    public ResponseEntity<MaintenanceRequestResponse> createWithImages(
            Authentication auth,
            @RequestParam("title") String title,
            @RequestParam(value = "description", required = false) String description,
            @RequestParam(value = "images", required = false) List<MultipartFile> images) {
        UUID tenantId = (UUID) auth.getPrincipal();
        CreateMaintenanceRequest req = new CreateMaintenanceRequest();
        req.setTitle(title);
        req.setDescription(description);
        MaintenanceRequest created = maintenanceService.create(tenantId, req);
        if (images != null && !images.isEmpty()) {
            for (MultipartFile img : images) {
                String url = storageService.upload("maintenance/" + created.getId(), img);
                maintenanceService.addImage(created.getId(), url);
            }
        }
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(MaintenanceRequestResponse.from(maintenanceService.getById(created.getId())));
    }
}
