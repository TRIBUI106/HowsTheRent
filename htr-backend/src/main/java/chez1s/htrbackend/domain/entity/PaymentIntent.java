package chez1s.htrbackend.domain.entity;

import jakarta.persistence.*;
import lombok.*;

import java.util.UUID;

@Getter @Setter @Builder @NoArgsConstructor @AllArgsConstructor
@Entity
@Table(name = "payment_intents", uniqueConstraints = @UniqueConstraint(columnNames = "order_code"))
public class PaymentIntent extends BaseEntity {
    @Id @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;
    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "invoice_id", nullable = false)
    private Invoice invoice;
    @Column(name = "order_code", nullable = false, unique = true)
    private String orderCode;
    @Column(nullable = false, length = 30)
    private String status;
    @Column(name = "checkout_url")
    private String checkoutUrl;
}
