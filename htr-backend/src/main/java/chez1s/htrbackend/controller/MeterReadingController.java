package chez1s.htrbackend.controller;

import chez1s.htrbackend.dto.request.CreateMeterReadingRequest;
import chez1s.htrbackend.dto.request.HunonicSyncMeterReadingRequest;
import chez1s.htrbackend.dto.response.HunonicMeterSyncResponse;
import chez1s.htrbackend.dto.request.UpdateVehicleRecordRequest;
import chez1s.htrbackend.dto.response.MeterReadingResponse;
import chez1s.htrbackend.dto.response.VehicleRecordResponse;
import chez1s.htrbackend.service.HunonicMeterService;
import chez1s.htrbackend.service.MeterReadingService;
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
@RequestMapping("/api/rooms/{roomId}")
@RequiredArgsConstructor
public class MeterReadingController {

    private final MeterReadingService meterReadingService;
    private final HunonicMeterService hunonicMeterService;

    @GetMapping("/meter-readings")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<List<MeterReadingResponse>> listReadings(@PathVariable UUID roomId) {
        return ResponseEntity.ok(meterReadingService.listByRoom(roomId).stream().map(MeterReadingResponse::from).toList());
    }

    @PostMapping("/meter-readings")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<MeterReadingResponse> createReading(@PathVariable UUID roomId,
                                                              Authentication auth,
                                                              @Valid @RequestBody CreateMeterReadingRequest req) {
        UUID recordedBy = (UUID) auth.getPrincipal();
        return ResponseEntity.status(HttpStatus.CREATED).body(MeterReadingResponse.from(meterReadingService.create(roomId, recordedBy, req)));
    }

    @PostMapping("/meter-readings/hunonic-sync")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<HunonicMeterSyncResponse> syncHunonicReading(@PathVariable UUID roomId,
                                                                       @Valid @RequestBody HunonicSyncMeterReadingRequest req) {
        return ResponseEntity.ok(hunonicMeterService.syncRoom(roomId, req.getReadingMonth()));
    }

    @GetMapping("/vehicle-records")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<List<VehicleRecordResponse>> listVehicleRecords(@PathVariable UUID roomId) {
        return ResponseEntity.ok(meterReadingService.listVehicleRecords(roomId).stream().map(VehicleRecordResponse::from).toList());
    }

    @PostMapping("/vehicle-records")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<VehicleRecordResponse> upsertVehicleRecord(@PathVariable UUID roomId,
                                                                     @Valid @RequestBody UpdateVehicleRecordRequest req) {
        return ResponseEntity.ok(VehicleRecordResponse.from(meterReadingService.upsertVehicleRecord(roomId, req)));
    }
}
