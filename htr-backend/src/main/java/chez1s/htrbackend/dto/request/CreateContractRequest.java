package chez1s.htrbackend.dto.request;

import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.PositiveOrZero;
import lombok.Data;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.UUID;

@Data
public class CreateContractRequest {
    @NotNull
    private UUID tenantId;
    @NotNull
    private LocalDate moveInDate;
    @NotNull @PositiveOrZero
    private BigDecimal depositAmount;
    private String notes;
}
