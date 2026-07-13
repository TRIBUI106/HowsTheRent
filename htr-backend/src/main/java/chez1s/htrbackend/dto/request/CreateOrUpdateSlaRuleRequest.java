package chez1s.htrbackend.dto.request;

import chez1s.htrbackend.domain.enums.MaintenanceCategory;
import chez1s.htrbackend.domain.enums.MaintenancePriority;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class CreateOrUpdateSlaRuleRequest {
    @NotNull
    private MaintenancePriority priority;

    @NotNull
    private MaintenanceCategory category;

    @Min(1)
    private int maxHours;
}
