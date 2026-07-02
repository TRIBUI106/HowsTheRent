package chez1s.htrbackend.dto.response;

import chez1s.htrbackend.domain.entity.MeterReading;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.UUID;

public record MeterReadingResponse(
        UUID id,
        UUID roomId,
        String roomNumber,
        LocalDate readingMonth,
        Long elecOld,
        Long elecNew,
        Long waterOld,
        Long waterNew,
        String source,
        UUID recordedById,
        String recordedByName,
        LocalDateTime recordedAt
) {
    public static MeterReadingResponse from(MeterReading m) {
        return new MeterReadingResponse(
                m.getId(),
                m.getRoom().getId(),
                m.getRoom().getRoomNumber(),
                m.getReadingMonth(),
                m.getElecOld(),
                m.getElecNew(),
                m.getWaterOld(),
                m.getWaterNew(),
                m.getSource().name(),
                m.getRecordedBy().getId(),
                m.getRecordedBy().getFullName(),
                m.getRecordedAt()
        );
    }
}
