package chez1s.htrbackend.domain.entity;

import jakarta.persistence.*;
import lombok.*;

import java.util.UUID;

@Getter @Setter @Builder @NoArgsConstructor @AllArgsConstructor
@Entity
@Table(name = "upload_batches", uniqueConstraints = @UniqueConstraint(columnNames = "idempotency_key"))
public class UploadBatch extends BaseEntity {
    @Id @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;
    @Column(name = "idempotency_key", nullable = false, unique = true)
    private String idempotencyKey;
    @Column(nullable = false, length = 30)
    private String status;
    @Column(name = "domain_type", nullable = false, length = 40)
    private String domainType;
    @Column(name = "domain_id")
    private UUID domainId;
    @Column(name = "cleanup_required", nullable = false)
    private boolean cleanupRequired;
}
