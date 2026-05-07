package chez1s.htrbackend.dto.request;

import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.PositiveOrZero;
import lombok.Data;

import java.time.LocalDate;

@Data
public class UpdateVehicleRecordRequest {
    @NotNull
    private LocalDate recordMonth;
    @NotNull @PositiveOrZero
    private Integer motorbikeCount;
    @NotNull @PositiveOrZero
    private Integer carCount;
    @NotNull @PositiveOrZero
    private Integer bicycleCount;
}
