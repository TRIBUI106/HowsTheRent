package chez1s.htrbackend.domain.repository;

import chez1s.htrbackend.domain.entity.SlaRule;
import chez1s.htrbackend.domain.enums.MaintenanceCategory;
import chez1s.htrbackend.domain.enums.MaintenancePriority;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;
import java.util.UUID;

@Repository
public interface SlaRuleRepository extends JpaRepository<SlaRule, UUID> {
    Optional<SlaRule> findByPriorityAndCategory(MaintenancePriority priority, MaintenanceCategory category);
    Optional<SlaRule> findByPriorityAndCategoryIsNull(MaintenancePriority priority);
}
