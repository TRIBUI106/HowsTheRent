package chez1s.htrbackend.domain.entity;

import jakarta.persistence.*;
import lombok.*;

import java.math.BigDecimal;
import java.util.UUID;

@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
@Entity
@Table(name = "vehicle_configs")
public class VehicleConfig extends BaseEntity {
    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @OneToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "property_id", nullable = false, unique = true)
    private Property property;

    @Column(name = "motorbike_price", nullable = false, precision = 15, scale = 2)
    private BigDecimal motorbikePrice;

    @Column(name = "car_price", nullable = false, precision = 15, scale = 2)
    private BigDecimal carPrice;

    @Column(name = "bicycle_price", nullable = false, precision = 15, scale = 2)
    private BigDecimal bicyclePrice;
}
