package chez1s.htrbackend.domain.entity;

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
