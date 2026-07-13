package chez1s.htrbackend.service;

import chez1s.htrbackend.domain.entity.SlaRule;
import chez1s.htrbackend.domain.enums.MaintenanceCategory;
import chez1s.htrbackend.domain.enums.MaintenancePriority;
import chez1s.htrbackend.domain.repository.SlaRuleRepository;
import chez1s.htrbackend.dto.request.CreateOrUpdateSlaRuleRequest;
import chez1s.htrbackend.dto.response.SlaRuleResponse;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class SlaServiceTest {

    @Mock
    private SlaRuleRepository slaRuleRepository;

    @InjectMocks
    private SlaService slaService;

    @Test
    void calculateExpectedResolvedAt_CustomRuleExists_UsesRuleHours() {
        SlaRule rule = SlaRule.builder()
                .id(UUID.randomUUID())
                .priority(MaintenancePriority.URGENT)
                .category(MaintenanceCategory.ELECTRIC)
                .maxHours(1)
                .build();

        when(slaRuleRepository.findByPriorityAndCategory(MaintenancePriority.URGENT, MaintenanceCategory.ELECTRIC))
                .thenReturn(Optional.of(rule));

        LocalDateTime result = slaService.calculateExpectedResolvedAt(MaintenancePriority.URGENT, MaintenanceCategory.ELECTRIC);

        assertNotNull(result);
        assertTrue(result.isAfter(LocalDateTime.now().plusMinutes(50)));
    }

    @Test
    void calculateExpectedResolvedAt_NoCustomRule_UsesDefaultFallback() {
        when(slaRuleRepository.findByPriorityAndCategory(MaintenancePriority.NORMAL, MaintenanceCategory.FURNITURE))
                .thenReturn(Optional.empty());
        when(slaRuleRepository.findByPriorityAndCategoryIsNull(MaintenancePriority.NORMAL))
                .thenReturn(Optional.empty());

        LocalDateTime result = slaService.calculateExpectedResolvedAt(MaintenancePriority.NORMAL, MaintenanceCategory.FURNITURE);

        assertNotNull(result);
        assertTrue(result.isAfter(LocalDateTime.now().plusHours(23)));
    }

    @Test
    void createOrUpdateRule_NewRule_SavesAndReturns() {
        CreateOrUpdateSlaRuleRequest req = new CreateOrUpdateSlaRuleRequest(MaintenancePriority.HIGH, MaintenanceCategory.PLUMBING, 4);

        when(slaRuleRepository.findByPriorityAndCategory(MaintenancePriority.HIGH, MaintenanceCategory.PLUMBING))
                .thenReturn(Optional.empty());
        when(slaRuleRepository.save(any(SlaRule.class))).thenAnswer(i -> {
            SlaRule r = i.getArgument(0);
            r.setId(UUID.randomUUID());
            return r;
        });

        SlaRuleResponse res = slaService.createOrUpdateRule(req);

        assertNotNull(res.getId());
        assertEquals("HIGH", res.getPriority());
        assertEquals("PLUMBING", res.getCategory());
        assertEquals(4, res.getMaxHours());
    }
}
