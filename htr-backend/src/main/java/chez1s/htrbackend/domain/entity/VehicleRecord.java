package chez1s.htrbackend.domain.entity;

import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDate;
import java.util.UUID;

@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
@Entity
@Table(name = "vehicle_records", uniqueConstraints = @UniqueConstraint(columnNames = {"room_id", "record_month"}))
public class VehicleRecord extends BaseEntity {
    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "room_id", nullable = false)
    private Room room;

    @Column(name = "record_month", nullable = false)
    private LocalDate recordMonth;

    @Column(name = "motorbike_count", nullable = false)
    private int motorbikeCount;

    @Column(name = "car_count", nullable = false)
    private int carCount;

    @Column(name = "bicycle_count", nullable = false)
    private int bicycleCount;
}
