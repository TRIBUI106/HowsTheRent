package chez1s.htrbackend.dto.response;

import java.time.LocalDate;
import java.util.UUID;

public record HunonicMeterSyncResponse(
        UUID roomId,
        LocalDate readingMonth,
        boolean configured,
        boolean created,
        String message
) {
}
