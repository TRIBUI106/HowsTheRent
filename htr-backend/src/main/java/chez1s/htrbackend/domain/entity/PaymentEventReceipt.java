package chez1s.htrbackend.domain.entity;

import jakarta.persistence.*;
import lombok.*;

import java.util.UUID;

@Getter @Setter @Builder @NoArgsConstructor @AllArgsConstructor
@Entity
@Table(name = "payment_event_receipts", uniqueConstraints = @UniqueConstraint(columnNames = "event_key"))
public class PaymentEventReceipt extends BaseEntity {
    @Id @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;
    @Column(name = "event_key", nullable = false, unique = true)
    private String eventKey;
    @Column(name = "order_code", nullable = false)
    private String orderCode;
    @Column(name = "transaction_id")
    private String transactionId;
    @Column(nullable = false)
    private boolean applied;
}
