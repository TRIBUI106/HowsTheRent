package chez1s.htrbackend.controller;

import chez1s.htrbackend.domain.enums.RoomStatus;
import chez1s.htrbackend.domain.repository.RoomRepository;
import chez1s.htrbackend.dto.response.RoomResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/rooms")
@RequiredArgsConstructor
public class RoomsController {

    private final RoomRepository roomRepository;

    @GetMapping
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<List<RoomResponse>> listAll() {
        return ResponseEntity.ok(roomRepository.findAll().stream().map(RoomResponse::from).toList());
    }

    @GetMapping("/rented")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<List<RoomResponse>> listRented() {
        return ResponseEntity.ok(roomRepository.findByStatus(RoomStatus.RENTED).stream().map(RoomResponse::from).toList());
    }
}
