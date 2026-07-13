package chez1s.htrbackend.dto.request;

import chez1s.htrbackend.domain.enums.MaintenanceCategory;
import chez1s.htrbackend.domain.enums.MaintenancePriority;
import jakarta.validation.constraints.NotBlank;
import lombok.Data;

import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

@Data
public class CreateMaintenanceRequest {
    private UUID roomId;
    @NotBlank
    private String title;
    private String description;
    private List<String> images;
    private MaintenancePriority priority;
    private MaintenanceCategory category;
    private LocalDateTime expectedResolvedAt;
}
