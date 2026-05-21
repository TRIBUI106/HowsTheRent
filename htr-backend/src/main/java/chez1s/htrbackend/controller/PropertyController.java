package chez1s.htrbackend.controller;

import chez1s.htrbackend.dto.request.CreatePropertyRequest;
import chez1s.htrbackend.dto.request.UpdateFeeConfigRequest;
import chez1s.htrbackend.dto.request.UpdateVehicleConfigRequest;
import chez1s.htrbackend.dto.response.FeeConfigResponse;
import chez1s.htrbackend.dto.response.PropertyResponse;
import chez1s.htrbackend.dto.response.VehicleConfigResponse;
import chez1s.htrbackend.service.PropertyService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/properties")
@RequiredArgsConstructor
public class PropertyController {

    private final PropertyService propertyService;

    @GetMapping
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<List<PropertyResponse>> listAll() {
        return ResponseEntity.ok(propertyService.listAll().stream().map(PropertyResponse::from).toList());
    }

    @GetMapping("/mine")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<List<PropertyResponse>> listMine(Authentication auth) {
        UUID ownerId = (UUID) auth.getPrincipal();
        return ResponseEntity.ok(propertyService.listByOwner(ownerId).stream().map(PropertyResponse::from).toList());
    }

    @GetMapping("/{id}")
    public ResponseEntity<PropertyResponse> getById(@PathVariable UUID id) {
        return ResponseEntity.ok(PropertyResponse.from(propertyService.getById(id)));
    }

    @PostMapping
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<PropertyResponse> create(Authentication auth,
                                                   @Valid @RequestBody CreatePropertyRequest req) {
        UUID ownerId = (UUID) auth.getPrincipal();
        return ResponseEntity.status(HttpStatus.CREATED).body(PropertyResponse.from(propertyService.create(ownerId, req)));
    }

    @PutMapping("/{id}")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<PropertyResponse> update(@PathVariable UUID id,
                                                   @Valid @RequestBody CreatePropertyRequest req) {
        return ResponseEntity.ok(PropertyResponse.from(propertyService.update(id, req)));
    }

    @GetMapping("/{id}/fee-config")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<FeeConfigResponse> getFeeConfig(@PathVariable UUID id) {
        return ResponseEntity.ok(FeeConfigResponse.from(propertyService.getFeeConfig(id)));
    }

    @PutMapping("/{id}/fee-config")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<FeeConfigResponse> updateFeeConfig(@PathVariable UUID id,
                                                             @Valid @RequestBody UpdateFeeConfigRequest req) {
        return ResponseEntity.ok(FeeConfigResponse.from(propertyService.updateFeeConfig(id, req)));
    }

    @GetMapping("/{id}/vehicle-config")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<VehicleConfigResponse> getVehicleConfig(@PathVariable UUID id) {
        return ResponseEntity.ok(VehicleConfigResponse.from(propertyService.getVehicleConfig(id)));
    }

    @PutMapping("/{id}/vehicle-config")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<VehicleConfigResponse> updateVehicleConfig(@PathVariable UUID id,
                                                                     @Valid @RequestBody UpdateVehicleConfigRequest req) {
        return ResponseEntity.ok(VehicleConfigResponse.from(propertyService.updateVehicleConfig(id, req)));
    }
}
