package chez1s.htrbackend.controller;

import chez1s.htrbackend.domain.entity.FeeConfig;
import chez1s.htrbackend.domain.entity.Property;
import chez1s.htrbackend.domain.entity.VehicleConfig;
import chez1s.htrbackend.dto.request.CreatePropertyRequest;
import chez1s.htrbackend.dto.request.UpdateFeeConfigRequest;
import chez1s.htrbackend.dto.request.UpdateVehicleConfigRequest;
import chez1s.htrbackend.security.JwtTokenProvider;
import chez1s.htrbackend.service.PropertyService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/properties")
@RequiredArgsConstructor
public class PropertyController {

    private final PropertyService propertyService;
    private final JwtTokenProvider jwtTokenProvider;

    @GetMapping
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<List<Property>> listAll() {
        return ResponseEntity.ok(propertyService.listAll());
    }

    @GetMapping("/mine")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<List<Property>> listMine(@RequestHeader("Authorization") String authHeader) {
        UUID ownerId = extractUserId(authHeader);
        return ResponseEntity.ok(propertyService.listByOwner(ownerId));
    }

    @GetMapping("/{id}")
    public ResponseEntity<Property> getById(@PathVariable UUID id) {
        return ResponseEntity.ok(propertyService.getById(id));
    }

    @PostMapping
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<Property> create(@RequestHeader("Authorization") String authHeader,
                                           @Valid @RequestBody CreatePropertyRequest req) {
        UUID ownerId = extractUserId(authHeader);
        return ResponseEntity.status(HttpStatus.CREATED).body(propertyService.create(ownerId, req));
    }

    @PutMapping("/{id}")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<Property> update(@PathVariable UUID id,
                                           @Valid @RequestBody CreatePropertyRequest req) {
        return ResponseEntity.ok(propertyService.update(id, req));
    }

    @GetMapping("/{id}/fee-config")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<FeeConfig> getFeeConfig(@PathVariable UUID id) {
        return ResponseEntity.ok(propertyService.getFeeConfig(id));
    }

    @PutMapping("/{id}/fee-config")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<FeeConfig> updateFeeConfig(@PathVariable UUID id,
                                                     @Valid @RequestBody UpdateFeeConfigRequest req) {
        return ResponseEntity.ok(propertyService.updateFeeConfig(id, req));
    }

    @GetMapping("/{id}/vehicle-config")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<VehicleConfig> getVehicleConfig(@PathVariable UUID id) {
        return ResponseEntity.ok(propertyService.getVehicleConfig(id));
    }

    @PutMapping("/{id}/vehicle-config")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<VehicleConfig> updateVehicleConfig(@PathVariable UUID id,
                                                             @Valid @RequestBody UpdateVehicleConfigRequest req) {
        return ResponseEntity.ok(propertyService.updateVehicleConfig(id, req));
    }

    private UUID extractUserId(String authHeader) {
        String token = authHeader.replace("Bearer ", "");
        return jwtTokenProvider.getUserId(token);
    }
}
