package chez1s.htrbackend.dto.request;

import jakarta.validation.constraints.NotBlank;
import lombok.Data;

@Data
public class CreatePropertyTypeRequest {
    @NotBlank
    private String code;
    @NotBlank
    private String name;
    private String description;
}
