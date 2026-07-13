package chez1s.htrbackend.dto.request;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;
import lombok.Data;
import java.math.BigDecimal;

@Data
public class CreateMaintenanceMaterial {
    @NotBlank
    private String name;
    @NotNull
    @Positive
    private Integer quantity = 1;
    private String unit = "cái";
    @NotNull
    private BigDecimal unitPrice = BigDecimal.ZERO;
    private Boolean isFreeInContract = false;
}
