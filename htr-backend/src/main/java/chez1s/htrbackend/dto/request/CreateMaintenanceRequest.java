package chez1s.htrbackend.dto.request;

import jakarta.validation.constraints.NotBlank;
import lombok.Data;

import java.util.List;
import java.util.UUID;

@Data
public class CreateMaintenanceRequest {
    private UUID roomId;
    @NotBlank
    private String title;
    private String description;
    private List<String> images;
}
