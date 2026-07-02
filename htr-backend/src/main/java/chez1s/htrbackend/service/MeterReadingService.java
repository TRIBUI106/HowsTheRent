package chez1s.htrbackend.service;

import chez1s.htrbackend.domain.entity.*;
import chez1s.htrbackend.domain.enums.MeterReadingSource;
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

    public Optional<MeterReading> findLatestBeforeMonth(UUID roomId, LocalDate month) {
        return meterReadingRepository.findFirstByRoomIdAndReadingMonthLessThanOrderByReadingMonthDesc(roomId, month);
    }

    @Transactional
    public MeterReading create(UUID roomId, UUID recordedById, CreateMeterReadingRequest req) {
        if (meterReadingRepository.existsByRoomIdAndReadingMonth(roomId, req.getReadingMonth())) {
            throw new BusinessException("Meter reading already exists for this room and month");
        }

        MeterReading previousReading = meterReadingRepository
                .findFirstByRoomIdAndReadingMonthLessThanOrderByReadingMonthDesc(roomId, req.getReadingMonth())
                .orElse(null);

        Long elecOld = req.getElecOld() != null
                ? req.getElecOld()
                : previousReading != null ? previousReading.getElecNew() : null;
        if (elecOld == null) {
            throw new BusinessException("Previous electricity reading not found. Please enter the old index for the first period.");
        }
        if (req.getElecNew() < elecOld) {
            throw new BusinessException("New electricity reading must be greater than or equal to the old reading.");
        }

        Long waterOld = req.getWaterOld();
        if (waterOld == null && req.getWaterNew() != null && previousReading != null) {
            waterOld = previousReading.getWaterNew();
        }
        if (waterOld != null && req.getWaterNew() != null && req.getWaterNew() < waterOld) {
            throw new BusinessException("New water reading must be greater than or equal to the old reading.");
        }

        Room room = roomService.getById(roomId);
        MeterReading reading = MeterReading.builder()
                .room(room)
                .readingMonth(req.getReadingMonth())
                .elecOld(elecOld)
                .elecNew(req.getElecNew())
                .waterOld(waterOld)
                .waterNew(req.getWaterNew())
                .source(req.getSource() != null ? req.getSource() : MeterReadingSource.MANUAL)
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
