package chez1s.htrbackend.dto.request;

import chez1s.htrbackend.domain.enums.MeterReadingSource;
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
    @NotNull @PositiveOrZero
    private Long elecNew;
    @PositiveOrZero
    private Long waterOld;
    @PositiveOrZero
    private Long waterNew;
    private MeterReadingSource source = MeterReadingSource.MANUAL;
}
