package chez1s.htrbackend.service;

import chez1s.htrbackend.domain.entity.SlaRule;
import chez1s.htrbackend.domain.enums.MaintenanceCategory;
import chez1s.htrbackend.domain.enums.MaintenancePriority;
import chez1s.htrbackend.domain.repository.SlaRuleRepository;
import chez1s.htrbackend.dto.request.CreateOrUpdateSlaRuleRequest;
import chez1s.htrbackend.dto.response.SlaRuleResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class SlaService {

    private final SlaRuleRepository slaRuleRepository;

    public LocalDateTime calculateExpectedResolvedAt(MaintenancePriority priority, MaintenanceCategory category) {
        Optional<SlaRule> ruleOpt = slaRuleRepository.findByPriorityAndCategory(priority, category);
        if (ruleOpt.isEmpty()) {
            ruleOpt = slaRuleRepository.findByPriorityAndCategoryIsNull(priority);
        }
        int maxHours = ruleOpt.map(SlaRule::getMaxHours).orElseGet(() -> {
            if (priority == MaintenancePriority.URGENT) return 2;
            if (priority == MaintenancePriority.HIGH) return 6;
            return 24;
        });
        return LocalDateTime.now().plusHours(maxHours);
    }

    public List<SlaRuleResponse> listAllRules() {
        return slaRuleRepository.findAll().stream()
                .map(SlaRuleResponse::from)
                .collect(Collectors.toList());
    }

    @Transactional
    public SlaRuleResponse createOrUpdateRule(CreateOrUpdateSlaRuleRequest req) {
        SlaRule rule = slaRuleRepository.findByPriorityAndCategory(req.getPriority(), req.getCategory())
                .orElse(SlaRule.builder()
                        .priority(req.getPriority())
                        .category(req.getCategory())
                        .build());
        rule.setMaxHours(req.getMaxHours());
        rule = slaRuleRepository.save(rule);
        return SlaRuleResponse.from(rule);
    }

    @Transactional
    public void deleteRule(UUID id) {
        slaRuleRepository.deleteById(id);
    }
}
