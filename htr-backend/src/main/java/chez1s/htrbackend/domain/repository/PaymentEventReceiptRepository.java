package chez1s.htrbackend.domain.repository;

import chez1s.htrbackend.domain.entity.PaymentEventReceipt;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.UUID;

public interface PaymentEventReceiptRepository extends JpaRepository<PaymentEventReceipt, UUID> {
    boolean existsByEventKey(String eventKey);
}
