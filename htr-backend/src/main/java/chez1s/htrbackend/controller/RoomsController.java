package chez1s.htrbackend.controller;

import chez1s.htrbackend.domain.enums.RoomStatus;
import chez1s.htrbackend.domain.enums.UserRole;
import chez1s.htrbackend.domain.repository.RoomRepository;
import chez1s.htrbackend.domain.repository.UserRepository;
import chez1s.htrbackend.dto.response.RoomResponse;
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
    private final UserRepository userRepository;

    private boolean isAdmin(UUID userId) {
        return userRepository.findById(userId)
                .map(u -> u.getRole() == UserRole.ADMIN)
                .orElse(false);
    }

    @GetMapping
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<List<RoomResponse>> listAll(Authentication auth) {
        UUID ownerId = (UUID) auth.getPrincipal();
        if (isAdmin(ownerId)) {
            return ResponseEntity.ok(roomRepository.findAll().stream().map(RoomResponse::from).toList());
        }
        return ResponseEntity.ok(roomRepository.findByPropertyOwnerId(ownerId).stream().map(RoomResponse::from).toList());
    }

    @GetMapping("/empty")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<List<RoomResponse>> listEmpty(Authentication auth) {
        UUID ownerId = (UUID) auth.getPrincipal();
        if (isAdmin(ownerId)) {
            return ResponseEntity.ok(roomRepository.findByStatus(RoomStatus.EMPTY).stream().map(RoomResponse::from).toList());
        }
        return ResponseEntity.ok(roomRepository.findByPropertyOwnerIdAndStatus(ownerId, RoomStatus.EMPTY).stream().map(RoomResponse::from).toList());
    }

    @GetMapping("/rented")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<List<RoomResponse>> listRented(Authentication auth) {
        UUID ownerId = (UUID) auth.getPrincipal();
        if (isAdmin(ownerId)) {
            return ResponseEntity.ok(roomRepository.findByStatus(RoomStatus.RENTED).stream().map(RoomResponse::from).toList());
        }
        return ResponseEntity.ok(roomRepository.findByPropertyOwnerIdAndStatus(ownerId, RoomStatus.RENTED).stream().map(RoomResponse::from).toList());
    }
}
