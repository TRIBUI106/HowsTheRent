package chez1s.htrbackend.dto.request;

import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.PositiveOrZero;
import lombok.Data;

import java.time.LocalDate;

@Data
public class CreateMeterReadingRequest {
    @NotNull
    private LocalDate readingMonth;
    @NotNull @PositiveOrZero
    private Long elecOld;
    @NotNull @PositiveOrZero
    private Long elecNew;
    private Long waterOld;
    private Long waterNew;
}
