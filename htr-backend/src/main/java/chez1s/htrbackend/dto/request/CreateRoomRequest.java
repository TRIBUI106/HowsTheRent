package chez1s.htrbackend.dto.request;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;
import lombok.Data;

import java.math.BigDecimal;

@Data
public class CreateRoomRequest {
    @NotBlank
    private String roomNumber;
    private Integer floor;
    private BigDecimal areaM2;
    @NotNull @Positive
    private Integer maxPeople;
    private BigDecimal rentOverride;
}
