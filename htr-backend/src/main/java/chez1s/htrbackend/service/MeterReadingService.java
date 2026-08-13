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

    private static final long MAX_READING_DELTA = 100_000L;

    private final MeterReadingRepository meterReadingRepository;
    private final VehicleRecordRepository vehicleRecordRepository;
    private final RoomService roomService;

    public List<MeterReading> listByRoom(UUID roomId) {
        return meterReadingRepository.findByRoomIdOrderByReadingMonthDesc(roomId);
    }

    public Optional<MeterReading> findByRoomAndMonth(UUID roomId, LocalDate month) {
        return meterReadingRepository.findByRoomIdAndReadingMonth(roomId, normalizeMonth(month));
    }

    public Optional<MeterReading> findLatestBeforeMonth(UUID roomId, LocalDate month) {
        return meterReadingRepository.findFirstByRoomIdAndReadingMonthLessThanOrderByReadingMonthDesc(roomId, normalizeMonth(month));
    }

    @Transactional
    public MeterReading create(UUID roomId, UUID recordedById, CreateMeterReadingRequest req) {
        LocalDate readingMonth = normalizeMonth(req.getReadingMonth());
        Optional<MeterReading> existingReading = meterReadingRepository.findByRoomIdAndReadingMonth(roomId, readingMonth);
        MeterReading previousReading = meterReadingRepository
                .findFirstByRoomIdAndReadingMonthLessThanOrderByReadingMonthDesc(roomId, readingMonth)
                .orElse(null);

        Long elecOld = previousReading != null
                ? previousReading.getElecNew()
                : req.getElecOld() != null ? req.getElecOld() : existingReading.map(MeterReading::getElecOld).orElse(null);
        if (elecOld == null) {
            throw new BusinessException("Previous electricity reading not found. Please enter the old index for the first period.");
        }
        validateDelta(req.getElecNew(), elecOld, "electricity");

        Long waterOld = previousReading != null
                ? previousReading.getWaterNew()
                : req.getWaterOld() != null ? req.getWaterOld() : existingReading.map(MeterReading::getWaterOld).orElse(null);
        if (waterOld != null && req.getWaterNew() != null) {
            validateDelta(req.getWaterNew(), waterOld, "water");
        }

        MeterReading reading = existingReading.orElseGet(() -> MeterReading.builder()
                .room(roomService.getById(roomId))
                .readingMonth(readingMonth)
                .build());
        reading.setElecOld(elecOld);
        reading.setElecNew(req.getElecNew());
        reading.setWaterOld(waterOld);
        reading.setWaterNew(req.getWaterNew());
        reading.setSource(req.getSource() != null ? req.getSource() : MeterReadingSource.MANUAL);
        reading.setRecordedBy(User.builder().id(recordedById).build());
        return meterReadingRepository.save(reading);
    }

    private LocalDate normalizeMonth(LocalDate date) {
        return date.withDayOfMonth(1);
    }

    private void validateDelta(Long newValue, Long oldValue, String meterName) {
        if (newValue < oldValue) {
            throw new BusinessException("New " + meterName + " reading must be greater than or equal to the old reading.");
        }
        if (newValue - oldValue > MAX_READING_DELTA) {
            throw new BusinessException("New " + meterName + " reading is too far from the old reading.");
        }
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
