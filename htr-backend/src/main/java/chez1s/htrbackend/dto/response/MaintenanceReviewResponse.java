package chez1s.htrbackend.dto.response;

import chez1s.htrbackend.domain.entity.MaintenanceReview;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;
import java.util.UUID;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class MaintenanceReviewResponse {
    private UUID id;
    private UUID requestId;
    private String requestTitle;
    private UUID technicianId;
    private String technicianName;
    private UUID tenantId;
    private String tenantName;
    private int ratingStars;
    private String comment;
    private LocalDateTime createdAt;

    public static MaintenanceReviewResponse from(MaintenanceReview r) {
        return MaintenanceReviewResponse.builder()
                .id(r.getId())
                .requestId(r.getMaintenanceRequest() != null ? r.getMaintenanceRequest().getId() : null)
                .requestTitle(r.getMaintenanceRequest() != null ? r.getMaintenanceRequest().getTitle() : null)
                .technicianId(r.getTechnician() != null ? r.getTechnician().getId() : null)
                .technicianName(r.getTechnician() != null ? r.getTechnician().getFullName() : null)
                .tenantId(r.getTenant() != null ? r.getTenant().getId() : null)
                .tenantName(r.getTenant() != null ? r.getTenant().getFullName() : null)
                .ratingStars(r.getRatingStars())
                .comment(r.getComment())
                .createdAt(r.getCreatedAt())
                .build();
    }
}
