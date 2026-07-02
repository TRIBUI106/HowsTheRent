package chez1s.htrbackend.domain.repository;

import chez1s.htrbackend.domain.entity.MeterReading;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface MeterReadingRepository extends JpaRepository<MeterReading, UUID> {
    @EntityGraph(attributePaths = {"room", "recordedBy"})
    List<MeterReading> findByRoomIdOrderByReadingMonthDesc(UUID roomId);

    @EntityGraph(attributePaths = {"room", "recordedBy"})
    Optional<MeterReading> findByRoomIdAndReadingMonth(UUID roomId, LocalDate readingMonth);

    @EntityGraph(attributePaths = {"room", "recordedBy"})
    Optional<MeterReading> findFirstByRoomIdAndReadingMonthLessThanOrderByReadingMonthDesc(UUID roomId, LocalDate readingMonth);

    boolean existsByRoomIdAndReadingMonth(UUID roomId, LocalDate readingMonth);
}
