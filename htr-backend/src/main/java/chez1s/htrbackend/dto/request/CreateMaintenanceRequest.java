package chez1s.htrbackend.dto.request;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

import java.util.List;
import java.util.UUID;

@Data
public class CreateMaintenanceRequest {
    @NotNull
    private UUID roomId;
    @NotBlank
    private String title;
    private String description;
    private List<String> images;
}
