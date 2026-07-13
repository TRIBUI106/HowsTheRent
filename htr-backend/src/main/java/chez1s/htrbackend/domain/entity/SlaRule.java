package chez1s.htrbackend.domain.entity;

import chez1s.htrbackend.domain.enums.MaintenanceCategory;
import chez1s.htrbackend.domain.enums.MaintenancePriority;
import jakarta.persistence.*;
import lombok.*;

import java.util.UUID;

@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
@Entity
@Table(name = "sla_rules")
public class SlaRule extends BaseEntity {
    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 30)
    private MaintenancePriority priority;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 30)
    private MaintenanceCategory category;

    @Column(name = "max_hours", nullable = false)
    private int maxHours;
}
