package chez1s.htrbackend.controller;

import chez1s.htrbackend.domain.entity.MaintenanceRequest;
import chez1s.htrbackend.dto.request.CreateMaintenanceRequest;
import chez1s.htrbackend.security.JwtTokenProvider;
import chez1s.htrbackend.service.MaintenanceService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/maintenance")
@RequiredArgsConstructor
public class MaintenanceController {

    private final MaintenanceService maintenanceService;
    private final JwtTokenProvider jwtTokenProvider;

    @GetMapping
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<List<MaintenanceRequest>> listAll() {
        return ResponseEntity.ok(maintenanceService.listAll());
    }

    @GetMapping("/mine")
    @PreAuthorize("hasRole('TENANT')")
    public ResponseEntity<List<MaintenanceRequest>> listMine(@RequestHeader("Authorization") String authHeader) {
        UUID tenantId = jwtTokenProvider.getUserId(authHeader.replace("Bearer ", ""));
        return ResponseEntity.ok(maintenanceService.listByTenant(tenantId));
    }

    @GetMapping("/assigned")
    @PreAuthorize("hasRole('TECHNICIAN')")
    public ResponseEntity<List<MaintenanceRequest>> listAssigned(@RequestHeader("Authorization") String authHeader) {
        UUID techId = jwtTokenProvider.getUserId(authHeader.replace("Bearer ", ""));
        return ResponseEntity.ok(maintenanceService.listByTechnician(techId));
    }

    @GetMapping("/{id}")
    public ResponseEntity<MaintenanceRequest> getById(@PathVariable UUID id) {
        return ResponseEntity.ok(maintenanceService.getById(id));
    }

    @PostMapping
    @PreAuthorize("hasRole('TENANT')")
    public ResponseEntity<MaintenanceRequest> create(@RequestHeader("Authorization") String authHeader,
                                                     @Valid @RequestBody CreateMaintenanceRequest req) {
        UUID tenantId = jwtTokenProvider.getUserId(authHeader.replace("Bearer ", ""));
        return ResponseEntity.status(HttpStatus.CREATED).body(maintenanceService.create(tenantId, req));
    }

    @PostMapping("/{id}/assign")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<MaintenanceRequest> assign(@PathVariable UUID id, @RequestParam UUID technicianId) {
        return ResponseEntity.ok(maintenanceService.assign(id, technicianId));
    }

    @PostMapping("/{id}/resolve")
    @PreAuthorize("hasAnyRole('ADMIN','TECHNICIAN')")
    public ResponseEntity<MaintenanceRequest> resolve(@PathVariable UUID id) {
        return ResponseEntity.ok(maintenanceService.resolve(id));
    }
}
