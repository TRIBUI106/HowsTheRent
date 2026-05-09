package chez1s.htrbackend.controller;

import chez1s.htrbackend.dto.request.CreateMaintenanceRequest;
import chez1s.htrbackend.dto.response.MaintenanceRequestResponse;
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
    public ResponseEntity<List<MaintenanceRequestResponse>> listAll() {
        return ResponseEntity.ok(maintenanceService.listAll().stream().map(MaintenanceRequestResponse::from).toList());
    }

    @GetMapping("/mine")
    @PreAuthorize("hasRole('TENANT')")
    public ResponseEntity<List<MaintenanceRequestResponse>> listMine(@RequestHeader("Authorization") String authHeader) {
        UUID tenantId = jwtTokenProvider.getUserId(authHeader.replace("Bearer ", ""));
        return ResponseEntity.ok(maintenanceService.listByTenant(tenantId).stream().map(MaintenanceRequestResponse::from).toList());
    }

    @GetMapping("/assigned")
    @PreAuthorize("hasRole('TECHNICIAN')")
    public ResponseEntity<List<MaintenanceRequestResponse>> listAssigned(@RequestHeader("Authorization") String authHeader) {
        UUID techId = jwtTokenProvider.getUserId(authHeader.replace("Bearer ", ""));
        return ResponseEntity.ok(maintenanceService.listByTechnician(techId).stream().map(MaintenanceRequestResponse::from).toList());
    }

    @GetMapping("/{id}")
    public ResponseEntity<MaintenanceRequestResponse> getById(@PathVariable UUID id) {
        return ResponseEntity.ok(MaintenanceRequestResponse.from(maintenanceService.getById(id)));
    }

    @PostMapping
    @PreAuthorize("hasRole('TENANT')")
    public ResponseEntity<MaintenanceRequestResponse> create(@RequestHeader("Authorization") String authHeader,
                                                             @Valid @RequestBody CreateMaintenanceRequest req) {
        UUID tenantId = jwtTokenProvider.getUserId(authHeader.replace("Bearer ", ""));
        return ResponseEntity.status(HttpStatus.CREATED).body(MaintenanceRequestResponse.from(maintenanceService.create(tenantId, req)));
    }

    @PostMapping("/{id}/assign")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<MaintenanceRequestResponse> assign(@PathVariable UUID id, @RequestParam UUID technicianId) {
        return ResponseEntity.ok(MaintenanceRequestResponse.from(maintenanceService.assign(id, technicianId)));
    }

    @PostMapping("/{id}/resolve")
    @PreAuthorize("hasAnyRole('ADMIN','TECHNICIAN')")
    public ResponseEntity<MaintenanceRequestResponse> resolve(@PathVariable UUID id) {
        return ResponseEntity.ok(MaintenanceRequestResponse.from(maintenanceService.resolve(id)));
    }
}
