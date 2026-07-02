package chez1s.htrbackend.dto.request;

import jakarta.validation.constraints.NotNull;
import lombok.Data;

import java.time.LocalDate;

@Data
public class HunonicSyncMeterReadingRequest {
    @NotNull
    private LocalDate readingMonth;
}
