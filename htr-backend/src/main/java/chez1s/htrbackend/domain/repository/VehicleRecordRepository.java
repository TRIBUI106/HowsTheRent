package chez1s.htrbackend.domain.repository;

import chez1s.htrbackend.domain.entity.VehicleRecord;
import org.springframework.data.jpa.repository.JpaRepository;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface VehicleRecordRepository extends JpaRepository<VehicleRecord, UUID> {
    List<VehicleRecord> findByRoomIdOrderByRecordMonthDesc(UUID roomId);
    Optional<VehicleRecord> findByRoomIdAndRecordMonth(UUID roomId, LocalDate recordMonth);
}
