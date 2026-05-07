package chez1s.htrbackend.service;

import chez1s.htrbackend.domain.entity.*;
import chez1s.htrbackend.domain.repository.MeterReadingRepository;
import chez1s.htrbackend.domain.repository.VehicleRecordRepository;
import chez1s.htrbackend.dto.request.CreateMeterReadingRequest;
import chez1s.htrbackend.dto.request.UpdateVehicleRecordRequest;
import chez1s.htrbackend.exception.BusinessException;
import chez1s.htrbackend.exception.ResourceNotFoundException;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class MeterReadingService {

    private final MeterReadingRepository meterReadingRepository;
    private final VehicleRecordRepository vehicleRecordRepository;
    private final RoomService roomService;

    public List<MeterReading> listByRoom(UUID roomId) {
        return meterReadingRepository.findByRoomIdOrderByReadingMonthDesc(roomId);
    }

    public Optional<MeterReading> findByRoomAndMonth(UUID roomId, LocalDate month) {
        return meterReadingRepository.findByRoomIdAndReadingMonth(roomId, month);
    }

    @Transactional
    public MeterReading create(UUID roomId, UUID recordedById, CreateMeterReadingRequest req) {
        if (meterReadingRepository.existsByRoomIdAndReadingMonth(roomId, req.getReadingMonth())) {
            throw new BusinessException("Meter reading already exists for this room and month");
        }
        Room room = roomService.getById(roomId);
        MeterReading reading = MeterReading.builder()
                .room(room)
                .readingMonth(req.getReadingMonth())
                .elecOld(req.getElecOld())
                .elecNew(req.getElecNew())
                .waterOld(req.getWaterOld())
                .waterNew(req.getWaterNew())
                .recordedBy(User.builder().id(recordedById).build())
                .build();
        return meterReadingRepository.save(reading);
    }

    public List<VehicleRecord> listVehicleRecords(UUID roomId) {
        return vehicleRecordRepository.findByRoomIdOrderByRecordMonthDesc(roomId);
    }

    @Transactional
    public VehicleRecord upsertVehicleRecord(UUID roomId, UpdateVehicleRecordRequest req) {
        Room room = roomService.getById(roomId);
        VehicleRecord record = vehicleRecordRepository
                .findByRoomIdAndRecordMonth(roomId, req.getRecordMonth())
                .orElse(VehicleRecord.builder().room(room).recordMonth(req.getRecordMonth()).build());
        record.setMotorbikeCount(req.getMotorbikeCount());
        record.setCarCount(req.getCarCount());
        record.setBicycleCount(req.getBicycleCount());
        return vehicleRecordRepository.save(record);
    }
}
