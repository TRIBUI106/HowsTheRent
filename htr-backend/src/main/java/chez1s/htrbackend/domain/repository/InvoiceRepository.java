package chez1s.htrbackend.domain.repository;

import chez1s.htrbackend.domain.entity.Invoice;
import chez1s.htrbackend.domain.enums.InvoiceStatus;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface InvoiceRepository extends JpaRepository<Invoice, UUID> {
    boolean existsByRoomIdAndInvoiceMonth(UUID roomId, LocalDate invoiceMonth);

    @EntityGraph(attributePaths = {"room", "room.property", "contract", "contract.tenant"})
    List<Invoice> findByRoomIdOrderByInvoiceMonthDesc(UUID roomId);

    @EntityGraph(attributePaths = {"room", "room.property", "contract", "contract.tenant"})
    Page<Invoice> findByContractTenantId(UUID tenantId, Pageable pageable);

    @EntityGraph(attributePaths = {"room", "room.property", "contract", "contract.tenant"})
    List<Invoice> findByContractTenantIdOrderByInvoiceMonthDesc(UUID tenantId);

    @EntityGraph(attributePaths = {"room", "room.property", "contract", "contract.tenant"})
    List<Invoice> findByRoomPropertyOwnerIdOrderByInvoiceMonthDesc(UUID ownerId);

    @EntityGraph(attributePaths = {"room", "room.property", "contract", "contract.tenant"})
    Page<Invoice> findByRoomPropertyOwnerId(UUID ownerId, Pageable pageable);

    @EntityGraph(attributePaths = {"room", "room.property", "contract", "contract.tenant"})
    Page<Invoice> findByRoomPropertyOwnerIdAndStatus(UUID ownerId, InvoiceStatus status, Pageable pageable);

    @EntityGraph(attributePaths = {"room", "room.property", "contract", "contract.tenant"})
    Page<Invoice> findByStatus(InvoiceStatus status, Pageable pageable);

    List<Invoice> findByStatusAndDueDateBefore(InvoiceStatus status, LocalDate date);

    @EntityGraph(attributePaths = {"room", "room.property", "contract", "contract.tenant"})
    Optional<Invoice> findByPaymentLinkId(String paymentLinkId);

    @Override
    @EntityGraph(attributePaths = {"room", "room.property", "contract", "contract.tenant"})
    Optional<Invoice> findById(UUID id);

    @Override
    @EntityGraph(attributePaths = {"room", "room.property", "contract", "contract.tenant"})
    Page<Invoice> findAll(Pageable pageable);

    @Query("SELECT COALESCE(SUM(i.totalAmount), 0) FROM Invoice i WHERE i.status = 'PAID' AND i.invoiceMonth = :month")
    BigDecimal sumPaidAmountByMonth(LocalDate month);

    @Query("SELECT COALESCE(SUM(i.totalAmount), 0) FROM Invoice i JOIN i.contract c JOIN c.room r WHERE i.status = 'PAID' AND i.invoiceMonth = :month AND r.property.id IN :propertyIds")
    BigDecimal sumPaidAmountByMonthAndPropertyIds(LocalDate month, List<UUID> propertyIds);

    long countByStatus(InvoiceStatus status);
    long countByRoomPropertyOwnerIdAndStatus(UUID ownerId, InvoiceStatus status);
    long countByRoomId(UUID roomId);
}
