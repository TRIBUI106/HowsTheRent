package chez1s.htrbackend.controller;

import chez1s.htrbackend.dto.request.CreateMeterReadingRequest;
import chez1s.htrbackend.dto.request.HunonicSyncMeterReadingRequest;
import chez1s.htrbackend.dto.response.HunonicMeterSyncResponse;
import chez1s.htrbackend.dto.request.UpdateVehicleRecordRequest;
import chez1s.htrbackend.dto.response.MeterReadingResponse;
import chez1s.htrbackend.dto.response.VehicleRecordResponse;
import chez1s.htrbackend.security.ActorContext;
import chez1s.htrbackend.security.OwnerScopeResolver;
import chez1s.htrbackend.service.HunonicMeterService;
import chez1s.htrbackend.service.MeterReadingService;
import chez1s.htrbackend.service.RoomService;
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
    private final RoomService roomService;
    private final OwnerScopeResolver ownerScopeResolver;

    private void requireRoomAccess(Authentication authentication, UUID roomId) {
        ActorContext actor = ActorContext.require(authentication);
        if (actor.isPlatformAdmin()) return;
        var room = roomService.getById(roomId);
        if (!room.getProperty().getOwner().getId().equals(ownerScopeResolver.requireOwnerId(actor))) {
            throw new chez1s.htrbackend.exception.BusinessException("Room is outside the actor owner scope");
        }
    }

    @GetMapping("/meter-readings")
    @PreAuthorize("hasAnyRole('ADMIN','PLATFORM_ADMIN','LANDLORD_ADMIN')")
    public ResponseEntity<List<MeterReadingResponse>> listReadings(Authentication authentication, @PathVariable UUID roomId) {
        requireRoomAccess(authentication, roomId);
        return ResponseEntity.ok(meterReadingService.listByRoom(roomId).stream().map(MeterReadingResponse::from).toList());
    }

    @PostMapping("/meter-readings")
    @PreAuthorize("hasAnyRole('ADMIN','PLATFORM_ADMIN','LANDLORD_ADMIN')")
    public ResponseEntity<MeterReadingResponse> createReading(@PathVariable UUID roomId,
                                                              Authentication auth,
                                                              @Valid @RequestBody CreateMeterReadingRequest req) {
        requireRoomAccess(auth, roomId);
        UUID recordedBy = (UUID) auth.getPrincipal();
        return ResponseEntity.status(HttpStatus.CREATED).body(MeterReadingResponse.from(meterReadingService.create(roomId, recordedBy, req)));
    }

    @PostMapping("/meter-readings/hunonic-sync")
    @PreAuthorize("hasAnyRole('ADMIN','PLATFORM_ADMIN','LANDLORD_ADMIN')")
    public ResponseEntity<HunonicMeterSyncResponse> syncHunonicReading(Authentication authentication,
                                                                       @PathVariable UUID roomId,
                                                                       @Valid @RequestBody HunonicSyncMeterReadingRequest req) {
        requireRoomAccess(authentication, roomId);
        return ResponseEntity.ok(hunonicMeterService.syncRoom(roomId, req.getReadingMonth()));
    }

    @GetMapping("/vehicle-records")
    @PreAuthorize("hasAnyRole('ADMIN','PLATFORM_ADMIN','LANDLORD_ADMIN')")
    public ResponseEntity<List<VehicleRecordResponse>> listVehicleRecords(Authentication authentication, @PathVariable UUID roomId) {
        requireRoomAccess(authentication, roomId);
        return ResponseEntity.ok(meterReadingService.listVehicleRecords(roomId).stream().map(VehicleRecordResponse::from).toList());
    }

    @PostMapping("/vehicle-records")
    @PreAuthorize("hasAnyRole('ADMIN','PLATFORM_ADMIN','LANDLORD_ADMIN')")
    public ResponseEntity<VehicleRecordResponse> upsertVehicleRecord(Authentication authentication,
                                                                     @PathVariable UUID roomId,
                                                                     @Valid @RequestBody UpdateVehicleRecordRequest req) {
        requireRoomAccess(authentication, roomId);
        return ResponseEntity.ok(VehicleRecordResponse.from(meterReadingService.upsertVehicleRecord(roomId, req)));
    }
}
