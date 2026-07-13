package chez1s.htrbackend.dto.response;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.UUID;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class TechnicianPerformanceDto {
    private UUID technicianId;
    private String technicianName;
    private String specialties;
    private int assignedCount;
    private int activeCount;
    private int completedCount;
    private int overdueSlaCount;
    private double avgRatingStars;
    private int totalReviews;
}
