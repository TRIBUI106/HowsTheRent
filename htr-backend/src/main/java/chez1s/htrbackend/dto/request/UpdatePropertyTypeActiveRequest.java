package chez1s.htrbackend.dto.request;

import jakarta.validation.constraints.NotNull;
import lombok.Data;

@Data
public class UpdatePropertyTypeActiveRequest {
    @NotNull
    private Boolean active;
}
