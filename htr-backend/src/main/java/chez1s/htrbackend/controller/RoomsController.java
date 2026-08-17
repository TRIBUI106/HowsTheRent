package chez1s.htrbackend.controller;

import chez1s.htrbackend.domain.enums.RoomStatus;
import chez1s.htrbackend.domain.repository.RoomRepository;
import chez1s.htrbackend.dto.response.RoomResponse;
import chez1s.htrbackend.security.ActorContext;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/rooms")
@RequiredArgsConstructor
public class RoomsController {

    private final RoomRepository roomRepository;

    private boolean isPlatformAdmin(Authentication auth) {
        return ActorContext.require(auth).isPlatformAdmin();
    }

    @GetMapping
    @PreAuthorize("hasAnyRole('ADMIN','PLATFORM_ADMIN','LANDLORD_ADMIN')")
    public ResponseEntity<List<RoomResponse>> listAll(Authentication auth) {
        UUID ownerId = (UUID) auth.getPrincipal();
        if (isPlatformAdmin(auth)) {
            return ResponseEntity.ok(roomRepository.findAll().stream().map(RoomResponse::from).toList());
        }
        return ResponseEntity.ok(roomRepository.findByPropertyOwnerId(ownerId).stream().map(RoomResponse::from).toList());
    }

    @GetMapping("/empty")
    @PreAuthorize("hasAnyRole('ADMIN','PLATFORM_ADMIN','LANDLORD_ADMIN')")
    public ResponseEntity<List<RoomResponse>> listEmpty(Authentication auth) {
        UUID ownerId = (UUID) auth.getPrincipal();
        if (isPlatformAdmin(auth)) {
            return ResponseEntity.ok(roomRepository.findByStatus(RoomStatus.EMPTY).stream().map(RoomResponse::from).toList());
        }
        return ResponseEntity.ok(roomRepository.findByPropertyOwnerIdAndStatus(ownerId, RoomStatus.EMPTY).stream().map(RoomResponse::from).toList());
    }

    @GetMapping("/rented")
    @PreAuthorize("hasAnyRole('ADMIN','PLATFORM_ADMIN','LANDLORD_ADMIN')")
    public ResponseEntity<List<RoomResponse>> listRented(Authentication auth) {
        UUID ownerId = (UUID) auth.getPrincipal();
        if (isPlatformAdmin(auth)) {
            return ResponseEntity.ok(roomRepository.findByStatus(RoomStatus.RENTED).stream().map(RoomResponse::from).toList());
        }
        return ResponseEntity.ok(roomRepository.findByPropertyOwnerIdAndStatus(ownerId, RoomStatus.RENTED).stream().map(RoomResponse::from).toList());
    }
}
