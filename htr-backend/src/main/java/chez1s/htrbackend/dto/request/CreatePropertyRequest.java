package chez1s.htrbackend.dto.request;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.PositiveOrZero;
import lombok.Data;

import java.util.UUID;

@Data
public class CreatePropertyRequest {
    @NotBlank
    private String name;
    @NotBlank
    private String address;
    @NotNull
    private UUID propertyTypeId;
    private String description;
    @PositiveOrZero
    private Integer floorCount;
    @PositiveOrZero
    private Integer roomCount;
}
