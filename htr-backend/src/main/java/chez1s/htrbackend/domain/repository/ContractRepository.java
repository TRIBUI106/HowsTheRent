package chez1s.htrbackend.domain.repository;

import chez1s.htrbackend.domain.entity.Contract;
import chez1s.htrbackend.domain.enums.ContractStatus;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface ContractRepository extends JpaRepository<Contract, UUID> {
    List<Contract> findByRoomId(UUID roomId);
    List<Contract> findByTenantId(UUID tenantId);
    List<Contract> findByStatus(ContractStatus status);
    boolean existsByRoomIdAndStatus(UUID roomId, ContractStatus status);
    boolean existsByTenantIdAndRoomIdAndStatus(UUID tenantId, UUID roomId, ContractStatus status);
    Optional<Contract> findFirstByTenantIdAndStatusOrderByCreatedAtDesc(UUID tenantId, ContractStatus status);
}
