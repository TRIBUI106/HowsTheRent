package chez1s.htrbackend.dto.request;

import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.PositiveOrZero;
import lombok.Data;

import java.math.BigDecimal;

@Data
public class UpdateVehicleConfigRequest {
    @NotNull @PositiveOrZero
    private BigDecimal motorbikePrice;
    @NotNull @PositiveOrZero
    private BigDecimal carPrice;
    @NotNull @PositiveOrZero
    private BigDecimal bicyclePrice;
}
