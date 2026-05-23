package chez1s.htrbackend.dto.request;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
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
}
