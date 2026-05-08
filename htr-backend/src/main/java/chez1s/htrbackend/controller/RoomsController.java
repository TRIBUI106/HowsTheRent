package chez1s.htrbackend.controller;

import chez1s.htrbackend.domain.entity.Room;
import chez1s.htrbackend.domain.enums.RoomStatus;
import chez1s.htrbackend.domain.repository.RoomRepository;
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
    public ResponseEntity<List<Room>> listAll() {
        return ResponseEntity.ok(roomRepository.findAll());
    }

    @GetMapping("/rented")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<List<Room>> listRented() {
        return ResponseEntity.ok(roomRepository.findByStatus(RoomStatus.RENTED));
    }
}
