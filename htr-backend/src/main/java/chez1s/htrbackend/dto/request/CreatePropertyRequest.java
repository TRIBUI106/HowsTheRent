package chez1s.htrbackend.dto.request;

import chez1s.htrbackend.domain.enums.PropertyType;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

@Data
public class CreatePropertyRequest {
    @NotBlank
    private String name;
    @NotBlank
    private String address;
    @NotNull
    private PropertyType type;
    private String description;
}
