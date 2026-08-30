package chez1s.htrbackend.dto.request;

import chez1s.htrbackend.domain.enums.MeterReadingSource;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.PositiveOrZero;
import lombok.Data;

import java.time.LocalDate;

@Data
public class CreateMeterReadingRequest {
    @NotNull
    private LocalDate readingMonth;
    @PositiveOrZero
    private Long elecOld;
    @NotNull @PositiveOrZero @Max(1_000_000_000L)
    private Long elecNew;
    @PositiveOrZero
    private Long waterOld;
    @PositiveOrZero @Max(1_000_000_000L)
    private Long waterNew;
    private MeterReadingSource source = MeterReadingSource.MANUAL;

    private boolean elecReplaced;
    @PositiveOrZero @Max(1_000_000_000L)
    private Long elecOldMeterFinal;
    @PositiveOrZero @Max(1_000_000_000L)
    private Long elecNewMeterStart;

    private boolean waterReplaced;
    @PositiveOrZero @Max(1_000_000_000L)
    private Long waterOldMeterFinal;
    @PositiveOrZero @Max(1_000_000_000L)
    private Long waterNewMeterStart;
}
