package chez1s.htrbackend.dto.request;

import chez1s.htrbackend.domain.enums.WaterMode;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.PositiveOrZero;
import lombok.Data;

import java.math.BigDecimal;

@Data
public class UpdateFeeConfigRequest {
    @NotNull @PositiveOrZero
    private BigDecimal rentDefault;
    @NotNull @PositiveOrZero
    private BigDecimal elecPrice;
    @NotNull
    private WaterMode waterMode;
    @NotNull @PositiveOrZero
    private BigDecimal waterPrice;
    @NotNull @PositiveOrZero
    private BigDecimal serviceFee;
    private boolean vehicleProRata;
    private boolean serviceProRata;
}
