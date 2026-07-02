package chez1s.htrbackend.dto.response;

import java.time.LocalDate;
import java.util.UUID;

public record HunonicMeterPreviewResponse(
        UUID roomId,
        String roomNumber,
        String propertyName,
        LocalDate readingMonth,
        boolean configured,
        String status,
        String message,
        Long suggestedElecOld,
        Long suggestedWaterOld
) {
}
