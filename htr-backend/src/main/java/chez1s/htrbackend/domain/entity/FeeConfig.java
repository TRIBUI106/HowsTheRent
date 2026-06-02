package chez1s.htrbackend.domain.entity;

import chez1s.htrbackend.domain.enums.WaterMode;
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
@Table(name = "fee_configs")
public class FeeConfig extends BaseEntity {
    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @OneToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "property_id", nullable = false, unique = true)
    private Property property;

    @Column(name = "rent_default", nullable = false, precision = 15, scale = 2)
    private BigDecimal rentDefault;

    @Column(name = "elec_price", nullable = false, precision = 15, scale = 2)
    private BigDecimal elecPrice;

    @Enumerated(EnumType.STRING)
    @Column(name = "water_mode", nullable = false, length = 20)
    private WaterMode waterMode;

    @Column(name = "water_price", nullable = false, precision = 15, scale = 2)
    private BigDecimal waterPrice;

    @Column(name = "service_fee", nullable = false, precision = 15, scale = 2)
    private BigDecimal serviceFee;

    @Column(name = "vehicle_pro_rata", nullable = false)
    private boolean vehicleProRata;

    @Column(name = "service_pro_rata", nullable = false)
    private boolean serviceProRata;

    @Column(name = "motorbike_price", nullable = false, precision = 15, scale = 2)
    private BigDecimal motorbikePrice;

    @Column(name = "car_price", nullable = false, precision = 15, scale = 2)
    private BigDecimal carPrice;

    @Column(name = "bicycle_price", nullable = false, precision = 15, scale = 2)
    private BigDecimal bicyclePrice;
}
