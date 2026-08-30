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
        if (req.isElecReplaced()) {
            validateReplacement(elecOld, req.getElecOldMeterFinal(), req.getElecNew(), req.getElecNewMeterStart(), "electricity");
        } else {
            validateDelta(req.getElecNew(), elecOld, "electricity");
        }

        Long waterOld = previousReading != null
                ? previousReading.getWaterNew()
                : req.getWaterOld() != null ? req.getWaterOld() : existingReading.map(MeterReading::getWaterOld).orElse(null);
        if (waterOld != null && req.getWaterNew() != null) {
            if (req.isWaterReplaced()) {
                validateReplacement(waterOld, req.getWaterOldMeterFinal(), req.getWaterNew(), req.getWaterNewMeterStart(), "water");
            } else {
                validateDelta(req.getWaterNew(), waterOld, "water");
            }
        }

        MeterReading reading = existingReading.orElseGet(() -> MeterReading.builder()
                .room(roomService.getById(roomId))
                .readingMonth(readingMonth)
                .build());
        reading.setElecOld(elecOld);
        reading.setElecNew(req.getElecNew());
        reading.setWaterOld(waterOld);
        reading.setWaterNew(req.getWaterNew());
        reading.setElecReplaced(req.isElecReplaced());
        reading.setElecOldMeterFinal(req.isElecReplaced() ? req.getElecOldMeterFinal() : null);
        reading.setElecNewMeterStart(req.isElecReplaced() ? req.getElecNewMeterStart() : null);
        reading.setWaterReplaced(req.isWaterReplaced());
        reading.setWaterOldMeterFinal(req.isWaterReplaced() ? req.getWaterOldMeterFinal() : null);
        reading.setWaterNewMeterStart(req.isWaterReplaced() ? req.getWaterNewMeterStart() : null);
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

    /**
     * When a meter is replaced mid-period, the usual "new >= old" check doesn't
     * apply (the new meter typically starts lower than the old one's last
     * reading). Instead validate the two independent segments: the old meter's
     * final reading before removal, and the new meter's current reading since
     * install — each must only move forward from its own baseline.
     */
    private void validateReplacement(Long oldMeterPrevious, Long oldMeterFinal, Long newMeterCurrent, Long newMeterStart, String meterName) {
        if (oldMeterFinal == null || newMeterStart == null) {
            throw new BusinessException("Meter replacement for " + meterName + " requires both the old meter's final reading and the new meter's starting reading.");
        }
        validateDelta(oldMeterFinal, oldMeterPrevious, meterName + " (old meter, final reading)");
        validateDelta(newMeterCurrent, newMeterStart, meterName + " (new meter, current reading)");
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
