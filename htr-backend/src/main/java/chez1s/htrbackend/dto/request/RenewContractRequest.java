package chez1s.htrbackend.dto.request;

import jakarta.validation.constraints.NotNull;
import java.math.BigDecimal;
import java.time.LocalDate;

public record RenewContractRequest(
    @NotNull LocalDate newStartDate,
    @NotNull LocalDate newEndDate,
    BigDecimal newDepositAmount
) {}