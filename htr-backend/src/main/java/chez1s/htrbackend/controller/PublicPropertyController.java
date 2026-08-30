package chez1s.htrbackend.controller;

import chez1s.htrbackend.domain.enums.RoomStatus;
import chez1s.htrbackend.domain.repository.RoomRepository;
import chez1s.htrbackend.dto.response.VacancyResponse;
import chez1s.htrbackend.service.PropertyService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.UUID;

@RestController
@RequestMapping("/api/public/properties")
@RequiredArgsConstructor
public class PublicPropertyController {

    private final PropertyService propertyService;
    private final RoomRepository roomRepository;

    @GetMapping("/{id}/vacancy")
    public ResponseEntity<VacancyResponse> vacancy(@PathVariable UUID id) {
        propertyService.getById(id); // 404s via ResourceNotFoundException if the property doesn't exist
        long empty = roomRepository.countByPropertyIdAndStatus(id, RoomStatus.EMPTY);
        long rented = roomRepository.countByPropertyIdAndStatus(id, RoomStatus.RENTED);
        long maintenance = roomRepository.countByPropertyIdAndStatus(id, RoomStatus.MAINTENANCE);
        return ResponseEntity.ok(new VacancyResponse(empty, rented, empty + rented + maintenance));
    }
}
