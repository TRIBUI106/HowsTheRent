package chez1s.htrbackend.domain.entity;

import chez1s.htrbackend.domain.enums.MaintenanceCategory;
import chez1s.htrbackend.domain.enums.MaintenancePriority;
import chez1s.htrbackend.domain.enums.MaintenanceStatus;
import jakarta.persistence.*;
import lombok.*;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
@Entity
@Table(name = "maintenance_requests")
public class MaintenanceRequest extends BaseEntity {
    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "room_id", nullable = false)
    private Room room;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "tenant_id", nullable = false)
    private User tenant;

    @Column(nullable = false, length = 200)
    private String title;

    @Column(columnDefinition = "TEXT")
    private String description;

    @ElementCollection
    @CollectionTable(name = "maintenance_images", joinColumns = @JoinColumn(name = "request_id"))
    @Column(name = "image_url")
    @Builder.Default
    private List<String> images = new ArrayList<>();

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    @Builder.Default
    private MaintenanceStatus status = MaintenanceStatus.OPEN;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    @Builder.Default
    private MaintenancePriority priority = MaintenancePriority.NORMAL;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 30)
    @Builder.Default
    private MaintenanceCategory category = MaintenanceCategory.OTHER;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "assigned_to")
    private User assignedTo;

    @Column(name = "resolved_at")
    private LocalDateTime resolvedAt;

    @Column(name = "expected_resolved_at")
    private LocalDateTime expectedResolvedAt;

    @Column(name = "ticket_code", length = 30)
    private String ticketCode;

    @ElementCollection
    @CollectionTable(name = "maintenance_preferred_slots", joinColumns = @JoinColumn(name = "request_id"))
    @Column(name = "time_slot")
    @Builder.Default
    private List<String> preferredTimeSlots = new ArrayList<>();

    @Column(name = "confirmed_time_slot", length = 100)
    private String confirmedTimeSlot;

    @Column(name = "confirm_slot_by_tenant")
    @Builder.Default
    private Boolean confirmSlotByTenant = false;

    @ElementCollection
    @CollectionTable(name = "maintenance_completion_images", joinColumns = @JoinColumn(name = "request_id"))
    @Column(name = "image_url")
    @Builder.Default
    private List<String> completionImages = new ArrayList<>();

    @Column(name = "attachment_video")
    private String attachmentVideo;

    @Column(name = "started_at")
    private LocalDateTime startedAt;

    @Column(name = "is_overdue_sla")
    @Builder.Default
    private Boolean isOverdueSla = false;

    @Column(name = "is_complained")
    @Builder.Default
    private Boolean isComplained = false;

    @Column(name = "complain_reason", columnDefinition = "TEXT")
    private String complainReason;

    @Column(name = "cancel_reason", columnDefinition = "TEXT")
    private String cancelReason;

    @Column(name = "material_cost", precision = 15, scale = 2)
    @Builder.Default
    private BigDecimal materialCost = BigDecimal.ZERO;
}
