package chez1s.htrbackend.controller;

import chez1s.htrbackend.dto.response.HunonicMeterPreviewResponse;
import chez1s.htrbackend.service.HunonicMeterService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/meter-readings")
@RequiredArgsConstructor
public class MeterReadingIntegrationController {

    private final HunonicMeterService hunonicMeterService;

    @GetMapping("/hunonic-preview")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<List<HunonicMeterPreviewResponse>> previewHunonic(Authentication auth,
                                                                            @RequestParam LocalDate readingMonth) {
        UUID ownerId = (UUID) auth.getPrincipal();
        return ResponseEntity.ok(hunonicMeterService.previewByOwner(ownerId, readingMonth));
    }
}
