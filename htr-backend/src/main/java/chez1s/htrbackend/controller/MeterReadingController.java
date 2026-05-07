package chez1s.htrbackend.controller;

import chez1s.htrbackend.domain.entity.MeterReading;
import chez1s.htrbackend.domain.entity.VehicleRecord;
import chez1s.htrbackend.dto.request.CreateMeterReadingRequest;
import chez1s.htrbackend.dto.request.UpdateVehicleRecordRequest;
import chez1s.htrbackend.security.JwtTokenProvider;
import chez1s.htrbackend.service.MeterReadingService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/rooms/{roomId}")
@RequiredArgsConstructor
public class MeterReadingController {

    private final MeterReadingService meterReadingService;
    private final JwtTokenProvider jwtTokenProvider;

    @GetMapping("/meter-readings")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<List<MeterReading>> listReadings(@PathVariable UUID roomId) {
        return ResponseEntity.ok(meterReadingService.listByRoom(roomId));
    }

    @PostMapping("/meter-readings")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<MeterReading> createReading(@PathVariable UUID roomId,
                                                      @RequestHeader("Authorization") String authHeader,
                                                      @Valid @RequestBody CreateMeterReadingRequest req) {
        UUID recordedBy = jwtTokenProvider.getUserId(authHeader.replace("Bearer ", ""));
        return ResponseEntity.status(HttpStatus.CREATED).body(meterReadingService.create(roomId, recordedBy, req));
    }

    @GetMapping("/vehicle-records")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<List<VehicleRecord>> listVehicleRecords(@PathVariable UUID roomId) {
        return ResponseEntity.ok(meterReadingService.listVehicleRecords(roomId));
    }

    @PostMapping("/vehicle-records")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<VehicleRecord> upsertVehicleRecord(@PathVariable UUID roomId,
                                                             @Valid @RequestBody UpdateVehicleRecordRequest req) {
        return ResponseEntity.ok(meterReadingService.upsertVehicleRecord(roomId, req));
    }
}
