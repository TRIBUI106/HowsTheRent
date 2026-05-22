package chez1s.htrbackend.controller;

import chez1s.htrbackend.domain.entity.Room;
import chez1s.htrbackend.domain.enums.RoomStatus;
import chez1s.htrbackend.dto.request.CreateRoomRequest;
import chez1s.htrbackend.dto.response.RoomResponse;
import chez1s.htrbackend.service.RoomService;
import chez1s.htrbackend.service.StorageService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/properties/{propertyId}/rooms")
@RequiredArgsConstructor
public class RoomController {

    private final RoomService roomService;
    private final StorageService storageService;

    @GetMapping
    public ResponseEntity<List<RoomResponse>> listByProperty(@PathVariable UUID propertyId) {
        return ResponseEntity.ok(roomService.listByProperty(propertyId).stream().map(RoomResponse::from).toList());
    }

    // Flat list needed by meter readings page — not under a property
    // Exposed as GET /api/rooms via a separate mapping

    @GetMapping("/{id}")
    public ResponseEntity<RoomResponse> getById(@PathVariable UUID propertyId, @PathVariable UUID id) {
        return ResponseEntity.ok(RoomResponse.from(roomService.getById(id)));
    }

    @PostMapping
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<RoomResponse> create(@PathVariable UUID propertyId,
                                               @Valid @RequestBody CreateRoomRequest req) {
        return ResponseEntity.status(HttpStatus.CREATED).body(RoomResponse.from(roomService.create(propertyId, req)));
    }

    @PutMapping("/{id}")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<RoomResponse> update(@PathVariable UUID propertyId, @PathVariable UUID id,
                                               @Valid @RequestBody CreateRoomRequest req) {
        return ResponseEntity.ok(RoomResponse.from(roomService.update(id, req)));
    }

    @PatchMapping("/{id}/status")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<RoomResponse> updateStatus(@PathVariable UUID propertyId, @PathVariable UUID id,
                                                     @RequestParam RoomStatus status) {
        return ResponseEntity.ok(RoomResponse.from(roomService.updateStatus(id, status)));
    }

    @DeleteMapping("/{id}")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<Void> delete(@PathVariable UUID propertyId, @PathVariable UUID id) {
        roomService.delete(id);
        return ResponseEntity.noContent().build();
    }

    @PostMapping("/{id}/images")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<List<String>> uploadImages(@PathVariable UUID propertyId, @PathVariable UUID id,
                                                     @RequestParam("files") List<MultipartFile> files) {
        List<String> urls = files.stream()
                .map(f -> storageService.upload("rooms/" + id, f))
                .toList();
        Room room = roomService.getById(id);
        room.getImages().addAll(urls);
        roomService.save(room);
        return ResponseEntity.ok(urls);
    }
}
