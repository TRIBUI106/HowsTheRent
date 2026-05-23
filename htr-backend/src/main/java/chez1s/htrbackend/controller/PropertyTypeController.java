package chez1s.htrbackend.controller;

import chez1s.htrbackend.dto.request.CreatePropertyTypeRequest;
import chez1s.htrbackend.dto.request.UpdatePropertyTypeActiveRequest;
import chez1s.htrbackend.dto.response.PropertyTypeResponse;
import chez1s.htrbackend.service.PropertyTypeService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/property-types")
@RequiredArgsConstructor
public class PropertyTypeController {

    private final PropertyTypeService propertyTypeService;

    @GetMapping
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<List<PropertyTypeResponse>> list(@RequestParam(defaultValue = "false") boolean activeOnly) {
        var types = activeOnly ? propertyTypeService.listActive() : propertyTypeService.listAll();
        return ResponseEntity.ok(types.stream().map(PropertyTypeResponse::from).toList());
    }

    @PostMapping
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<PropertyTypeResponse> create(@Valid @RequestBody CreatePropertyTypeRequest req) {
        return ResponseEntity.status(HttpStatus.CREATED).body(PropertyTypeResponse.from(propertyTypeService.create(req)));
    }

    @PutMapping("/{id}")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<PropertyTypeResponse> update(@PathVariable UUID id,
                                                       @Valid @RequestBody CreatePropertyTypeRequest req) {
        return ResponseEntity.ok(PropertyTypeResponse.from(propertyTypeService.update(id, req)));
    }

    @PatchMapping("/{id}/active")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<PropertyTypeResponse> updateActive(@PathVariable UUID id,
                                                             @Valid @RequestBody UpdatePropertyTypeActiveRequest req) {
        return ResponseEntity.ok(PropertyTypeResponse.from(propertyTypeService.updateActive(id, req.getActive())));
    }

    @DeleteMapping("/{id}")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<Void> delete(@PathVariable UUID id) {
        propertyTypeService.delete(id);
        return ResponseEntity.noContent().build();
    }
}
