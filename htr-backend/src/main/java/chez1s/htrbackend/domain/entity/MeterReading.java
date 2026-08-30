package chez1s.htrbackend.domain.entity;

import chez1s.htrbackend.domain.enums.MeterReadingSource;
import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.UUID;

@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
@Entity
@Table(name = "meter_readings", uniqueConstraints = @UniqueConstraint(columnNames = {"room_id", "reading_month"}))
public class MeterReading {
    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "room_id", nullable = false)
    private Room room;

    @Column(name = "reading_month", nullable = false)
    private LocalDate readingMonth;

    @Column(name = "elec_old", nullable = false)
    private Long elecOld;

    @Column(name = "elec_new", nullable = false)
    private Long elecNew;

    @Column(name = "water_old")
    private Long waterOld;

    @Column(name = "water_new")
    private Long waterNew;

    /** True when the electricity meter was physically replaced during this period. */
    @Column(name = "elec_replaced", nullable = false)
    @Builder.Default
    private boolean elecReplaced = false;

    /** Old meter's final reading right before removal, when {@link #elecReplaced}. */
    @Column(name = "elec_old_meter_final")
    private Long elecOldMeterFinal;

    /** New meter's starting reading at install, when {@link #elecReplaced}. */
    @Column(name = "elec_new_meter_start")
    private Long elecNewMeterStart;

    /** True when the water meter was physically replaced during this period. */
    @Column(name = "water_replaced", nullable = false)
    @Builder.Default
    private boolean waterReplaced = false;

    /** Old meter's final reading right before removal, when {@link #waterReplaced}. */
    @Column(name = "water_old_meter_final")
    private Long waterOldMeterFinal;

    /** New meter's starting reading at install, when {@link #waterReplaced}. */
    @Column(name = "water_new_meter_start")
    private Long waterNewMeterStart;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    @Builder.Default
    private MeterReadingSource source = MeterReadingSource.MANUAL;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "recorded_by", nullable = false)
    private User recordedBy;

    @Column(name = "recorded_at", nullable = false)
    private LocalDateTime recordedAt;

    @PrePersist
    void onCreate() {
        if (recordedAt == null) {
            recordedAt = LocalDateTime.now();
        }
    }
}
