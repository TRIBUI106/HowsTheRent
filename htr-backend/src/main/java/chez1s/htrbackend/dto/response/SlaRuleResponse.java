package chez1s.htrbackend.dto.response;

import chez1s.htrbackend.domain.entity.SlaRule;
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
public class SlaRuleResponse {
    private UUID id;
    private String priority;
    private String category;
    private int maxHours;
    private LocalDateTime updatedAt;

    public static SlaRuleResponse from(SlaRule rule) {
        return SlaRuleResponse.builder()
                .id(rule.getId())
                .priority(rule.getPriority() != null ? rule.getPriority().name() : null)
                .category(rule.getCategory() != null ? rule.getCategory().name() : null)
                .maxHours(rule.getMaxHours())
                .updatedAt(rule.getUpdatedAt())
                .build();
    }
}
